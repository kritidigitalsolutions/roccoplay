import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';
import 'interstitial_ad_helper.dart';

/// ✅ App Open Ad Helper
/// Use: Jab user app ko sach me minimize kare aur 30s+ baad wapas aaye
class AppOpenAdHelper {
  static AppOpenAd? _appOpenAd;
  static bool _isLoaded = false;
  static bool _isShowing = false;
  static DateTime? _loadTime;

  /// 🔥 Jab true ho, App Open Ad kabhi show nahi hoga (jaise video player screen par)
  static bool suppressed = false;

  /// ⏱ User ne kab app ko minimize/background me daala
  static DateTime? _pausedTime;

  /// ⏱ Pichla App Open Ad kab show hua tha (Cooldown ke liye)
  static DateTime? _lastAdShownTime;

  /// ⏳ Cooldown: Ek App Open Ad ke baad kam se kam 15 minute tak doosra na aaye
  static const Duration _cooldownDuration = Duration(minutes: 15);

  /// ⏳ Minimum background time: Kam se kam 30 seconds app minimize rehna zaroori hai
  static const int _minBackgroundSeconds = 30;

  /// 🔢 Daily limit: Din bhar me maximum 4 App Open Ads
  static int _dailyShowCount = 0;
  static int? _lastShowDay;
  static const int _maxDailyShows = 4;

  /// ⏱ Ad 4 ghante se zyada purana ho to reload karo
  static bool get _isAdExpired {
    if (_loadTime == null) return true;
    return DateTime.now().difference(_loadTime!).inHours >= 4;
  }

  /// 🔄 Load App Open Ad
  static void loadAd() {
    if (kIsWeb) return;
    if (_isLoaded && !_isAdExpired) return;

    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isLoaded = true;
          _loadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _isLoaded = false;
        },
      ),
    );
  }

  /// 📱 Jab app background (paused) me jaye tab time note karo
  static void onAppPaused() {
    // Agar koi Interstitial Ad chal raha ho toh use app minimize na maano
    if (InterstitialAdHelper.isShowing) return;
    _pausedTime = DateTime.now();
  }

  /// 📢 Show App Open Ad with strict checks
  static void showAdIfAvailable() {
    if (kIsWeb) return;

    // 1. Agar screen ne suppress kar rakha ho (e.g. video player)
    if (suppressed) {
      _pausedTime = null;
      return;
    }

    // 2. Agar Interstitial Ad chal raha ho toh kabhi show mat karo (Ad ke baad Ad chain-reaction rokne ke liye)
    if (InterstitialAdHelper.isShowing) {
      _pausedTime = null;
      return;
    }

    // 3. Agar app kabhi minimize hi nahi hui (jaise in-app navigation, video play, back, orientation change)
    if (_pausedTime == null) {
      return;
    }

    // 4. Background duration check (kam se kam 30 seconds bahar raha ho)
    final int backgroundSeconds = DateTime.now().difference(_pausedTime!).inSeconds;
    _pausedTime = null; // Turant reset karo taaki navigation pe dobara trigger na ho sake

    if (backgroundSeconds < _minBackgroundSeconds) {
      return;
    }

    // 5. Cooldown check (minimum 15 min gap)
    final now = DateTime.now();
    if (_lastAdShownTime != null && now.difference(_lastAdShownTime!) < _cooldownDuration) {
      return;
    }

    // 6. Daily limit check (din me max 4 baar)
    if (_lastShowDay == null || _lastShowDay != now.day) {
      _dailyShowCount = 0;
      _lastShowDay = now.day;
    }
    if (_dailyShowCount >= _maxDailyShows) {
      return;
    }

    if (!_isLoaded || _appOpenAd == null || _isShowing || _isAdExpired) {
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowing = true;
        _lastAdShownTime = DateTime.now();
        _dailyShowCount++;
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
