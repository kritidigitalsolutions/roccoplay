import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/homePages/mainHomepage.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/app_session.dart';
import '../profile/create_profile_page.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/auth_controller/otp_controller.dart';
import '../../app/routes/app_routes.dart';

class OtpPage extends StatelessWidget {
  final String phoneNumber;

  const OtpPage({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final OtpController otpController = Get.put(OtpController());

    void verifyOtp() async {
      String otp = otpController.controllers.map((e) => e.text).join();

      if (otp.length < 6) {
        Get.snackbar('Error', 'Please enter 6-digit OTP');
        return;
      }

      final response = await authController.verifyOtp(phoneNumber, otp);

      if (response != null && response.success) {
        // ✅ CRITICAL FIX: Update global login state
        authController.setLoginStatus(true);
        
        // Check if user is new or profile is incomplete
        bool isNew = response.isNewUser;
        bool isProfileIncomplete = false;
        
        if (response.user != null && response.user!['profileComplete'] == false) {
          isProfileIncomplete = true;
        }

        if (isNew || isProfileIncomplete) {
          print("Navigating to: CreateProfilePage");
          Get.offAll(() => CreateProfilePage(phone: phoneNumber));
        } else {
          print("Navigating to: MainHomePage");
          Get.offAllNamed(AppRoutes.home);
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text(
                "Verify OTP",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter the OTP sent to $phoneNumber",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),

              /// OTP Boxes (6 digits)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 45,
                    height: 55,
                    child: TextField(
                      controller: otpController.controllers[index],
                      focusNode: otpController.focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.grey,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(context)
                              .requestFocus(otpController.focusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(context)
                              .requestFocus(otpController.focusNodes[index - 1]);
                        }
                        if (value.length == 1 && index == 5) {
                           FocusScope.of(context).unfocus();
                           verifyOtp();
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// Verify Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: authController.isLoading.value ? null : verifyOtp,
                  child: authController.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Verify",
                          style: TextStyle(fontSize: 16, color: AppColors.white),
                        ),
                )),
              ),

              const SizedBox(height: 20),

              /// Resend OTP
              Center(
                child: Obx(() => TextButton(
                  onPressed: (otpController.isResendButtonDisabled.value || authController.isLoading.value)
                      ? null
                      : () async {
                          bool success = await authController.sendOtp(phoneNumber);
                          if (success) {
                            otpController.startTimer();
                          }
                        },
                  child: Text(
                    otpController.isResendButtonDisabled.value
                        ? 'Resend OTP in ${otpController.countdown.value}\s'
                        : 'Resend OTP',
                    style: TextStyle(
                        color: otpController.isResendButtonDisabled.value
                            ? Colors.grey
                            : AppColors.buttonColor),
                  ),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
