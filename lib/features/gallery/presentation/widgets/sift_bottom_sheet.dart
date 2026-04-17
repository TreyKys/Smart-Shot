import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/core/theme/theme_provider.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/settings/settings_screen.dart';

void showSiftBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SiftBottomSheetContent(),
  );
}

class SiftBottomSheetContent extends ConsumerWidget {
  const SiftBottomSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(uniqueTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0E0E0E).withOpacity(0.97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: SiftColors.border, width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: SiftColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'SIFT',
                    style: TextStyle(
                      color: SiftColors.accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'MENU',
                    style: TextStyle(
                      color: SiftColors.textTertiary,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  // Theme toggle
                  GestureDetector(
                    onTap: () =>
                        ref.read(themeModeNotifierProvider.notifier).toggle(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SiftColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: SiftColors.border, width: 0.5),
                      ),
                      child: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: SiftColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: SiftColors.border, thickness: 0.5, height: 1),

            // Navigation items
            _MenuItem(
              icon: Icons.grid_view_rounded,
              label: 'All Screenshots',
              isSelected: selectedTag == null,
              onTap: () {
                ref.read(selectedTagProvider.notifier).select(null);
                Navigator.pop(context);
              },
            ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05),

            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings & Pro',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                );
              },
            ).animate(delay: 40.ms).fadeIn(duration: 200.ms).slideX(begin: -0.05),

            if (tagsAsync.hasValue && tagsAsync.value!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'CATEGORIES',
                      style: TextStyle(
                        color: SiftColors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: tagsAsync.value!.length,
                  itemBuilder: (context, i) {
                    final tag = tagsAsync.value![i];
                    return _MenuItem(
                      icon: Icons.label_outline,
                      iconColor: SiftColors.forTag(tag),
                      label: tag,
                      isSelected: selectedTag == tag,
                      onTap: () {
                        ref.read(selectedTagProvider.notifier).select(tag);
                        Navigator.pop(context);
                      },
                    )
                        .animate(delay: ((i + 3) * 30).ms)
                        .fadeIn(duration: 200.ms)
                        .slideX(begin: -0.05);
                  },
                ),
              ),
            ],

            SizedBox(bottom: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected
            ? SiftColors.accent.withOpacity(0.05)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? SiftColors.accent
                  : (iconColor ?? SiftColors.textSecondary),
              size: 20,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? SiftColors.accent : SiftColors.textPrimary,
                fontSize: 15,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SiftColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
