import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/purge/purge_service.dart';

class PurgeBanner extends ConsumerWidget {
  const PurgeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purgeAsync = ref.watch(purgeServiceProvider);

    return purgeAsync.when(
      data: (result) {
        if (result == null || result.count == 0) return const SizedBox.shrink();

        return _BannerContent(result: result)
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: -0.2, duration: 350.ms, curve: Curves.easeOut);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BannerContent extends ConsumerWidget {
  final PurgeResult result;
  const _BannerContent({required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: SiftColors.danger.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SiftColors.danger.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_delete_outlined, color: SiftColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You have ${result.count} useless screenshots taking up ${result.formattedSize}. Delete?',
              style: const TextStyle(
                color: SiftColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmPurge(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: SiftColors.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurge(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SiftColors.surface,
        title: const Text('Confirm Delete', style: TextStyle(color: SiftColors.textPrimary)),
        content: Text(
          'This will permanently delete ${result.count} screenshots tagged as junk, memes, or to-do items older than 30 days (${result.formattedSize} freed).',
          style: const TextStyle(color: SiftColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: SiftColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SiftColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final deleted = await ref.read(purgeServiceProvider.notifier).executePurge();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted $deleted screenshots.')),
        );
      }
    }
  }
}
