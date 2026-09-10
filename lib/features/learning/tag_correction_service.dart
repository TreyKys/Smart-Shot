import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/diagnostics/diagnostic_log.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/ingestion/services/tag_engine.dart';

/// A single recorded tag correction — a user editing away from the tags the
/// AI (or a previous edit) assigned.
///
/// Deliberately carries no raw screenshot text, OCR content, topic, or any
/// extracted URL/email/phone/crypto data. [keywords] is limited to whatever
/// subset of [TagEngine.categoryKeywords] — a fixed, generic vocabulary
/// already shipped in the app ("invoice", "netflix", "boarding pass") —
/// happened to appear in the screenshot's text. That vocabulary can never
/// contain a real email address, balance, or name, which is what makes this
/// safe to mirror to the shared Firestore database in
/// [TagCorrectionService._pushToFirestore] without leaking anything personal.
@immutable
class TagCorrection {
  final List<String> keywords;
  final List<String> fromTags;
  final List<String> toTags;
  final DateTime timestamp;

  const TagCorrection({
    required this.keywords,
    required this.fromTags,
    required this.toTags,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'keywords': keywords,
        'fromTags': fromTags,
        'toTags': toTags,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TagCorrection.fromJson(Map<String, dynamic> json) => TagCorrection(
        keywords: List<String>.from(json['keywords'] as List? ?? const []),
        fromTags: List<String>.from(json['fromTags'] as List? ?? const []),
        toTags: List<String>.from(json['toTags'] as List? ?? const []),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

final tagCorrectionServiceProvider = Provider<TagCorrectionService>((ref) {
  return TagCorrectionService(ref);
});

/// Real count of corrections this device has recorded in the last 7 days —
/// Discover's "Sift is learning" card reads this. Not a running total or a
/// fabricated streak: exactly what [TagCorrectionService.recentCorrectionCount]
/// finds in the same local log [TagCorrectionService.recordCorrection]
/// appends to. autoDispose since it's a point-in-time read, not something
/// worth keeping warm between visits to Discover.
final recentCorrectionCountProvider = FutureProvider.autoDispose<int>((ref) {
  return ref.watch(tagCorrectionServiceProvider).recentCorrectionCount();
});

/// Records what users correct the AI's tagging to, rewards them for it, and
/// feeds those corrections back into future tagging as a prompt hint.
///
/// Two tiers, deliberately gated one behind the other:
///
/// - **Local log** (this device, SharedPreferences): every correction is
///   recorded here regardless of anything else. Always available, free,
///   works offline.
/// - **Shared Firestore database** (all users): a redacted mirror of the
///   same correction — keywords + from/to tags only, see [TagCorrection]'s
///   doc — is pushed best-effort. When tagging a *new* screenshot, this
///   service only ever queries Firestore if the local log already found a
///   relevant match for that screenshot's text — see [buildLearningHint].
///   That gate is what keeps a device with no correction history from
///   burning a Firestore read on every single screenshot it processes.
class TagCorrectionService {
  TagCorrectionService(this._ref);
  final Ref _ref;

  static const String _kLocalKey = 'tag_corrections_v1';
  static const int _kMaxLocal = 300;
  static const String _kFirestoreCollection = 'tag_corrections';

  List<TagCorrection>? _localCache;
  final Map<String, List<TagCorrection>> _communityCache = {};

  /// Matches [text] against [TagEngine.categoryKeywords] only — never
  /// returns anything that wasn't already one of those fixed, built-in
  /// words. Capped so a very long OCR text can't produce an unbounded list.
  static List<String> _matchKeywords(String text) {
    if (text.trim().isEmpty) return const [];
    final lower = text.toLowerCase();
    final matched = <String>{};
    for (final keywords in TagEngine.categoryKeywords.values) {
      for (final kw in keywords) {
        if (lower.contains(kw)) matched.add(kw);
      }
    }
    return matched.take(12).toList();
  }

  /// Records a correction and rewards the user for it.
  ///
  /// A no-op (returns false, records nothing) when [fromTags] and [toTags]
  /// are the same set — saving a tag sheet without actually changing
  /// anything shouldn't count as a correction or earn a reward.
  ///
  /// Returns whether the correction reward was actually granted (subject to
  /// [EconomyService.rewardTagCorrection]'s daily cap), so the caller can
  /// show a "+2 energy" confirmation only when something was really granted.
  Future<bool> recordCorrection({
    required String textForKeywords,
    required List<String> fromTags,
    required List<String> toTags,
  }) async {
    final fromSet = fromTags.toSet();
    final toSet = toTags.toSet();
    if (fromSet.length == toSet.length && fromSet.containsAll(toSet)) {
      return false;
    }

    final correction = TagCorrection(
      keywords: _matchKeywords(textForKeywords),
      fromTags: fromTags,
      toTags: toTags,
      timestamp: DateTime.now(),
    );

    await _appendLocal(correction);
    _pushToFirestore(correction);

    return _ref.read(economyServiceProvider.notifier).rewardTagCorrection();
  }

  Future<void> _appendLocal(TagCorrection correction) async {
    final current = await _loadLocal();
    final updated = [...current, correction];
    final trimmed = updated.length > _kMaxLocal
        ? updated.sublist(updated.length - _kMaxLocal)
        : updated;
    _localCache = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kLocalKey,
      trimmed.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  /// Cached after the first read for this service instance's lifetime — a
  /// full library sync calls [buildLearningHint] once per screenshot, and
  /// re-reading + re-decoding up to [_kMaxLocal] JSON strings from
  /// SharedPreferences that many times would add real latency for no
  /// benefit, since the log only changes when [_appendLocal] runs (which
  /// updates this same cache directly).
  Future<List<TagCorrection>> _loadLocal() async {
    final cached = _localCache;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kLocalKey) ?? const [];
    final list = raw
        .map((s) {
          try {
            return TagCorrection.fromJson(
                Map<String, dynamic>.from(jsonDecode(s) as Map));
          } catch (_) {
            return null;
          }
        })
        .whereType<TagCorrection>()
        .toList();
    _localCache = list;
    return list;
  }

  /// Fire-and-forget mirror to the shared database. Never throws into the
  /// caller and never blocks the UI — Firestore write failures (offline, the
  /// collection not yet enabled in the Firebase Console, a rules rejection)
  /// degrade to a diagnostics-log line, not a user-visible error, since the
  /// local record (already saved by the time this runs) is the one thing
  /// that actually has to succeed.
  void _pushToFirestore(TagCorrection correction) {
    if (correction.keywords.isEmpty) return; // nothing worth sharing
    // Deliberately not awaited by the caller — this is best-effort and must
    // never make a tag edit feel slow or fail because of a network blip.
    unawaited(() async {
      try {
        await FirebaseFirestore.instance
            .collection(_kFirestoreCollection)
            .add({
          'keywords': correction.keywords,
          'fromTags': correction.fromTags,
          'toTags': correction.toTags,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        DiagnosticLog.warn(
            'TagCorrectionService: Firestore write failed: $e');
      }
    }());
  }

  /// Real count of corrections recorded to the local log in the last [days]
  /// days — used by Discover's "Sift is learning" card. Doesn't distinguish
  /// ones that also reached Firestore from ones that didn't; either way the
  /// user actually made the edit, which is the thing being surfaced here.
  Future<int> recentCorrectionCount({int days = 7}) async {
    final all = await _loadLocal();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return all.where((c) => c.timestamp.isAfter(cutoff)).length;
  }

  /// The local-log gate described in this class's doc comment — only a hit
  /// here unlocks a Firestore query in [buildLearningHint].
  Future<List<TagCorrection>> _localMatches(List<String> keywords) async {
    if (keywords.isEmpty) return const [];
    final local = await _loadLocal();
    return local.where((c) => c.keywords.any(keywords.contains)).toList();
  }

  /// Best-effort community query, gated by [_localMatches] finding something
  /// first. Cached per keyword set for this service instance's lifetime so a
  /// batch of similar screenshots (a folder of receipts, say) doesn't repeat
  /// the same Firestore read for each one.
  Future<List<TagCorrection>> _communityMatches(List<String> keywords) async {
    if (keywords.isEmpty) return const [];
    final cacheKey = (List<String>.from(keywords)..sort()).join(',');
    final cached = _communityCache[cacheKey];
    if (cached != null) return cached;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(_kFirestoreCollection)
          .where('keywords', arrayContainsAny: keywords.take(10).toList())
          .limit(8)
          .get()
          .timeout(const Duration(seconds: 4));
      final result =
          snap.docs.map((d) => TagCorrection.fromJson(d.data())).toList();
      _communityCache[cacheKey] = result;
      return result;
    } catch (e) {
      DiagnosticLog.warn('TagCorrectionService: Firestore read failed: $e');
      return const [];
    }
  }

  /// Builds a short note to append to the AI tagging prompt for a screenshot
  /// whose text is [text], summarizing how similar screenshots were
  /// corrected before — first by this user, then (only if that local check
  /// found something) by the wider community via Firestore. Returns null
  /// when there's nothing relevant to say, which is the common case for a
  /// device with little or no correction history yet.
  Future<String?> buildLearningHint(String text) async {
    final keywords = _matchKeywords(text);
    final local = await _localMatches(keywords);
    if (local.isEmpty) return null;

    final community = await _communityMatches(keywords);
    final all = [...local, ...community];

    // Tally which (fromTags -> toTags) correction pattern recurs most, so a
    // single stray edit doesn't outweigh a pattern several corrections agree
    // on.
    final counts = <String, int>{};
    final labels = <String, String>{};
    for (final c in all) {
      if (c.toTags.isEmpty) continue;
      final key = '${c.fromTags.join(",")}=>${c.toTags.join(",")}';
      counts[key] = (counts[key] ?? 0) + 1;
      final fromLabel = c.fromTags.isEmpty ? 'no tags' : c.fromTags.join(', ');
      labels[key] = '$fromLabel → ${c.toTags.join(", ")}';
    }
    if (counts.isEmpty) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(2).map((e) => labels[e.key]).join('; ');

    return 'Note: for screenshots with similar content, users have '
        'previously corrected the tags as follows: $top. Weigh this pattern '
        'if it fits, but do not force it onto content that clearly differs.';
  }
}
