import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';

/// ✅ App Open Ad Helper
/// Use: app launch hone pe / app foreground me aane pe
class AppOpenAdHelper {
  static AppOpenAd? _appOpenAd;
  static bool _isLoaded = false;
  static bool _isShowing = false;
  static DateTime? _loadTime;

  /// 🔥 Jab true ho, App Open Ad kabhi show nahi hoga (jaise video player screen par)
  static bool suppressed = false;

  /// ⏱ Ad 4 ghante se zyada purana ho to reload karo
  static bool get _isAdExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!).inHours >= 4;
  }

  /// 🔄 Load App Open Ad
  static void loadAd() {
    if (_isLoaded && !_isAdExpired) return;

    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("✅ App Open Ad Loaded");
          _appOpenAd = ad;
          _isLoaded = true;
          _loadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint("❌ App Open Ad Failed: ${error.message}");
          _isLoaded = false;
        },
      ),
    );
  }

  /// 📢 Show App Open Ad
  static void showAdIfAvailable() {
    // 🔥 Jab kisi screen ne suppress kar rakha ho (jaise video player), App Open Ad skip
    if (suppressed) {
      debugPrint("⏭️ App Open Ad suppressed (current screen doesn't allow it)");
      return;
    }

    if (!_isLoaded || _appOpenAd == null || _isShowing || _isAdExpired) {
      debugPrint("⚠️ App Open Ad not available, loading...");
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowing = true;
        debugPrint("App Open Ad showing");
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        _isLoaded = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // next ke liye reload
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        _isLoaded = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  static bool get isLoaded => _isLoaded;

  static void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isLoaded = false;
    _isShowing = false;
  }
}
