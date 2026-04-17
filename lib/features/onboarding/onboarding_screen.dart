import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/theme/app_theme.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:sift/features/gallery/services/background_service.dart';
import 'package:sift/features/pro/presentation/paywall_sheet.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingPage(
      gradient: [Color(0xFF090909), Color(0xFF0D1A1A)],
      icon: Icons.screenshot_monitor,
      title: 'Your Screenshots,\nFinally Organised',
      subtitle:
          'Sift uses on-device AI to automatically tag, search and surface the information trapped in your screenshots.',
    ),
    _OnboardingPage(
      gradient: [Color(0xFF0A0A12), Color(0xFF0D0D1F)],
      icon: Icons.auto_awesome,
      title: 'AI That Actually\nUnderstands Context',
      subtitle:
          'Receipts, crypto addresses, to-dos, memes — Sift reads every screenshot and extracts the data that matters.',
    ),
    _OnboardingPage(
      gradient: [Color(0xFF0A120A), Color(0xFF0A1A0D)],
      icon: Icons.bolt,
      title: '30 Free AI Scans\nEvery Day',
      subtitle:
          'Free tier gives you 30 daily AI scans. Watch 2 short ads to earn +10 more. Go Pro for unlimited.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SiftColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => _showModeSelector(context),
                child: const Text(
                  'Skip',
                  style: TextStyle(color: SiftColors.textSecondary, fontSize: 14),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length + 1, // +1 for choose-path page
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _PageContent(page: _pages[index], index: index);
                  }
                  return _ChoosePathPage(onLive: _activateLiveMode, onDeep: () {
                    showPaywallSheet(context,
                        triggerFeature: 'Deep Mode (Full Backlog Scan)');
                  });
                },
              ),
            ),

            // Indicator + Next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length + 1,
                    effect: const WormEffect(
                      dotColor: SiftColors.border,
                      activeDotColor: SiftColors.accent,
                      dotHeight: 6,
                      dotWidth: 6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentPage < _pages.length)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Next'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _activateLiveMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('smart_indexing_mode', 'live');
    await prefs.setInt(
        'live_mode_timestamp', DateTime.now().millisecondsSinceEpoch);
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    _navigateToGallery();
  }

  void _showModeSelector(BuildContext context) {
    _controller.animateToPage(
      _pages.length,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToGallery() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
  }
}

// ── Pages ─────────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardingPage({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  final int index;
  const _PageContent({required this.page, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: SiftColors.accent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: SiftColors.accent.withOpacity(0.3), width: 1),
              ),
              child: Icon(page.icon, color: SiftColors.accent, size: 40),
            )
                .animate(delay: (index * 50).ms)
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 40),
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SiftColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            )
                .animate(delay: (index * 50 + 100).ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1),
            const SizedBox(height: 20),
            Text(
              page.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SiftColors.textSecondary,
                fontSize: 16,
                height: 1.5,
              ),
            )
                .animate(delay: (index * 50 + 200).ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}

class _ChoosePathPage extends StatelessWidget {
  final VoidCallback onLive;
  final VoidCallback onDeep;
  const _ChoosePathPage({required this.onLive, required this.onDeep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Choose Your\nSifting Mode',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: SiftColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),
          const Text(
            'You can change this later in Settings.',
            style: TextStyle(color: SiftColors.textSecondary, fontSize: 14),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 40),

          // Live Mode card
          _ModeCard(
            icon: Icons.fiber_new,
            iconColor: SiftColors.accent,
            title: 'Live Mode',
            description:
                'Only scan new screenshots going forward. Instant, lightweight, free.',
            badgeText: 'FREE',
            badgeColor: SiftColors.success,
            onTap: onLive,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

          const SizedBox(height: 14),

          // Deep Mode card
          _ModeCard(
            icon: Icons.manage_search,
            iconColor: SiftColors.proGold,
            title: 'Deep Mode',
            description:
                'Scan your entire screenshot history. Unlock the full power of Sift.',
            badgeText: 'PRO',
            badgeColor: SiftColors.proGold,
            onTap: onDeep,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SiftColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SiftColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: SiftColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: SiftColors.textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: SiftColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
