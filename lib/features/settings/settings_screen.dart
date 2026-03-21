import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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
                      onPressed: _showPaywall,
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
                   ref.read(economyServiceProvider.notifier).showRewardedAd(onBlockCompleted: () {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Energy Refilled!')));
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
        ],
      ),
    );
  }

  Future<void> _showPaywall() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) => _PaywallView(offering: offerings.current!),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No packages available at this time.')));
      }
    } catch (e) {
      debugPrint("Error fetching offerings: $e");
    }
  }
}

class _PaywallView extends ConsumerWidget {
  final Offering offering;

  const _PaywallView({required this.offering});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sift Pro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text('• Infinite AI Fuel (No Ads)\n• Deep Backlog Sweep\n• Custom Tags & Vaults\n• Advanced Exports (Notion, PDF)', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 24),
          ...offering.availablePackages.map((pkg) =>
             Padding(
               padding: const EdgeInsets.only(bottom: 8.0),
               child: ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(vertical: 16),
                   backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                 ),
                 onPressed: () async {
                   await ref.read(proServiceProvider.notifier).purchasePackage(pkg);
                   if (context.mounted) Navigator.pop(context);
                 },
                 child: Text('${pkg.storeProduct.title} - ${pkg.storeProduct.priceString}', style: const TextStyle(fontSize: 16)),
               ),
             )
          ),
          TextButton(
             onPressed: () async {
                await ref.read(proServiceProvider.notifier).restorePurchases();
                if (context.mounted) Navigator.pop(context);
             },
             child: const Text('Restore Purchases'),
          )
        ],
      ),
    );
  }
}
