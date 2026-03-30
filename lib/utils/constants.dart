class AppConstants {
  static const String baseUrl = 'http://192.168.1.31:5000/api';
  
  // Auth Endpoints
  static const String sendOtp = '$baseUrl/user/auth/send-otp';
  static const String verifyOtp = '$baseUrl/user/auth/verify-otp';
  /// user proflie
  static const String getProfile = '$baseUrl/user/profile';
  static const String createProfile = '$baseUrl/user/profile-info';

  /// legal
  static const String privacyPolicyUrl = '$baseUrl/user/legal/privacy-policy';
  static const String termsAndConditionsUrl = '$baseUrl/user/legal/terms-conditions';
  static const String refundPolicy = '$baseUrl/user/legal/refund-policy';
  static const String helpSupport = '$baseUrl/help';

  /// content
  static const String getAllContent = '$baseUrl/content';


  /// watchlist
  static const String addWatchlist = '$baseUrl/user/watchlist';
  static const String getWatchlist = '$baseUrl/user/watchlist';
}
