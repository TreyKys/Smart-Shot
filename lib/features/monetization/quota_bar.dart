import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/economy/economy_service.dart';
import 'package:sift/features/pro/presentation/paywall_sheet.dart';
import 'package:sift/features/pro/pro_service.dart';

class QuotaBar extends ConsumerWidget {
  const QuotaBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(proServiceProvider);
    if (isPro) return const SizedBox.shrink();

    final energyAsync = ref.watch(economyServiceProvider);

    return energyAsync.when(
      data: (energy) => _QuotaBarContent(energy: energy)
          .animate()
          .fadeIn(duration: 300.ms),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QuotaBarContent extends ConsumerWidget {
  final int energy;
  const _QuotaBarContent({required this.energy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fraction = (energy / kDailyFreeExtractions).clamp(0.0, 1.0);
    final isDepleted = energy <= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SiftColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiftColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isDepleted ? Icons.bolt_outlined : Icons.bolt,
                color: isDepleted ? SiftColors.textTertiary : SiftColors.accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isDepleted
                    ? 'AI scans depleted — recharge to continue'
                    : '$energy / $kDailyFreeExtractions AI scans remaining today',
                style: TextStyle(
                  color: isDepleted ? SiftColors.textTertiary : SiftColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isDepleted)
                GestureDetector(
                  onTap: () => _watchAd(context, ref),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SiftColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: SiftColors.accent.withOpacity(0.5)),
                    ),
                    child: const Text(
                      'Watch Ad',
                      style: TextStyle(
                        color: SiftColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                backgroundColor: SiftColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDepleted ? SiftColors.textTertiary : SiftColors.accent,
                ),
                minHeight: 3,
              ),
            ),
          ),
          if (isDepleted) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => showPaywallSheet(context, triggerFeature: 'quota_depleted'),
              child: Row(
                children: [
                  const Icon(Icons.workspace_premium_outlined,
                      color: SiftColors.proGold, size: 14),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'You\'ve used all 30 scans today — Pro users never stop.',
                      style: TextStyle(
                        color: SiftColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Go Pro →',
                    style: TextStyle(
                      color: SiftColors.proGold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _watchAd(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Loading ad... Watch 2 ads to earn +10 scans.')),
    );
    ref.read(economyServiceProvider.notifier).showRewardedAd(
      onBlockCompleted: () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('+10 AI scans unlocked!')),
          );
        }
      },
    );
  }
}
