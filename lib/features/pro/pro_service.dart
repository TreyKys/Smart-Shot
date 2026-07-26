import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sift/core/config/app_config.dart';

part 'pro_service.g.dart';

@Riverpod(keepAlive: true)
class ProService extends _$ProService {
  late SharedPreferences _prefs;

  @override
  bool build() {
    _initRevenueCat();
    return _checkLocalProStatus();
  }

  Future<void> _initRevenueCat() async {
    _prefs = await SharedPreferences.getInstance();

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid && AppConfig.revenueCatAndroidApiKey.isNotEmpty) {
      configuration = PurchasesConfiguration(AppConfig.revenueCatAndroidApiKey);
    } else if (Platform.isIOS && AppConfig.revenueCatIosApiKey.isNotEmpty) {
      configuration = PurchasesConfiguration(AppConfig.revenueCatIosApiKey);
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      _checkSubscriptionStatus();
    } else {
      debugPrint(
          'RevenueCat API key not supplied via --dart-define; purchases disabled.');
    }
  }

  bool _checkLocalProStatus() {
    // Fail closed: default to non-Pro until RevenueCat/cached entitlement
    // confirms otherwise via _checkSubscriptionStatus() below.
    return false;
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.all["pro_entitlement"]?.isActive ?? false;
      state = isPro;
      await _prefs.setBool('is_pro', isPro);
    } catch (e) {
      debugPrint("Failed to fetch customer info: $e");
      state = _prefs.getBool('is_pro') ?? false;
    }
  }

  Future<void> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      state = purchaseResult.customerInfo.entitlements.all["pro_entitlement"]?.isActive ?? false;
      await _prefs.setBool('is_pro', state);
    } catch (e) {
      debugPrint("Purchase error: $e");
    }
  }

  Future<void> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      state = customerInfo.entitlements.all["pro_entitlement"]?.isActive ?? false;
      await _prefs.setBool('is_pro', state);
    } catch (e) {
      debugPrint("Restore error: $e");
    }
  }
}
