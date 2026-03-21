import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/features/gallery/presentation/gallery_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
            ),
            _buildPage(
              icon: Icons.document_scanner_outlined,
              title: "Instant OCR Extraction",
              description: "Every screenshot you take is instantly scanned offline. All text is extracted, made searchable, and stored securely on your device for free.",
            ),
            _buildPage(
              icon: Icons.auto_awesome,
              title: "The AI Brain",
              description: "Sift analyzes the text to generate summaries, extract links, dates, and build one-tap actions so you never lose context.",
            ),
            _buildPage(
              icon: Icons.bolt,
              title: "The Economy",
              description: "You get 10 free AI scans every day. Need more? Watch a quick ad or upgrade to Sift Pro for infinite energy and deep backlog scanning.",
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _controller.jumpToPage(3),
              child: const Text('Skip'),
            ),
            Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: WormEffect(
                  activeDotColor: Theme.of(context).colorScheme.primary,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (_isLastPage) {
                  _completeOnboarding();
                } else {
                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
              child: Text(_isLastPage ? 'Start' : 'Next'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required IconData icon, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 100, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(description, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
