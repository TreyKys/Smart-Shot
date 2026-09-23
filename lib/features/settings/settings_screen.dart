import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/core/theme/theme_provider.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/services/sync_status.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:sift/features/pro/presentation/paywall_sheet.dart';

// Mirrors legal/privacy-policy.html and legal/terms.html in this repo — kept
// in sync manually, since neurodevlabs.cloud is built from a separate repo.
const String kPrivacyPolicyUrl =
    'https://neurodevlabs.cloud/sift/privacy-policy.html';
const String kTermsOfServiceUrl = 'https://neurodevlabs.cloud/sift/terms.html';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _byokController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _byokController.text =
        ref.read(economyServiceProvider.notifier).getByokKey() ?? '';
  }

  @override
  void dispose() {
    _byokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proServiceProvider);
    final energyState = ref.watch(economyServiceProvider);
    // BYOK bypasses the energy system entirely (see
    // EconomyService._isUnlimited) — showing "Remaining: N" and a "Refill"
    // button off the stale `ai_energy` pref would misrepresent a BYOK user's
    // actual (unlimited) quota. Reads the persisted key, not the draft text
    // field, so this only flips once Save has actually taken effect.
    final savedByokKey = ref
        .watch(economyServiceProvider.notifier)
        .getByokKey();
    final hasByok = (savedByokKey ?? '').isNotEmpty;

    return Scaffold(
      backgroundColor: SiftColors.background,
      appBar: AppBar(
        backgroundColor: SiftColors.background,
        title: const Text('Settings & Pro'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PRO STATUS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isPro
                  ? SiftColors.proGold.withValues(alpha: 0.12)
                  : SiftColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPro
                    ? SiftColors.proGold.withValues(alpha: 0.4)
                    : SiftColors.border,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPro ? 'Sift Pro Active' : 'Sift Free',
                  style: TextStyle(
                    color: isPro ? SiftColors.proGold : SiftColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isPro) ...[
                  Text(
                    'Unlock infinite AI fuel, deep backlog sweeping, custom vaults, and advanced exports.',
                    style: TextStyle(
                      color: SiftColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        showPaywallSheet(context, triggerFeature: 'Settings'),
                    child: const Text('Upgrade to Pro'),
                  ),
                ] else ...[
                  Text(
                    'Thank you for supporting Sift! You have unlimited access to all features.',
                    style: TextStyle(
                      color: SiftColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // APPEARANCE
          _SettingsTile(
            leading: Icon(
              Icons.palette_outlined,
              color: SiftColors.textSecondary,
            ),
            title: 'Appearance',
            subtitle: 'Dark, light, or match your device.',
          ),
          const SizedBox(height: 8),
          const _ThemeModeSelector(),
          const SizedBox(height: 16),
          Divider(color: SiftColors.border, height: 1),
          const SizedBox(height: 8),

          // BACKGROUND SYNC — what Sift last found and a manual re-scan
          // trigger. Without this, "did the background scan actually
          // run today?" was an entirely opaque question, and a permission
          // regression (say, the user revoked photo access from Android
          // Settings months after granting it) surfaced as "Sift stopped
          // finding my new screenshots" with no diagnostic path forward.
          const _SyncStatusTile(),
          const SizedBox(height: 16),
          Divider(color: SiftColors.border, height: 1),
          const SizedBox(height: 8),

          // ENERGY STATE — same watch-ads-for-energy pattern QuotaBar
          // already uses elsewhere in the app (live "N/2 watched" progress,
          // not a static button label), so this doesn't feel like a
          // different feature just because it's reached from Settings.
          if (!isPro && !hasByok) ...[
            energyState.when(
              data: (energy) => _EnergyTile(energy: energy),
              loading: () => const _SettingsTile(
                leading: Icon(Icons.bolt, color: SiftColors.accent),
                title: 'AI Energy',
                subtitle: 'Loading...',
              ),
              error: (e, s) => const _SettingsTile(
                leading: Icon(Icons.bolt, color: SiftColors.accent),
                title: 'AI Energy',
                subtitle: 'Error loading energy',
              ),
            ),
            Divider(color: SiftColors.border, height: 24),
          ],

          // BYOK
          _SettingsTile(
            leading: Icon(Icons.vpn_key, color: SiftColors.textSecondary),
            title: 'Bring Your Own Key (Mistral)',
            subtitle:
                'Power users: Bypass the energy and ad systems entirely by using your own Mistral AI API key.',
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _byokController,
                    style: TextStyle(color: SiftColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter Mistral API Key',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(economyServiceProvider.notifier)
                        .setByokKey(_byokController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Key saved!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: SiftColors.border, height: 1),
          const SizedBox(height: 8),

          // LEGAL
          _SettingsTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: SiftColors.textSecondary,
            ),
            title: 'Privacy Policy',
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: SiftColors.textTertiary,
            ),
            onTap: () => _openUrl(context, kPrivacyPolicyUrl),
          ),
          _SettingsTile(
            leading: Icon(
              Icons.description_outlined,
              color: SiftColors.textSecondary,
            ),
            title: 'Terms of Service',
            trailing: Icon(
              Icons.open_in_new,
              size: 18,
              color: SiftColors.textTertiary,
            ),
            onTap: () => _openUrl(context, kTermsOfServiceUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }
}

/// A single settings row — title, optional subtitle/leading icon/trailing
/// widget, tappable if [onTap] is given. Matches the plain-row pattern the
/// rest of the app uses instead of Material's default ListTile styling,
/// which (unthemed) would render with the ambient light Material theme
/// rather than this screen's dark palette.
class _SettingsTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 16)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: SiftColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: SiftColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Sync-status row: when Sift last checked the photo library, what it
/// found, and a "Scan now" button. The tile self-refreshes once a minute
/// so "N min ago" stays truthful while the user is looking at the screen.
class _SyncStatusTile extends ConsumerStatefulWidget {
  const _SyncStatusTile();

  @override
  ConsumerState<_SyncStatusTile> createState() => _SyncStatusTileState();
}

class _SyncStatusTileState extends ConsumerState<_SyncStatusTile> {
  SyncStatus? _status;
  bool _loaded = false;
  bool _scanning = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _reload();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _reload());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final s = await SyncStatus.load();
    if (!mounted) return;
    setState(() {
      _status = s;
      _loaded = true;
    });
  }

  Future<void> _scanNow() async {
    setState(() => _scanning = true);
    // Fire-and-forget: syncGallery kicks off a Future.microtask internally
    // for the "rest of the batch" ingest, so awaiting it here would only
    // block on the fast first-10 pass anyway. The refresh below covers
    // both by polling until the timestamp advances.
    unawaited(ref.read(galleryRepositoryProvider).syncGallery());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanning your library…')),
      );
    }
    final before = _status?.at;
    // Poll up to 30s waiting for a new SyncStatus write — that's the
    // point the tile can honestly say the scan finished. Times out
    // silently so a scan that runs longer than 30s (a huge library on a
    // slow device) still leaves the button re-enabled and the tile will
    // eventually refresh on the minute-timer.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      final latest = await SyncStatus.load();
      if (latest != null && latest.at != before) {
        setState(() {
          _status = latest;
          _scanning = false;
        });
        return;
      }
    }
    if (mounted) setState(() => _scanning = false);
  }

  String _timeAgo(DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inSeconds < 60) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  String _subtitle() {
    final s = _status;
    if (!_loaded) return 'Loading…';
    if (s == null) return 'Not yet checked.';
    if (s.failed) return 'Last check ${_timeAgo(s.at)} — ${s.error}';
    final via = s.source == SyncSource.background ? 'in background' : 'on open';
    final added = s.added == 0
        ? 'no new screenshots'
        : '${s.added} new screenshot${s.added == 1 ? '' : 's'}';
    final deferred = s.deferred > 0 ? ' (+${s.deferred} deferred)' : '';
    return 'Last check ${_timeAgo(s.at)} $via — $added$deferred.';
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    final failed = s?.failed ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              failed ? Icons.warning_amber_rounded : Icons.sync,
              color:
                  failed ? SiftColors.proGold : SiftColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Background Sync',
                    style: TextStyle(
                      color: SiftColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _subtitle(),
                    style: TextStyle(
                      color: failed
                          ? SiftColors.proGold
                          : SiftColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _scanning ? null : _scanNow,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: SiftColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: SiftColors.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _scanning ? 'Scanning…' : 'Scan now',
                      style: const TextStyle(
                        color: SiftColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // When the last scan failed because photos aren't granted, the
            // "Scan now" button alone can't fix that — the fix lives in the
            // OS Settings app. openAppSettings() takes the user there
            // directly instead of leaving them hunting through Android's
            // Settings maze.
            if (failed) ...[
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    await openAppSettings();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: SiftColors.proGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: SiftColors.proGold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Open Settings',
                        style: TextStyle(
                          color: SiftColors.proGold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// AI Energy row with a live progress bar and watch-ads button — the same
/// pattern QuotaBar shows on the gallery grid, adapted for a settings row
/// instead of a banner. Reusing the exact same "N/2 watched" live count
/// (adsWatchedInBlockProvider) means watching an ad from here or from the
/// grid feels like the same feature, not two different ones that happen to
/// do the same thing.
class _EnergyTile extends ConsumerWidget {
  final int energy;
  const _EnergyTile({required this.energy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fraction = (energy / kDailyFreeExtractions).clamp(0.0, 1.0);
    final isDepleted = energy <= 0;
    final adsWatched = ref.watch(adsWatchedInBlockProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDepleted ? Icons.bolt_outlined : Icons.bolt,
              color: isDepleted ? SiftColors.textTertiary : SiftColors.accent,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Energy',
                    style: TextStyle(
                      color: SiftColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isDepleted
                        ? 'Depleted for today'
                        : '$energy / $kDailyFreeExtractions remaining today',
                    style: TextStyle(
                      color: SiftColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: SiftColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDepleted ? SiftColors.textTertiary : SiftColors.accent,
            ),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => _watchAd(context, ref),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: SiftColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SiftColors.accent.withValues(alpha: 0.4)),
            ),
            child: Center(
              child: Text(
                adsWatched > 0
                    ? '$adsWatched/$kAdsRequiredForReward watched — 1 more'
                    : 'Watch $kAdsRequiredForReward ads for +$kAdRewardExtractions',
                style: const TextStyle(
                  color: SiftColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _watchAd(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Loading ad... watch $kAdsRequiredForReward to earn '
          '+$kAdRewardExtractions scans.',
        ),
      ),
    );
    ref
        .read(economyServiceProvider.notifier)
        .showRewardedAd(
          onBlockCompleted: () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('+$kAdRewardExtractions AI scans unlocked!'),
                ),
              );
            }
          },
        );
  }
}

/// Three-way Dark / Light / System picker for [themeModeProvider] — a
/// segmented row rather than a dropdown, so all three options (and which
/// one is active) are visible at a glance without an extra tap to open
/// anything.
class _ThemeModeSelector extends ConsumerWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);

    Widget segment(SiftThemeMode mode, IconData icon, String label) {
      final selected = current == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => ref.read(themeModeProvider.notifier).setMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? SiftColors.accent.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? SiftColors.accent : SiftColors.border,
                width: selected ? 1.2 : 0.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? SiftColors.accent
                      : SiftColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? SiftColors.accent
                        : SiftColors.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        segment(SiftThemeMode.dark, Icons.dark_mode_outlined, 'Dark'),
        const SizedBox(width: 8),
        segment(SiftThemeMode.light, Icons.light_mode_outlined, 'Light'),
        const SizedBox(width: 8),
        segment(SiftThemeMode.system, Icons.brightness_auto_outlined, 'System'),
      ],
    );
  }
}
