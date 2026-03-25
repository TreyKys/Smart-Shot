import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sift/features/pro/pro_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'economy_service.g.dart';

@Riverpod(keepAlive: true)
class EconomyService extends _$EconomyService {
  late SharedPreferences _prefs;
  RewardedAd? _rewardedAd;
  int _adsWatchedInCurrentBlock = 0;

  @override
  FutureOr<int> build() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkMidnightReset();
    return _getCurrentEnergy();
  }

  Future<void> _checkMidnightReset() async {
    // Ensure _prefs is loaded if called externally before build finishes
    // In practice build() finishes first, but this is safe
    _prefs = await SharedPreferences.getInstance();
    final lastResetStr = _prefs.getString('last_reset_date');
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    if (lastResetStr != todayStr) {
      await _prefs.setString('last_reset_date', todayStr);
      await _prefs.setInt('ai_energy', 10);
      await _prefs.setInt('refills_today', 0);
      debugPrint("Midnight reset applied. Energy back to 10.");
    }
  }

  int _getCurrentEnergy() {
    return _prefs.getInt('ai_energy') ?? 10;
  }

  Future<bool> hasEnoughEnergy() async {
    // Pro users have infinite energy
    if (ref.read(proServiceProvider)) return true;

    // BYOK users have infinite energy
    _prefs = await SharedPreferences.getInstance();
    final byokKey = _prefs.getString('byok_key') ?? '';
    if (byokKey.isNotEmpty) return true;

    await _checkMidnightReset();
    return _getCurrentEnergy() > 0;
  }

  Future<void> consumeEnergy(int amount) async {
    if (ref.read(proServiceProvider)) return;
    _prefs = await SharedPreferences.getInstance();
    final byokKey = _prefs.getString('byok_key') ?? '';
    if (byokKey.isNotEmpty) return;

    final current = _getCurrentEnergy();
    final newEnergy = (current - amount).clamp(0, 9999);
    await _prefs.setInt('ai_energy', newEnergy);
    state = AsyncValue.data(newEnergy);
  }

  Future<void> setByokKey(String key) async {
    await _prefs.setString('byok_key', key.trim());
    state = AsyncValue.data(_getCurrentEnergy()); // trigger rebuild
  }

  String? getByokKey() {
    return _prefs.getString('byok_key');
  }

  // --- Ad Logic ---

  void loadRewardedAd() {
    // Official test unit ID for Android Rewarded Ad
    final String adUnitId = kReleaseMode
        ? 'ca-app-pub-3940256099942544/5224354917' // USE PRODUCTION ID HERE IN REAL RELEASE, test ID for safety
        : 'ca-app-pub-3940256099942544/5224354917';

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded.');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> showRewardedAd({required VoidCallback onBlockCompleted}) async {
    if (_rewardedAd == null) {
      debugPrint('Warning: attempt to show rewarded ad before loaded.');
      loadRewardedAd(); // Try again for next time
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Ad showed fullscreen content.'),
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('Ad dismissed fullscreen content.');
        ad.dispose();
        _rewardedAd = null;

        // If they still need to watch another ad to finish the block
        if (_adsWatchedInCurrentBlock < 2) {
             loadRewardedAd();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show fullscreen content: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
      _adsWatchedInCurrentBlock++;
      debugPrint('User earned reward. Ads watched in block: ${_adsWatchedInCurrentBlock}/2');

      if (_adsWatchedInCurrentBlock >= 2) {
        // Complete the Double Block
        await _applyRefill();
        _adsWatchedInCurrentBlock = 0; // reset
        onBlockCompleted();
      }
    });
  }

  Future<void> _applyRefill() async {
    await _checkMidnightReset();
    int refillsToday = _prefs.getInt('refills_today') ?? 0;

    int rewardAmount = 5; // Strictly 5 scans per block

    final currentEnergy = _getCurrentEnergy();
    await _prefs.setInt('ai_energy', currentEnergy + rewardAmount);
    await _prefs.setInt('refills_today', refillsToday + 1);

    state = AsyncValue.data(_getCurrentEnergy());
    debugPrint("Refill applied! +$rewardAmount Energy. Total: ${currentEnergy + rewardAmount}");
  }
}
