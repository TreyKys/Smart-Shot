import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/pro/pro_service.dart';

void showPaywallSheet(BuildContext context, {String? triggerFeature}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallSheetContent(triggerFeature: triggerFeature),
  );
}

class PaywallSheetContent extends ConsumerStatefulWidget {
  final String? triggerFeature;
  const PaywallSheetContent({super.key, this.triggerFeature});

  @override
  ConsumerState<PaywallSheetContent> createState() => _PaywallSheetContentState();
}

class _PaywallSheetContentState extends ConsumerState<PaywallSheetContent> {
  List<Package> _packages = [];
  bool _loading = true;
  int _selectedIndex = 1; // Default: Annual

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null) {
        setState(() {
          _packages = offerings.current!.availablePackages;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Paywall: failed to load offerings: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E).withOpacity(0.97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: SiftColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              decoration: BoxDecoration(
                color: SiftColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Pro badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'SIFT PRO',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.85, 0.85)),
                  const SizedBox(height: 16),
                  if (widget.triggerFeature != null) ...[
                    Text(
                      '${widget.triggerFeature} is a Pro feature',
                      style: const TextStyle(
                        color: SiftColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Text(
                    'Unlimited AI. Zero Ads.\nOwn your data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: SiftColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Feature bullets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _FeatureRow(icon: Icons.all_inclusive, text: 'Infinite AI scans — no daily limit'),
                  _FeatureRow(icon: Icons.block, text: 'Zero ads. Ever.'),
                  _FeatureRow(icon: Icons.select_all, text: 'Batch scan up to 50 screenshots'),
                  _FeatureRow(icon: Icons.auto_delete, text: 'Automated Smart Purge scheduling'),
                  _FeatureRow(icon: Icons.ios_share, text: 'Advanced Markdown export'),
                ].animate(interval: 60.ms).fadeIn(duration: 300.ms).slideX(begin: -0.05),
              ),
            ),

            const SizedBox(height: 24),

            // Package tiles
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: SiftColors.accent),
              )
            else if (_packages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStaticTiles(),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(_packages.length, (i) {
                    final pkg = _packages[i];
                    final isSelected = i == _selectedIndex;
                    return _PackageTile(
                      package: pkg,
                      isSelected: isSelected,
                      badge: _badgeFor(pkg),
                      onTap: () => setState(() => _selectedIndex = i),
                    );
                  }),
                ),
              ),

            const SizedBox(height: 16),

            // CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SiftColors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _packages.isEmpty ? null : () => _purchase(_packages[_selectedIndex]),
                  child: const Text(
                    'UNLOCK SIFT PRO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: () async {
                await ref.read(proServiceProvider.notifier).restorePurchases();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Restore Purchases',
                style: TextStyle(color: SiftColors.textSecondary, fontSize: 13),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticTiles() {
    // Fallback when RevenueCat isn't configured yet
    final tiers = [
      ('Monthly', r'$5.99/mo', null),
      ('Annual', r'$49.99/yr', 'BEST VALUE — SAVE 30%'),
      ('Lifetime', r'$129.99', 'OWN IT FOREVER'),
    ];
    return Column(
      children: List.generate(tiers.length, (i) {
        final (title, price, badge) = tiers[i];
        final isSelected = i == _selectedIndex;
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? SiftColors.accent.withOpacity(0.1) : SiftColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? SiftColors.accent : SiftColors.border,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badge != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SiftColors.proGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: SiftColors.proGold,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      Text(title,
                          style: TextStyle(
                            color: isSelected ? SiftColors.accent : SiftColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    color: isSelected ? SiftColors.accent : SiftColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String? _badgeFor(Package pkg) {
    final id = pkg.packageType;
    if (id == PackageType.annual) return 'BEST VALUE — SAVE 30%';
    if (id == PackageType.lifetime) return 'OWN IT FOREVER';
    return null;
  }

  Future<void> _purchase(Package pkg) async {
    try {
      await ref.read(proServiceProvider.notifier).purchasePackage(pkg);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Purchase error: $e');
    }
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: SiftColors.accent, size: 18),
          const SizedBox(width: 12),
          Text(text,
              style: const TextStyle(
                color: SiftColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final String? badge;
  final VoidCallback onTap;

  const _PackageTile({
    required this.package,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? SiftColors.accent.withOpacity(0.1) : SiftColors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? SiftColors.accent : SiftColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SiftColors.proGold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: SiftColors.proGold,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Text(
                    package.storeProduct.title.isNotEmpty
                        ? package.storeProduct.title
                        : package.identifier,
                    style: TextStyle(
                      color: isSelected ? SiftColors.accent : SiftColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              package.storeProduct.priceString,
              style: TextStyle(
                color: isSelected ? SiftColors.accent : SiftColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
