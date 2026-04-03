import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/profile/create_profile_controller.dart';

class CreateProfilePage extends StatelessWidget {
  final String phone;

  const CreateProfilePage({super.key, required this.phone});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final authController = Get.find<AuthController>();
    final createProfileController = Get.put(CreateProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              /// Profile Image
              GestureDetector(
                onTap: createProfileController.pickImage,
                child: Obx(() => CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: createProfileController.selectedImage.value != null
                      ? FileImage(createProfileController.selectedImage.value!)
                      : null,
                  child: createProfileController.selectedImage.value == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                )),
              ),

              TextButton(
                onPressed: createProfileController.pickImage,
                child: const Text(
                  "Change Avatar",
                  style: TextStyle(color: AppColors.buttonColor),
                ),
              ),

              const SizedBox(height: 20),

              /// Name Field
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: "Name",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              /// Email Field
              TextField(
                controller: emailController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: "Email",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: authController.isLoading.value
                      ? null
                      : () async {
                          if (nameController.text.isEmpty ||
                              emailController.text.isEmpty ||
                              createProfileController.selectedImage.value == null) {
                            Get.snackbar("Error", "All fields are required");
                            return;
                          }

                          bool success = await authController.updateAndSaveProfile(
                            name: nameController.text,
                            email: emailController.text,
                            phone: phone,
                            imagePath: createProfileController.selectedImage.value!.path,
                          );

                          if (success) {
                            Get.offAllNamed('/'); // Navigate to home
                          }
                        },
                  child: authController.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Save",
                          style: TextStyle(color: AppColors.white, fontSize: 16),
                        ),
                )),
              )
            ],
          ),
        ),
      ),
    );
  }
}
