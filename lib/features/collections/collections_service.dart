import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/features/collections/domain/gallery_collection.dart';

/// Manual curation layer, stored in SharedPreferences rather than Isar.
///
/// Deliberately not modeled as an Isar `@collection` with `IsarLinks` —
/// adding a new Isar collection, or a new field to the existing `Screenshot`
/// collection, requires regenerating its `.g.dart` via `dart run
/// build_runner build`, which isn't guaranteed to be available in every
/// environment this app gets built from. SharedPreferences already holds two
/// other pieces of exactly this shape of state for the same reason — pinned
/// screenshot ids (gallery_screen.dart) and the perceptual-dedup index
/// (gallery_repository.dart's `_DedupIndex`) — so this follows an established
/// pattern rather than inventing a new one. At Sift's realistic library sizes
/// (hundreds to low thousands of screenshots) a JSON blob per collection is
/// plenty fast; `_DedupIndex`'s own doc comment makes the same argument.
class CollectionsService
    extends StateNotifier<AsyncValue<List<GalleryCollection>>> {
  CollectionsService() : super(const AsyncValue.loading()) {
    _load();
  }

  static const _kCollectionsKey = 'collections_v1';
  static const _kMembershipPrefix = 'collection_members_v1_';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCollectionsKey);
      if (raw == null || raw.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }
      final decoded = jsonDecode(raw);
      final collections = (decoded is List ? decoded : const [])
          .whereType<Map>()
          .map((m) => GalleryCollection.fromJson(Map<String, dynamic>.from(m)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(collections);
    } catch (e, st) {
      debugPrint('CollectionsService: load failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Re-reads from SharedPreferences — used after another isolate/screen may
  /// have changed things, mirroring how DiagnosticLog.load() re-syncs rather
  /// than trusting an in-memory snapshot.
  Future<void> refresh() => _load();

  Future<void> _persist(List<GalleryCollection> collections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCollectionsKey,
      jsonEncode(collections.map((c) => c.toJson()).toList()),
    );
  }

  Future<GalleryCollection> create(String name,
      {int colorValue = 0xFF2F6FED}) async {
    final trimmed = name.trim();
    final collection = GalleryCollection(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed.isEmpty ? 'Untitled' : trimmed,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    final current = state.value ?? const <GalleryCollection>[];
    final updated = [collection, ...current];
    state = AsyncValue.data(updated);
    await _persist(updated);
    return collection;
  }

  /// Finds an existing collection by name (case-insensitive), or null.
  GalleryCollection? findByName(String name) {
    final target = name.trim().toLowerCase();
    for (final c in state.value ?? const <GalleryCollection>[]) {
      if (c.name.toLowerCase() == target) return c;
    }
    return null;
  }

  Future<void> rename(String id, String newName) async {
    final current = state.value ?? const <GalleryCollection>[];
    final updated = [
      for (final c in current)
        if (c.id == id) c.copyWith(name: newName) else c,
    ];
    state = AsyncValue.data(updated);
    await _persist(updated);
  }

  Future<void> delete(String id) async {
    final current = state.value ?? const <GalleryCollection>[];
    final updated = current.where((c) => c.id != id).toList();
    state = AsyncValue.data(updated);
    await _persist(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kMembershipPrefix$id');
  }

  // ── Membership ──────────────────────────────────────────────────────────

  Future<Set<int>> membersOf(String collectionId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_kMembershipPrefix$collectionId') ?? [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> addScreenshots(
      String collectionId, Iterable<int> screenshotIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kMembershipPrefix$collectionId';
    final current =
        (prefs.getStringList(key) ?? []).map(int.tryParse).whereType<int>().toSet();
    current.addAll(screenshotIds);
    await prefs.setStringList(key, current.map((e) => e.toString()).toList());
  }

  Future<void> removeScreenshots(
      String collectionId, Iterable<int> screenshotIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_kMembershipPrefix$collectionId';
    final current =
        (prefs.getStringList(key) ?? []).map(int.tryParse).whereType<int>().toSet();
    current.removeAll(screenshotIds);
    await prefs.setStringList(key, current.map((e) => e.toString()).toList());
  }

  /// Drops a deleted screenshot's id from every collection's membership.
  ///
  /// Without this, a purged screenshot's id lingers in whatever collections
  /// it was filed into forever — the same class of bug `forgetDedupHash()`
  /// exists to prevent for the perceptual-hash index (gallery_repository.dart).
  Future<void> forgetScreenshot(int screenshotId) async {
    final collections = state.value ?? const <GalleryCollection>[];
    final prefs = await SharedPreferences.getInstance();
    for (final c in collections) {
      final key = '$_kMembershipPrefix${c.id}';
      final current = (prefs.getStringList(key) ?? [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
      if (current.remove(screenshotId)) {
        await prefs.setStringList(
            key, current.map((e) => e.toString()).toList());
      }
    }
  }
}

final collectionsServiceProvider = StateNotifierProvider<CollectionsService,
    AsyncValue<List<GalleryCollection>>>(
  (ref) => CollectionsService(),
);
