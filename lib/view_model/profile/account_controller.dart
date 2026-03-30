import 'package:get/get.dart';

class AccountController extends GetxController {
  var isEmailVerified = false.obs;
  var isPhoneVerified = true.obs;

  void verifyEmail() {
    isEmailVerified.value = true;
    Get.snackbar("Success", "Email verified successfully!");
  }
}
