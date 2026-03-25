import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../auth/auth_controller.dart';

class CreateProfilePage extends StatefulWidget {
  final String phone; // 👈 phone pass karna padega

  const CreateProfilePage({super.key, required this.phone});

  @override
  State<CreateProfilePage> createState() =>
      _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final controller = Get.find<AuthController>();

  File? selectedImage;

  /// Image Picker
  Future<void> pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 30),

            /// Profile Image
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                backgroundImage:
                selectedImage != null ? FileImage(selectedImage!) : null,
                child: selectedImage == null
                    ? const Icon(Icons.person,
                    size: 50, color: Colors.white)
                    : null,
              ),
            ),

            TextButton(
              onPressed: pickImage,
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
              ),
            ),

            const SizedBox(height: 15),

            /// Email Field ✅
            TextField(
              controller: emailController,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                hintText: "Email",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
              ),
            ),

            const SizedBox(height: 30),

            /// Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor),
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    selectedImage == null) {
                  Get.snackbar("Error", "All fields are required");
                  return;
                }

                await controller.updateAndSaveProfile(
                  name: nameController.text,
                  email: emailController.text,
                  phone: widget.phone,
                  imagePath: selectedImage!.path,
                );

                Get.offAllNamed('/home'); // 👈 change route as per app
              },
              child: const Text(
                "Save",
                style: TextStyle(color: AppColors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
