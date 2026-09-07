import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/assistant/presentation/assistant_screen.dart';
import 'package:sift/features/collections/presentation/collections_screen.dart';
import 'package:sift/features/discover/presentation/discover_screen.dart';
import 'package:sift/features/gallery/data/gallery_repository.dart';
import 'package:sift/features/gallery/presentation/gallery_provider.dart';
import 'package:sift/features/gallery/presentation/widgets/smart_indexing_dialog.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/features/organize/presentation/organize_screen.dart';

/// Public so NotificationService can switch tabs from outside the widget
/// tree — a notification tap has no BuildContext of its own to reach into
/// the shell with, the same reason appNavigatorKey exists in
/// lib/core/navigation.dart. Both keys serve main.dart's single MaterialApp.
final GlobalKey<MainShellState> mainShellKey = GlobalKey<MainShellState>();

const int kDiscoverTabIndex = 0;
const int kOrganizeTabIndex = 1;
const int kAssistantTabIndex = 2;
const int kCollectionsTabIndex = 3;

/// Root navigation shell — Discover / Organize / Sift AI / Collections as
/// persistent tabs, replacing GalleryScreen as main.dart's home. Each tab
/// keeps its existing Scaffold/AppBar exactly as it already had it: Flutter
/// only shows a back button when there's actually somewhere to pop back to
/// (Navigator.canPop), so a tab embedded here with nothing pushed below it
/// renders with no back arrow automatically, and the same screen still
/// works completely unchanged wherever else it's independently pushed
/// (e.g. JunkReviewScreen and DuplicateReviewScreen push from Discover;
/// GalleryScreen pushes from Organize).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => MainShellState();
}

class MainShellState extends ConsumerState<MainShell> {
  int _index = kDiscoverTabIndex;

  static const _tabs = [
    DiscoverScreen(),
    OrganizeScreen(),
    AssistantScreen(),
    CollectionsScreen(),
  ];

  /// Called by NotificationService when a notification names a specific tab
  /// to land on (e.g. a Memories notification routes here to Discover).
  void selectTab(int index) => setState(() => _index = index);

  // Formerly ran from GalleryScreen.initState — moved here when MainShell
  // replaced GalleryScreen as main.dart's home. GalleryScreen is now reached
  // only by pushing from the Organize tab, so a user who stays on
  // Discover/Organize/Sift AI/Collections for an entire session would never
  // trigger these otherwise, silently losing first-run indexing consent,
  // garbage-tag cleanup, and pin restoration (the last of which Sift AI's own
  // tab reads via pinnedIdsProvider).
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _checkSmartIndexingConsent();
      ref.read(galleryRepositoryProvider).reprocessGarbageTags();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList('pinned_ids') ?? [];
      final ids = raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
      if (mounted) ref.read(pinnedIdsProvider.notifier).state = ids;
    });
  }

  Future<void> _checkSmartIndexingConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('smart_indexing_mode');

    if (mode == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => SmartIndexingDialog(
          onLiveMode: () async {
            Navigator.of(context).pop();
            await prefs.setString('smart_indexing_mode', 'live');
            await prefs.setInt(
                'live_mode_timestamp', DateTime.now().millisecondsSinceEpoch);
            // Live Mode's promise is "new screenshots get indexed" — without
            // this, that only happens while the app is open. See
            // background_service.dart's discoverNewScreenshots call.
            await scheduleBackgroundSync();
            ref.read(galleryRepositoryProvider).syncGallery();
          },
          onDeepScan: () async {
            Navigator.of(context).pop();
            await prefs.setString('smart_indexing_mode', 'deep');
            await scheduleBackgroundSync();
            ref.read(galleryRepositoryProvider).syncGallery();
          },
        ),
      );
    } else {
      // Covers users who picked a mode before background sync applied to
      // both — re-registering is idempotent (WorkManager keeps one task per
      // unique name), so this just backfills Live Mode users who are still
      // foreground-only from an earlier version.
      await scheduleBackgroundSync();
      ref.read(galleryRepositoryProvider).syncGallery();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiftPillowyColors.surface,
      // IndexedStack, not a plain child swap — every tab keeps its scroll
      // position and in-flight state (the assistant's chat history, a
      // half-typed message) when switching away and back, the same way a
      // real bottom-nav app is expected to behave.
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _PillowyBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _PillowyBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _PillowyBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SiftPillowyColors.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: SiftPillowyColors.onSurface.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'Discover',
                selected: currentIndex == kDiscoverTabIndex,
                onTap: () => onTap(kDiscoverTabIndex),
              ),
              _NavItem(
                icon: Icons.folder_special_outlined,
                label: 'Organize',
                selected: currentIndex == kOrganizeTabIndex,
                onTap: () => onTap(kOrganizeTabIndex),
              ),
              _CenterNavItem(
                selected: currentIndex == kAssistantTabIndex,
                onTap: () => onTap(kAssistantTabIndex),
              ),
              _NavItem(
                icon: Icons.collections_bookmark_outlined,
                label: 'Collections',
                selected: currentIndex == kCollectionsTabIndex,
                onTap: () => onTap(kCollectionsTabIndex),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SiftPillowyColors.primary
        : SiftPillowyColors.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: SiftPillowyText.labelSm
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// The raised circular "Sift AI" button — the mockup's centerpiece nav
/// treatment, carried over because it's purely visual (which tab is
/// selected), not a claim about any capability.
class _CenterNavItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _CenterNavItem({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                gradient: SiftPillowyColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SiftPillowyColors.primaryContainer.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          Text('Sift AI',
              style: SiftPillowyText.labelSm.copyWith(
                  color: SiftPillowyColors.primary,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
