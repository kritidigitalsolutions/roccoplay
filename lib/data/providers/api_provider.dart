import 'package:get/get.dart';
import '../../utils/constants.dart';

class ApiProvider extends GetConnect {
  @override
  void onInit() {
    httpClient.baseUrl = AppConstants.baseUrl;
    httpClient.timeout = const Duration(seconds: 30);
    super.onInit();
  }

  Future<Response> sendOtp(String phoneNumber) {
    return post(AppConstants.sendOtp, {
      'phone': phoneNumber,
    });
  }

  Future<Response> verifyOtp(String phoneNumber, String otp) {
    return post(AppConstants.verifyOtp, {
      'phone': phoneNumber,
      'otp': otp,
    });
  }
}
