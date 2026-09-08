import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:sift/features/pro/presentation/paywall_sheet.dart';
import 'package:sift/features/settings/diagnostic_log_screen.dart';

// Mirrors legal/privacy-policy.html and legal/terms.html in this repo — kept
// in sync manually, since neurodevlabs.cloud is built from a separate repo.
const String kPrivacyPolicyUrl = 'https://neurodevlabs.cloud/sift/privacy-policy.html';
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
    _byokController.text = ref.read(economyServiceProvider.notifier).getByokKey() ?? '';
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
    final savedByokKey = ref.watch(economyServiceProvider.notifier).getByokKey();
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
                  ? SiftColors.proGold.withOpacity(0.12)
                  : SiftColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPro
                    ? SiftColors.proGold.withOpacity(0.4)
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
                  const Text(
                    'Unlock infinite AI fuel, deep backlog sweeping, custom vaults, and advanced exports.',
                    style: TextStyle(
                        color: SiftColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        showPaywallSheet(context, triggerFeature: 'Settings'),
                    child: const Text('Upgrade to Pro'),
                  )
                ] else ...[
                  const Text(
                    'Thank you for supporting Sift! You have unlimited access to all features.',
                    style: TextStyle(
                        color: SiftColors.textSecondary, fontSize: 13),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ENERGY STATE
          if (!isPro && !hasByok) ...[
            _SettingsTile(
              leading: const Icon(Icons.bolt, color: SiftColors.accent),
              title: 'AI Energy',
              subtitle: energyState.when(
                data: (energy) => 'Remaining: $energy',
                loading: () => 'Loading...',
                error: (e, s) => 'Error loading energy',
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 16),
                          Text('Loading high-value ad...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  ref
                      .read(economyServiceProvider.notifier)
                      .showRewardedAd(onBlockCompleted: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('+10 AI scans unlocked!')));
                    }
                  });
                },
                child: const Text('Refill (2 Ads)'),
              ),
            ),
            const Divider(color: SiftColors.border, height: 24),
          ],

          // BYOK
          const _SettingsTile(
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
                    style: const TextStyle(color: SiftColors.textPrimary),
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
                          const SnackBar(content: Text('Key saved!')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: SiftColors.border, height: 1),
          const SizedBox(height: 8),

          // DIAGNOSTICS
          _SettingsTile(
            leading: const Icon(Icons.bug_report_outlined,
                color: SiftColors.textSecondary),
            title: 'Diagnostics Log',
            subtitle:
                'See whether AI tagging is actually succeeding on this device.',
            trailing: const Icon(Icons.chevron_right,
                color: SiftColors.textTertiary),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiagnosticLogScreen()),
            ),
          ),
          const Divider(color: SiftColors.border, height: 24),

          // LEGAL
          _SettingsTile(
            leading: const Icon(Icons.privacy_tip_outlined,
                color: SiftColors.textSecondary),
            title: 'Privacy Policy',
            trailing: const Icon(Icons.open_in_new,
                size: 18, color: SiftColors.textTertiary),
            onTap: () => _openUrl(context, kPrivacyPolicyUrl),
          ),
          _SettingsTile(
            leading: const Icon(Icons.description_outlined,
                color: SiftColors.textSecondary),
            title: 'Terms of Service',
            trailing: const Icon(Icons.open_in_new,
                size: 18, color: SiftColors.textTertiary),
            onTap: () => _openUrl(context, kTermsOfServiceUrl),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link.')),
      );
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
                    style: const TextStyle(
                      color: SiftColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                          color: SiftColors.textSecondary, fontSize: 12),
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
