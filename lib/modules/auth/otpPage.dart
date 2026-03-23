import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/homePages/mainHomepage.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/app_session.dart';
import 'auth_controller.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;

  const OtpPage({super.key, required this.phoneNumber});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final AuthController authController = Get.find<AuthController>();
  final List<TextEditingController> controllers =
      List.generate(6, (index) => TextEditingController());

  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  bool _isResendButtonDisabled = false;
  int _countdown = 30;
  Timer? _timer;

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isResendButtonDisabled = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          _isResendButtonDisabled = false;
          _countdown = 30;
        }
      });
    });
  }

  void verifyOtp() async {
    String otp = controllers.map((e) => e.text).join();

    if (otp.length < 6) {
      Get.snackbar('Error', 'Please enter 6-digit OTP');
      return;
    }

    final response = await authController.verifyOtp(widget.phoneNumber, otp);

    if (response != null && response.success) {
      // Print response to console as requested
      print("-----------------------------------------");
      print("VERIFY OTP RESPONSE: ${response.message}");
      print("IS NEW USER: ${response.isNewUser}");
      print("-----------------------------------------");

      await AppSession.setLogin(true);
      // You can also save the phone or token if available in response
      
      if (response.isNewUser) {
        // Navigate to complete profile if needed, or home for now
        Get.offAll(() => const MainHomePage());
      } else {
        Get.offAll(() => const MainHomePage());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                "Enter the OTP sent to ${widget.phoneNumber}",
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
                      controller: controllers[index],
                      focusNode: focusNodes[index],
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
                              .requestFocus(focusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(context)
                              .requestFocus(focusNodes[index - 1]);
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
                  onPressed: (_isResendButtonDisabled || authController.isLoading.value)
                      ? null
                      : () async {
                          bool success = await authController.sendOtp(widget.phoneNumber);
                          if (success) {
                            _startTimer();
                          }
                        },
                  child: Text(
                    _isResendButtonDisabled
                        ? 'Resend OTP in $_countdown\s'
                        : 'Resend OTP',
                    style: TextStyle(
                        color: _isResendButtonDisabled
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
