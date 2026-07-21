class AppConstants {
  // static const String baseUrl = 'http://192.168.1.17:8000/api';
  static const String baseUrl = 'https://api.roccoplay.in/api';

  // Auth Endpoints
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  /// user proflie
  static const String getProfile = '$baseUrl/user/profile';
  static const String createProfile = '$baseUrl/user/profile-info';

  /// fcm
  static const String updateFcmToken = '$baseUrl/user/fcm-token';

  /// notifications
  static const String getNotifications = '$baseUrl/notifications';
  static String markNotificationRead(String id) => '$baseUrl/notifications/$id/read';
  static const String markAllNotificationsRead = '$baseUrl/notifications/read-all';
  static String deleteNotification(String id) => '$baseUrl/notifications/$id';

  /// legal
  static const String privacyPolicyUrl = '$baseUrl/legal/privacy-policy';
  static const String termsAndConditionsUrl = '$baseUrl/legal/terms-conditions';
  static const String refundPolicy = '$baseUrl/legal/refund-policy';
  static const String helpSupport = '$baseUrl/help';
  static const String supportNumber = '$baseUrl/help/support/number';
  static const String supportEmail = '$baseUrl/help/support/email';

  /// content
  static const String getAllContent = '$baseUrl/content';
  static const String getCategories = '$baseUrl/categories';

  /// payment
  static const String createOrder = '$baseUrl/payment/create-order';
  static const String verifyPayment = '$baseUrl/payment/verify';

  /// watchlist
  static const String addWatchlist = '$baseUrl/watchlist';
  static const String getWatchlist = '$baseUrl/watchlist';
  static const String removeWatchlist = '$baseUrl/watchlist';

  /// interaction
  static const String toggleInteraction = '$baseUrl/interaction/toggle';
  static const String interactionStats = '$baseUrl/interaction/stats';

  /// review
  static const String rateApp = '$baseUrl/rating/rate';
  /// plans
  static const String planList = '$baseUrl/plan';
  static const String buyPlan = '$baseUrl/subscription/subscribe';
  static const String planCheck = '$baseUrl/subscription/status';
  static const String cancelPlan = '$baseUrl/subscription/status';
  /// company
  static const String companyInfo = '$baseUrl/companyInfo';

  /// voucher
  static const String redeemVoucher = '$baseUrl/voucher/redeem';
}
