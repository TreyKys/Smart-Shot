import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void showProModal(BuildContext context, {VoidCallback? onSubscribe}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ProModalContent(onSubscribe: onSubscribe),
  );
}

class ProModalContent extends ConsumerWidget {
  final VoidCallback? onSubscribe;

  const ProModalContent({super.key, this.onSubscribe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "SIFT PRO",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Unlock the full power of the AI brain. No limits, no ads, just pure context extraction.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(Icons.all_inclusive, "Infinite AI Scans"),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.history_toggle_off, "Deep Mode Backlog Scanning"),
            const SizedBox(height: 16),
            _buildFeatureRow(Icons.block, "Zero Ads. Ever."),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                 try {
                  final offerings = await Purchases.getOfferings();
                  if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
                    final pkg = offerings.current!.availablePackages.first;
                    await ref.read(proServiceProvider.notifier).purchasePackage(pkg);
                    if (context.mounted) {
                       Navigator.pop(context);
                       if (onSubscribe != null) onSubscribe!();
                    }
                  } else {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No packages available")));
                     }
                  }
                 } catch (e) {
                   debugPrint("Error fetching packages: $e");
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "UPGRADE NOW",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                 await ref.read(proServiceProvider.notifier).restorePurchases();
                 if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                "Restore Purchases",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
