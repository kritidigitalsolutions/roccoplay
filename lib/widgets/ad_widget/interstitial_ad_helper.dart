import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';

/// ✅ Interstitial Ad Helper
/// Use: page open pe, app close pe, video pause/close pe
class InterstitialAdHelper {
  static InterstitialAd? _interstitialAd;
  static bool _isLoaded = false;
  static bool isShowing = false;

  /// 🔄 Load Interstitial Ad
  static void loadAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoaded = true;

          _interstitialAd!.setImmersiveMode(true); // 👈 sahi naam
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
        },
      ),
    );
  }

  /// 📢 Show Interstitial Ad
  static void showAd({VoidCallback? onAdClosed}) {
    if (kIsWeb) {
      if (onAdClosed != null) onAdClosed();
      return;
    }
    if (_isLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          isShowing = true;
        },
        onAdDismissedFullScreenContent: (ad) {
          isShowing = false;
          ad.dispose();
          _interstitialAd = null;
          _isLoaded = false;
          loadAd(); // auto reload for next time
          if (onAdClosed != null) onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          isShowing = false;
          ad.dispose();
          _interstitialAd = null;
          _isLoaded = false;
          loadAd();
          if (onAdClosed != null) onAdClosed();
        },
      );
      _interstitialAd!.show();
    } else {
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
