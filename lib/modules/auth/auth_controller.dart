import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/providers/api_provider.dart';
import '../../data/models/response_model/verify_otp_response.dart';
import '../../utils/constants.dart';

class AuthController extends GetxController {
  final AuthRepository repository = AuthRepository(apiProvider: ApiProvider());

  var isLoading = false.obs;
  final storage = GetStorage();
  var userData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    var saved = storage.read('user_data');
    if (saved != null) {
      userData.value = Map<String, dynamic>.from(saved);
    }
  }

  Future<bool> sendOtp(String identifier) async {
    isLoading.value = true;
    try {
      final (success, message) = await repository.sendOtp(identifier);
      print("SEND OTP RESPONSE: $message");
      if (success) {
        Get.snackbar('Success', message);
        return true;
      } else {
        Get.snackbar('Error', message);
        return false;
      }
    } catch (e) {
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
      if (success && response != null) {
        Get.snackbar('Success', response.message);
        return response;
      } else {
        Get.snackbar('Error', 'Invalid OTP');
        return null;
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  /// Profile Create Function with Detailed Logging
  Future<bool> updateAndSaveProfile({
    required String name,
    required String email,
    required String phone,
    required String imagePath,
  }) async {
    try {
      isLoading.value = true;
      print("-----------------------------------------");
      print("🚀 STARTING PROFILE UPDATE...");
      print("Params: Name=$name, Email=$email, Phone=$phone, Image=$imagePath");

      final response = await repository.createProfile(
        phone: phone,
        name: name,
        email: email,
        // imagePath: imagePath,
      );

      print("📡 API RESPONSE STATUS: ${response.statusCode}");
      print("📡 API RESPONSE BODY: ${response.body}");
      print("-----------------------------------------");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> userProfile = {
          "name": name,
          "email": email,
          "phone": phone,
          "profileImage": response.body['imageUrl'] ?? imagePath,
        };

        userData.value = userProfile;
        await storage.write('user_data', userProfile);

        Get.snackbar("Success", "Profile updated successfully!");
        return true;
      } else {
        String error = response.body != null && response.body['message'] != null 
            ? response.body['message'] 
            : response.statusText ?? "Unknown Error";
        Get.snackbar("Error", "Failed to update profile: $error");
        return false;
      }
    } catch (e) {
      print("❌ EXCEPTION in updateAndSaveProfile: $e");
      Get.snackbar("Error", "Exception: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getProfile() async {
    try {
      final response = await repository.apiProvider.get(AppConstants.getProfile);
      if (response.statusCode == 200) {
        userData.value = response.body['data'] ?? response.body; 
        storage.write('user_data', userData.value);
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }
}
