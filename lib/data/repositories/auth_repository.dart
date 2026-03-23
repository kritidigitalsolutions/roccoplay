import '../providers/api_provider.dart';
import '../models/response_model/send_otp_response.dart';
import '../models/response_model/verify_otp_response.dart';

class AuthRepository {
  final ApiProvider apiProvider;

  AuthRepository({required this.apiProvider});

  Future<(bool, String)> sendOtp(String identifier) async {
    final response = await apiProvider.sendOtp(identifier);
    if (response.isOk) {
      final data = SendOtpResponse.fromJson(response.body);
      return (true, data.message);
    } else {
      String errorMsg = response.body != null && response.body['message'] != null 
          ? response.body['message'] 
          : (response.statusText ?? 'Something went wrong');
      return (false, errorMsg);
    }
  }

  Future<(bool, VerifyOtpResponse?)> verifyOtp(String phoneNumber, String otp) async {
    final response = await apiProvider.verifyOtp(phoneNumber, otp);
    if (response.isOk) {
      final data = VerifyOtpResponse.fromJson(response.body);
      return (true, data);
    } else {
      return (false, null);
    }
  }
}
