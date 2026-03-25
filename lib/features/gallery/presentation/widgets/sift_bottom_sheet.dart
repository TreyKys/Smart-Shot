import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/settings/settings_screen.dart';
import 'package:sift/core/theme/theme_provider.dart';

void showSiftBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SiftBottomSheetContent(),
  );
}

class SiftBottomSheetContent extends ConsumerWidget {
  const SiftBottomSheetContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(uniqueTagsProvider);
    final selectedTag = ref.watch(selectedTagProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SIFT MENU",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                        color: isDark ? Colors.cyanAccent : Colors.deepPurple,
                        onPressed: () {
                           ref.read(themeModeNotifierProvider.notifier).toggle();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        color: isDark ? Colors.white70 : Colors.black54,
                        onPressed: () {
                          Navigator.pop(context); // Close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.grid_view,
                    title: "All Screenshots",
                    isSelected: selectedTag == null,
                    onTap: () {
                      ref.read(selectedTagProvider.notifier).select(null);
                      Navigator.pop(context);
                    },
                    isDark: isDark,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
                    child: Text(
                      "CATEGORIES",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  tagsAsync.when(
                    data: (tags) {
                      if (tags.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              "No smart tags generated yet.",
                              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: tags.map((tag) => _buildMenuItem(
                          context,
                          icon: _getIconForTag(tag),
                          title: tag,
                          isSelected: selectedTag == tag,
                          onTap: () {
                            ref.read(selectedTagProvider.notifier).select(tag);
                            Navigator.pop(context);
                          },
                          isDark: isDark,
                        )).toList(),
                      );
                    },
                    error: (err, stack) => Center(child: Text('Error: $err')),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    )),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = isDark ? Colors.cyanAccent : Colors.deepPurple;
    final inactiveColor = isDark ? Colors.white70 : Colors.black87;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? activeColor : inactiveColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? activeColor : inactiveColor,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: isSelected ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
      onTap: onTap,
    );
  }

  IconData _getIconForTag(String tag) {
    final lower = tag.toLowerCase().replaceAll('#', '');
    if (lower.contains('finance') || lower.contains('receipt') || lower.contains('money')) {
      return CupertinoIcons.money_dollar;
    }
    if (lower.contains('travel') || lower.contains('flight')) {
      return CupertinoIcons.airplane;
    }
    if (lower.contains('web3') || lower.contains('crypto') || lower.contains('btc') || lower.contains('eth')) {
      return CupertinoIcons.bitcoin;
    }
    if (lower.contains('code') || lower.contains('dev') || lower.contains('git')) {
      return CupertinoIcons.chevron_left_slash_chevron_right;
    }
    if (lower.contains('social') || lower.contains('instagram') || lower.contains('twitter') || lower.contains('x')) {
      return CupertinoIcons.person_2;
    }
    if (lower.contains('meme') || lower.contains('funny')) {
      return CupertinoIcons.smiley;
    }
    if (lower.contains('chem') || lower.contains('science') || lower.contains('lab')) {
      return CupertinoIcons.lab_flask;
    }
    if (lower.contains('date') || lower.contains('calendar') || lower.contains('schedule')) {
      return CupertinoIcons.calendar;
    }
    if (lower.contains('chart') || lower.contains('trading') || lower.contains('stock')) {
      return CupertinoIcons.graph_circle;
    }
    if (lower.contains('news') || lower.contains('article')) {
      return CupertinoIcons.news;
    }
    if (lower.contains('shop') || lower.contains('buy')) {
      return CupertinoIcons.shopping_cart;
    }
    if (lower.contains('music') || lower.contains('song')) {
      return CupertinoIcons.music_note;
    }
    if (lower.contains('video') || lower.contains('movie')) {
      return CupertinoIcons.film;
    }
    if (lower.contains('book') || lower.contains('read') || lower.contains('edu')) {
      return CupertinoIcons.book;
    }

    return CupertinoIcons.tag;
  }
}
