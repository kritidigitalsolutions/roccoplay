import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/network/api_network_service.dart';
import '../../data/models/response_model/auth_response_model/verify_otp_response.dart';
import '../../utils/app_session.dart';

class AuthController extends GetxController {
  final AuthRepository repository = AuthRepository(NetworkApiService());

  var isLoading = false.obs;
  var isLoggedIn = false.obs;
  final storage = GetStorage();
  var userData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    isLoggedIn.value = AppSession.getLogin();
    var saved = storage.read('user_data');
    if (saved != null) {
      userData.value = Map<String, dynamic>.from(saved);
    }

    String? token = AppSession.getToken();
    if (token != null) {
      (repository.apiProvider as NetworkApiService).setToken(token);
    }
  }

  void setLoginStatus(bool status) async {
    isLoggedIn.value = status;
    await AppSession.setLogin(status);
  }
/// send otp
  Future<bool> sendOtp(String identifier) async {
    isLoading.value = true;
    try {
      final response = await repository.sendOtp(identifier);
      
      print("=========================================");
      print("SEND OTP REQUEST FOR: $identifier");
      print("API RESPONSE MESSAGE: ${response.message}");
      print("RECEIVED OTP: ${response.otp}");
      print("SESSION ID: ${response.sessionId}");
      print("=========================================");

      Get.snackbar('Success', response.message);
      return true;
    } catch (e) {
      print("ERROR IN sendOtp: $e");
      Get.snackbar('Error', e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }
/// verify otp
  Future<VerifyOtpResponse?> verifyOtp(String phoneNumber, String otp) async {
    isLoading.value = true;
    try {
      final response = await repository.verifyOtp(phoneNumber, otp);
      if (response != null && response.success) {
        print("================ VERIFY OTP RESPONSE ================");
        print("SUCCESS: ${response.success}");
        print("IS NEW USER: ${response.isNewUser}");
        print("TOKEN: ${response.token}");
        print("USER DATA: ${response.user}");
        print("====================================================");

        if (response.token != null) {
          await AppSession.setToken(response.token!);
          (repository.apiProvider as NetworkApiService).setToken(response.token!);
        }
        
        if (response.user != null) {
          userData.value = response.user;
          await storage.write('user_data', response.user);
        }

        return response;
      } else {
        Get.snackbar('Error', 'Verification failed');
        return null;
      }
    } catch (e) {
      print("ERROR IN verifyOtp: $e");
      Get.snackbar('Error', e.toString());
      return null;
    } finally {
      isLoading.value = false;
    }
  }
/// create or save profile
  Future<bool> updateAndSaveProfile({
    required String name,
    required String email,
    required String phone,
    required String imagePath,
  }) async {
    try {
      isLoading.value = true;
      print("🚀 STARTING PROFILE UPDATE...");

      final response = await repository.createProfile(
        phone: phone,
        name: name,
        email: email,
      );

      print("📡 API RESPONSE: $response");

      if (response != null) {
        String? token = response['token'];
        if (token != null) {
          await AppSession.setToken(token);
          (repository.apiProvider as NetworkApiService).setToken(token);
        }

        userData.value = response['user'] ?? {
          "name": name,
          "email": email,
          "phone": phone,
        };
        await storage.write('user_data', userData.value);
        setLoginStatus(true);

        Get.snackbar("Success", "Profile updated successfully!");
        return true;
      }
      return false;
    } catch (e) {
      if (e.toString().contains("Profile already completed")) {
        setLoginStatus(true);
        return true;
      }
      print("❌ EXCEPTION in updateAndSaveProfile: $e");
      Get.snackbar("Error", e.toString());
      return false;
    } finally {
      isLoading.value = false;
    }
  }
/// get profile of user
  Future<void> getProfile() async {
    try {
      final response = await repository.getProfile();
      if (response != null) {
        // API response mein 'user' key hai, usey extract karein
        var fetchedUser = response['user'];

        if (fetchedUser != null) {
          userData.value = Map<String, dynamic>.from(fetchedUser);
          await storage.write('user_data', userData.value);
          print("✅ Profile Updated in AuthController: ${userData.value}");
        }
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }
  }
}
