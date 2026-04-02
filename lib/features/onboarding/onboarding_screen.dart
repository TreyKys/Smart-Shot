import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sift/features/pro/presentation/pro_modal.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            setState(() => _isLastPage = index == 3);
          },
          children: [
            _buildPage(
              icon: Icons.photo_library_outlined,
              title: "The Screenshot Graveyard",
              description: "You take screenshots to remember things. Instead, they get lost in your camera roll forever. Sift changes that.",
              gradientColors: [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)],
            ),
            _buildPage(
              icon: Icons.document_scanner_outlined,
              title: "Instant OCR Extraction",
              description: "Every screenshot you take is instantly scanned offline. All text is extracted, made searchable, and stored securely on your device for free.",
              gradientColors: [const Color(0xFF141E30), const Color(0xFF243B55)],
            ),
            _buildPage(
              icon: Icons.auto_awesome,
              title: "The AI Brain",
              description: "Sift analyzes the text to generate summaries, extract links, dates, and build one-tap actions so you never lose context.",
              gradientColors: [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)],
            ),
            _buildPage(
              icon: Icons.bolt,
              title: "Choose Your Path",
              description: "Decide how Sift handles your gallery.",
              gradientColors: [const Color(0xFF1CB5E0), const Color(0xFF000851)],
              isFinalPage: true,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 80,
        color: const Color(0xFF000851),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _controller.jumpToPage(3),
              child: const Text('SKIP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
            Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: const WormEffect(
                  activeDotColor: Colors.cyanAccent,
                  dotColor: Colors.white24,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (!_isLastPage) {
                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                } else {
                  // Do nothing, let them click the buttons
                }
              },
              child: Text(_isLastPage ? '' : 'NEXT', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    bool isFinalPage = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      padding: const EdgeInsets.all(40.0),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 120, color: Colors.white),
            const SizedBox(height: 48),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2.0,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              description,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFinalPage) ...[
              const SizedBox(height: 60),
              _buildChoiceCard(
                title: "LIVE SCAN",
                subtitle: "Free, ad-supported mode. Scans new screenshots.",
                icon: Icons.bolt,
                color: Colors.white.withValues(alpha: 0.1),
                borderColor: Colors.white.withValues(alpha: 0.3),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('smart_indexing_mode', 'live');
                  await prefs.setInt('live_mode_timestamp', DateTime.now().millisecondsSinceEpoch);
                  _completeOnboarding();
                },
              ),
              const SizedBox(height: 16),
              _buildChoiceCard(
                title: "DEEP MODE (PRO)",
                subtitle: "Premium. Scans your entire history in the background.",
                icon: Icons.all_inclusive,
                color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                borderColor: Colors.deepPurpleAccent,
                onTap: () {
                  // Trigger Pro Modal
                  showProModal(context, onSubscribe: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('smart_indexing_mode', 'deep');
                    _completeOnboarding();
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
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
}
