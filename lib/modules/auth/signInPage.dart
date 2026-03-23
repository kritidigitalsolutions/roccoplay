import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/auth/otpPage.dart';
import '../../app/theme/app_colors.dart';
import '../homePages/mainHomepage.dart';
import 'auth_controller.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController authController = Get.put(AuthController());

  bool isAgeConfirmed = false;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool showCodeField = false;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.white,
            ),
            onPressed: () {
              Get.offAll(() => const MainHomePage());
            },
          ),
        ),
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                      ),

                      /// LOGO
                      Image.asset(
                        "assets/images/roccoplay_logo.png",
                        height: 100,
                      ),

                      const SizedBox(height: 25),

                      /// WELCOME
                      const Text(
                        "Welcome",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// PHONE ROW
                      Row(
                        children: [
                          const SizedBox(width: 10),

                          /// PHONE FIELD
                          Expanded(
                            child: TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Phone or Email is required";
                                }

                                bool isEmail = RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$')
                                    .hasMatch(value);

                                bool isPhone =
                                    RegExp(r'^[6-9][0-9]{9}$').hasMatch(value);

                                if (!isEmail && !isPhone) {
                                  return "Enter valid phone number or email";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: "Phone Number or Email",
                                hintStyle:
                                    const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: Colors.grey[900],
                                errorStyle:
                                    const TextStyle(color: Colors.redAccent),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// SIGNUP CODE
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Have a sign up code? ",
                            style: TextStyle(color: Colors.white70),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showCodeField = !showCodeField;
                              });
                            },
                            child: const Text(
                              "Enter Code",
                              style: TextStyle(
                                color: Colors.pinkAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      if (showCodeField)
                        TextField(
                          controller: codeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Enter Sign Up Code",
                            hintStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: Colors.grey[900],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      /// AGE CONFIRMATION CHECKBOX
                      Row(
                        children: [
                          Checkbox(
                            value: isAgeConfirmed,
                            activeColor: Colors.pinkAccent,
                            onChanged: (value) {
                              if (!isAgeConfirmed) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.black,
                                    title: const Text(
                                      "Age Restriction",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      "You must be 18 years or older to use RoccoPlay.",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            isAgeConfirmed = true;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Confirm"),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                setState(() {
                                  isAgeConfirmed = false;
                                });
                              }
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I confirm that I am 18+ years old",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// GET OTP BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: Obx(() => ElevatedButton(
                              onPressed: (isAgeConfirmed && !authController.isLoading.value)
                                  ? () async {
                                      if (_formKey.currentState!.validate()) {
                                        FocusScope.of(context).unfocus();
                                        String valueToSend =
                                            phoneController.text;

                                        bool success = await authController
                                            .sendOtp(valueToSend);
                                        if (success) {
                                          Get.to(() => OtpPage(
                                              phoneNumber: valueToSend));
                                        }
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.buttonColor,
                                disabledBackgroundColor: Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: authController.isLoading.value
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Get OTP",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            )),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
