class VerifyOtpResponse {
  final bool success;
  final bool isNewUser;
  final String message;
  final String phone;

  VerifyOtpResponse({
    required this.success,
    required this.isNewUser,
    required this.message,
    required this.phone,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] ?? false,
      isNewUser: json['isNewUser'] ?? false,
      message: json['message'] ?? '',
      phone: json['phone'] ?? '',
    );
  }
}
