import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP (User Messaging Platform) consent flow — required by Google's
/// EU User Consent Policy before requesting personalized ads for users in
/// the EEA, UK, or Switzerland. No-ops (grants nothing, blocks nothing)
/// outside those regions since the UMP SDK itself decides applicability.
class ConsentService {
  ConsentService._();
  static final instance = ConsentService._();

  /// Runs the consent flow if needed, then always initializes the Mobile
  /// Ads SDK (ad requests remain non-personalized until consent is given).
  Future<void> requestConsentAndInitAds() async {
    final params = ConsentRequestParameters();
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadAndShowForm();
          }
        } catch (e) {
          debugPrint('UMP consent form error: $e');
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (error) {
        debugPrint('UMP consent info update failed: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    await completer.future;
    await MobileAds.instance.initialize();
  }

  Future<void> _loadAndShowForm() async {
    final formCompleter = Completer<void>();
    ConsentForm.loadConsentForm(
      (consentForm) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((formError) {
            if (formError != null) {
              debugPrint('UMP consent form show error: ${formError.message}');
            }
            if (!formCompleter.isCompleted) formCompleter.complete();
          });
        } else {
          if (!formCompleter.isCompleted) formCompleter.complete();
        }
      },
      (formError) {
        debugPrint('UMP consent form load error: ${formError.message}');
        if (!formCompleter.isCompleted) formCompleter.complete();
      },
    );
    await formCompleter.future;
  }
}
