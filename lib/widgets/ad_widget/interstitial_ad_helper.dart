import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';

/// ✅ Interstitial Ad Helper
/// Use: page open pe, app close pe, video pause/close pe
class InterstitialAdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;

  /// 🔄 Load Interstitial Ad
  static void loadAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("✅ Interstitial Ad Loaded");
          _interstitialAd = ad;
          _isLoaded = true;

          _interstitialAd!.setImmersiveMode(true); // 👈 sahi naam
        },
        onAdFailedToLoad: (error) {
          debugPrint("❌ Interstitial Failed: ${error.message}");
          _isLoaded = false;
        },
      ),
    );
  }

  /// 📢 Show Interstitial Ad
  static void showAd({VoidCallback? onAdClosed}) {
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          _isLoaded = false;
          loadAd(); // auto reload for next time
          if (onAdClosed != null) onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          _isLoaded = false;
          loadAd();
          if (onAdClosed != null) onAdClosed();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint("⚠️ Interstitial not ready, loading for next time...");
      loadAd();
      if (onAdClosed != null) onAdClosed();
    }
  }

  static bool get isLoaded => _isLoaded;

  static void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoaded = false;
  }
}
