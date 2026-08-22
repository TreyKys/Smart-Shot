import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:sift/features/pro/presentation/paywall_sheet.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PRO STATUS
          Card(
            color: isPro ? Colors.amber.shade100 : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isPro ? 'Sift Pro Active' : 'Sift Free', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (!isPro) ...[
                    Text(
                      'Unlock infinite AI fuel, deep backlog sweeping, custom vaults, and advanced exports.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => showPaywallSheet(context, triggerFeature: 'Settings'),
                      child: const Text('Upgrade to Pro'),
                    )
                  ] else ...[
                    const Text('Thank you for supporting Sift! You have unlimited access to all features.')
                  ]
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ENERGY STATE
          if (!isPro) ...[
            ListTile(
              leading: const Icon(Icons.bolt),
              title: const Text('AI Energy'),
              subtitle: Text(
                energyState.when(
                  data: (energy) => 'Remaining: $energy',
                  loading: () => 'Loading...',
                  error: (e, s) => 'Error loading energy',
                )
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 16),
                          Text('Loading high-value ad...'),
                        ],
                      ),
                      duration: Duration(seconds: 2),
                    )
                  );
                  ref.read(economyServiceProvider.notifier).showRewardedAd(onBlockCompleted: () {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('+10 AI scans unlocked!')));
                    }
                  });
                },
                child: const Text('Refill (2 Ads)'),
              ),
            ),
            const Divider(),
          ],

          // BYOK
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Bring Your Own Key (Gemini)'),
            subtitle: const Text('Power users: Bypass the energy and ad systems entirely by using your own Gemini API key.'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _byokController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Gemini API Key',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    await ref.read(economyServiceProvider.notifier).setByokKey(_byokController.text);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Key saved!')));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),

          // LEGAL
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => _openUrl(context, kPrivacyPolicyUrl),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.open_in_new, size: 18),
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
