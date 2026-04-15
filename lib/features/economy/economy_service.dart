import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sift/features/pro/pro_service.dart';

part 'economy_service.g.dart';

const int kDailyFreeExtractions = 5;
const int kAdRewardExtractions = 3;
const int kFreeBatchLimit = 3;
const int kProBatchLimit = 50;
const int kBackgroundDeepScanChunkSize = 50;
const double kCostPerExtraction = 0.0005;

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
    _prefs = await SharedPreferences.getInstance();
    final lastResetStr = _prefs.getString('last_reset_date');
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    if (lastResetStr != todayStr) {
      await _prefs.setString('last_reset_date', todayStr);
      await _prefs.setInt('ai_energy', kDailyFreeExtractions);
      await _prefs.setInt('refills_today', 0);
      debugPrint('Midnight reset: energy restored to $kDailyFreeExtractions.');
    }
  }

  int _getCurrentEnergy() => _prefs.getInt('ai_energy') ?? kDailyFreeExtractions;

  Future<bool> hasEnoughEnergy() async {
    if (ref.read(proServiceProvider)) return true;
    _prefs = await SharedPreferences.getInstance();
    final byokKey = _prefs.getString('byok_key') ?? '';
    if (byokKey.isNotEmpty) return true;
    await _checkMidnightReset();
    return _getCurrentEnergy() > 0;
  }

  Future<void> consumeEnergy(int amount) async {
    if (ref.read(proServiceProvider)) {
      // Pro: track cost but don't gate
      await _trackCost(amount);
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    final byokKey = _prefs.getString('byok_key') ?? '';
    if (byokKey.isNotEmpty) {
      await _trackCost(amount);
      return;
    }
    final current = _getCurrentEnergy();
    final newEnergy = (current - amount).clamp(0, 9999);
    await _prefs.setInt('ai_energy', newEnergy);
    await _trackCost(amount);
    state = AsyncValue.data(newEnergy);
  }

  Future<void> _trackCost(int units) async {
    _prefs = await SharedPreferences.getInstance();
    final totalCalls = (_prefs.getInt('total_extractions') ?? 0) + units;
    final totalCost = (_prefs.getDouble('total_cost_usd') ?? 0.0) + (units * kCostPerExtraction);
    await _prefs.setInt('total_extractions', totalCalls);
    await _prefs.setDouble('total_cost_usd', totalCost);
  }

  double getTotalCostUsd() => _prefs.getDouble('total_cost_usd') ?? 0.0;
  int getTotalExtractions() => _prefs.getInt('total_extractions') ?? 0;

  Future<void> setByokKey(String key) async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs.setString('byok_key', key.trim());
    state = AsyncValue.data(_getCurrentEnergy());
  }

  String? getByokKey() => _prefs.getString('byok_key');

  String? getEffectiveApiKey(String envKey) {
    final byok = getByokKey();
    if (byok != null && byok.isNotEmpty) return byok;
    return envKey.isNotEmpty ? envKey : null;
  }

  // ── AdMob ────────────────────────────────────────────────────────────────

  void loadRewardedAd() {
    const String adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // test ID
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('Rewarded ad loaded.');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<void> showRewardedAd({required VoidCallback onBlockCompleted}) async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not ready — reloading.');
      loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => debugPrint('Ad showing.'),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        if (_adsWatchedInCurrentBlock < 2) loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
      _adsWatchedInCurrentBlock++;
      debugPrint('Ad watched: ${_adsWatchedInCurrentBlock}/2');
      if (_adsWatchedInCurrentBlock >= 2) {
        await _applyAdRefill();
        _adsWatchedInCurrentBlock = 0;
        onBlockCompleted();
      }
    });
  }

  Future<void> _applyAdRefill() async {
    await _checkMidnightReset();
    final current = _getCurrentEnergy();
    final newEnergy = current + kAdRewardExtractions;
    await _prefs.setInt('ai_energy', newEnergy);
    await _prefs.setInt('refills_today', (_prefs.getInt('refills_today') ?? 0) + 1);
    state = AsyncValue.data(newEnergy);
    debugPrint('Ad refill: +$kAdRewardExtractions energy. Total: $newEnergy');
  }

  int getBatchLimit(bool isPro) => isPro ? kProBatchLimit : kFreeBatchLimit;
}
