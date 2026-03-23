class AppConstants {
  static const String baseUrl = 'http://192.168.1.8:5000/api';
  
  // Auth Endpoints
  static const String sendOtp = '$baseUrl/user/auth/send-otp';
  static const String verifyOtp = '$baseUrl/user/auth/verify-otp';
}
