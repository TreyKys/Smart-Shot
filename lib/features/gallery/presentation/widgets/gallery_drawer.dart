import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/settings/settings_screen.dart';

class GalleryDrawer extends ConsumerWidget {
  const GalleryDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagCountsProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final totalScreenshots = ref.watch(galleryStreamProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => null,
        );

    return Drawer(
      backgroundColor: SiftColors.surface,
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: SiftColors.background,
              border: Border(
                bottom: BorderSide(color: SiftColors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SiftColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: SiftColors.accent.withOpacity(0.4),
                        width: 1),
                  ),
                  child: const Center(
                    child: Icon(Icons.filter_alt,
                        color: SiftColors.accent, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Categories',
                    style: const TextStyle(
                      color: SiftColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (totalScreenshots != null)
                  Text(
                    '$totalScreenshots shot${totalScreenshots == 1 ? '' : 's'}',
                    style: const TextStyle(
                        color: SiftColors.textTertiary, fontSize: 12),
                  ),
              ],
            ),
          ),

          // All Screenshots
          _DrawerTile(
            icon: Icons.grid_view_rounded,
            label: 'All Screenshots',
            isSelected: selectedTag == null,
            onTap: () {
              ref.read(selectedTagProvider.notifier).select(null);
              Navigator.pop(context);
            },
          ),

          const Divider(
              color: SiftColors.border, thickness: 0.5, height: 1),

          // Tag list
          Expanded(
            child: tagsAsync.when(
              data: (tags) {
                if (tags.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tags yet.\nScreenshots will be\ntagged automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: SiftColors.textTertiary, fontSize: 13),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final entry = tags[index];
                    final tag = entry.tag;
                    final count = entry.count;
                    return _DrawerTile(
                      icon: _getIconForTag(tag),
                      iconColor: SiftColors.forTag(tag),
                      label: tag.startsWith('#') ? tag.substring(1) : tag,
                      count: count,
                      isSelected: selectedTag == tag,
                      onTap: () {
                        ref.read(selectedTagProvider.notifier).select(tag);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
              error: (err, _) => Center(
                  child: Text('Error: $err',
                      style:
                          const TextStyle(color: SiftColors.danger))),
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: SiftColors.accent)),
            ),
          ),

          // Bottom: Settings link
          const Divider(
              color: SiftColors.border, thickness: 0.5, height: 1),
          _DrawerTile(
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
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  IconData _getIconForTag(String tag) {
    final lower = tag.toLowerCase().replaceAll('#', '');
    if (lower.contains('finance') ||
        lower.contains('receipt') ||
        lower.contains('money')) return CupertinoIcons.money_dollar;
    if (lower.contains('travel') || lower.contains('flight'))
      return CupertinoIcons.airplane;
    if (lower.contains('web3') ||
        lower.contains('crypto') ||
        lower.contains('btc') ||
        lower.contains('eth')) return CupertinoIcons.bitcoin;
    if (lower.contains('code') ||
        lower.contains('dev') ||
        lower.contains('git'))
      return CupertinoIcons.chevron_left_slash_chevron_right;
    if (lower.contains('social') ||
        lower.contains('instagram') ||
        lower.contains('twitter') ||
        lower.contains('x')) return CupertinoIcons.person_2;
    if (lower.contains('meme') || lower.contains('funny'))
      return CupertinoIcons.smiley;
    if (lower.contains('chem') ||
        lower.contains('science') ||
        lower.contains('lab')) return CupertinoIcons.lab_flask;
    if (lower.contains('date') ||
        lower.contains('calendar') ||
        lower.contains('schedule')) return CupertinoIcons.calendar;
    if (lower.contains('chart') ||
        lower.contains('trading') ||
        lower.contains('stock')) return CupertinoIcons.graph_circle;
    if (lower.contains('news') || lower.contains('article'))
      return CupertinoIcons.news;
    if (lower.contains('shop') || lower.contains('buy'))
      return CupertinoIcons.shopping_cart;
    if (lower.contains('music') || lower.contains('song'))
      return CupertinoIcons.music_note;
    if (lower.contains('video') || lower.contains('movie'))
      return CupertinoIcons.film;
    if (lower.contains('book') ||
        lower.contains('read') ||
        lower.contains('edu')) return CupertinoIcons.book;
    if (lower.contains('sport') || lower.contains('football') ||
        lower.contains('soccer')) return CupertinoIcons.sportscourt;
    if (lower.contains('food') || lower.contains('restaurant'))
      return CupertinoIcons.cart;
    return CupertinoIcons.tag;
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = isSelected
        ? SiftColors.accent
        : (iconColor ?? SiftColors.textSecondary);

    return InkWell(
      onTap: onTap,
      splashColor: SiftColors.accent.withOpacity(0.05),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: isSelected
            ? SiftColors.accent.withOpacity(0.06)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(icon, color: effectiveIconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? SiftColors.accent
                      : SiftColors.textPrimary,
                  fontSize: 15,
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.w400,
                ),
              ),
            ),
            if (count != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: SiftColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: SiftColors.textTertiary, fontSize: 11),
                ),
              ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: SiftColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
