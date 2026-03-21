import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'pro_service.g.dart';

@Riverpod(keepAlive: true)
class ProService extends _$ProService {
  late SharedPreferences _prefs;

  @override
  bool build() {
    _initRevenueCat();
    return _checkLocalProStatus(); // Synchronous initial state
  }

  Future<void> _initRevenueCat() async {
    _prefs = await SharedPreferences.getInstance();

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration("goog_placeholder_api_key_for_sift");
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration("appl_placeholder_api_key_for_sift");
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
      _checkSubscriptionStatus();
    }
  }

  bool _checkLocalProStatus() {
    // Stubbed to false for now, unless overridden
    return false;
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      // "pro_entitlement" is the assumed identifier in RevenueCat dashboard
      final isPro = customerInfo.entitlements.all["pro_entitlement"]?.isActive ?? false;
      state = isPro;

      // Cache it locally just in case
      await _prefs.setBool('is_pro', isPro);
    } catch (e) {
      debugPrint("Failed to fetch customer info: $e");
      state = _prefs.getBool('is_pro') ?? false; // Fallback to local cache
    }
  }

  Future<void> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      state = customerInfo.entitlements.all["pro_entitlement"]?.isActive ?? false;
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
