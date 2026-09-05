import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sift/core/config/app_config.dart';
import 'package:sift/features/pro/pro_service.dart';

part 'economy_service.g.dart';

const int kDailyFreeExtractions = 30;
const int kAdRewardExtractions = 10;
const int kAdsRequiredForReward = 2;
const int kFreeBatchLimit = 3;
const int kProBatchLimit = 50;
const int kBackgroundDeepScanChunkSize = 50;
const double kCostPerExtraction = 0.0005;

/// How many of the [kAdsRequiredForReward] ads the user has watched in the
/// current refill attempt — plain, non-generated provider (this session's
/// convention for new providers) so quota_bar.dart can show live progress
/// instead of the block completing invisibly after a silent second tap.
/// EconomyService writes to this; nothing else should.
final adsWatchedInBlockProvider = StateProvider<int>((ref) => 0);

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

  /// True when the user's tier doesn't draw down the daily pool.
  Future<bool> _isUnlimited() async {
    if (ref.read(proServiceProvider)) return true;
    _prefs = await SharedPreferences.getInstance();
    return (_prefs.getString('byok_key') ?? '').isNotEmpty;
  }

  /// Atomically claims up to [wanted] units, returning how many were granted.
  ///
  /// Callers that run work concurrently must reserve before starting, not
  /// check-then-consume per item: `hasEnoughEnergy()` followed by
  /// `consumeEnergy(1)` has an await between the read and the write, so N
  /// parallel workers can all observe the same balance and overspend it.
  /// Anything unused must be handed back via [releaseEnergy].
  ///
  /// Returns [wanted] unchanged for Pro and BYOK users.
  Future<int> reserveEnergy(int wanted) async {
    if (wanted <= 0) return 0;
    if (await _isUnlimited()) return wanted;

    await _checkMidnightReset();

    // No await between the read and the write — shared_preferences updates its
    // in-memory cache synchronously, so a concurrent reserve sees the debit.
    final current = _getCurrentEnergy();
    final granted = current < wanted ? current : wanted;
    if (granted <= 0) return 0;
    final remaining = current - granted;
    final write = _prefs.setInt('ai_energy', remaining);
    state = AsyncValue.data(remaining);
    await write;
    debugPrint('Reserved $granted of $wanted energy ($remaining left).');
    return granted;
  }

  /// Returns unspent reservations to the pool.
  Future<void> releaseEnergy(int amount) async {
    if (amount <= 0) return;
    if (await _isUnlimited()) return;
    _prefs = await SharedPreferences.getInstance();
    final restored = _getCurrentEnergy() + amount;
    final write = _prefs.setInt('ai_energy', restored);
    state = AsyncValue.data(restored);
    await write;
    debugPrint('Released $amount unused energy ($restored left).');
  }

  /// Records spend for units actually consumed. Balance is already debited by
  /// [reserveEnergy], so this only updates the cost counters.
  Future<void> recordUsage(int units) => _trackCost(units);

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
    final String adUnitId = AppConfig.rewardedAdUnitId;
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
        if (_adsWatchedInCurrentBlock < kAdsRequiredForReward) loadRewardedAd();
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
      debugPrint('Ad watched: $_adsWatchedInCurrentBlock/$kAdsRequiredForReward');
      ref.read(adsWatchedInBlockProvider.notifier).state = _adsWatchedInCurrentBlock;
      if (_adsWatchedInCurrentBlock >= kAdsRequiredForReward) {
        await _applyAdRefill();
        _adsWatchedInCurrentBlock = 0;
        ref.read(adsWatchedInBlockProvider.notifier).state = 0;
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
