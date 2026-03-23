import 'package:get/get.dart';
import 'dart:developer' as developer;
import '../../data/repositories/auth_repository.dart';
import '../../data/providers/api_provider.dart';
import '../../data/models/response_model/verify_otp_response.dart';

class AuthController extends GetxController {
  final AuthRepository repository = AuthRepository(apiProvider: ApiProvider());

  var isLoading = false.obs;

  Future<bool> sendOtp(String identifier) async {
    isLoading.value = true;
    try {
      final (success, message) = await repository.sendOtp(identifier);

      print("=========================================");
      print("SEND OTP REQUEST FOR: $identifier");
      print("API RESPONSE: $message");
      print("=========================================");

      if (success) {
        Get.snackbar('Success', message);
        return true;
      } else {
        Get.snackbar('Error', message);
        return false;
      }
    } catch (e) {
      print("ERROR CALLING SEND OTP: $e");
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<VerifyOtpResponse?> verifyOtp(String phoneNumber, String otp) async {
    isLoading.value = true;
    try {
      final (success, response) = await repository.verifyOtp(phoneNumber, otp);
      
      print("=========================================");
      print("VERIFY OTP REQUEST FOR: $phoneNumber");
      print("API RESPONSE: ${response?.message}");
      print("=========================================");

      if (success && response != null) {
        Get.snackbar('Success', response.message);
        return response;
      } else {
        Get.snackbar('Error', 'Invalid OTP');
        return null;
      }
    } catch (e) {
      print("ERROR CALLING VERIFY OTP: $e");
      Get.snackbar('Error', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }
}
