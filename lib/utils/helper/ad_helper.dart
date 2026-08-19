// class AdHelper {
//   static const String bannerAdUnitId =
//       'ca-app-pub-3940256099942544/6300978111'; // TEST
//   static const String interstitialAdUnitId =
//       'ca-app-pub-3940256099942544/1033173712'; // TEST
//   static const String nativeAdUnitId =
//       'ca-app-pub-3940256099942544/2247696110'; // TEST
//   static const String appOpenAdUnitId =
//       'ca-app-pub-3940256099942544/9257395921'; // TEST
// }

class AdHelper {
  /// 🔥 PRODUCTION IDs (Client ke real IDs)
  static String get bannerAdUnitId {
    return 'ca-app-pub-4529616898084985/5854931639';
  }

  static String get interstitialAdUnitId {
    return 'ca-app-pub-4529616898084985/6269864604';
  }

  static String get nativeAdUnitId {
    return 'ca-app-pub-4529616898084985/8249160684';
  }

  static String get appOpenAdUnitId {
    return 'ca-app-pub-4529616898084985/1915686628';
  }

  /// ⚠️ Rewarded Ad - use nahi karna (client instruction)
  // static String get rewardedAdUnitId {
  //   return 'ca-app-pub-4529616898084985/7780769702';
  // }
}
