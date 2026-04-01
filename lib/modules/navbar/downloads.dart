import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/home_controller/home_controller.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HomeController homeController = Get.find<HomeController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Downloads",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() => _buildDownloadsView(authController, homeController)),
    );
  }

  Widget _buildDownloadsView(AuthController authController, HomeController homeController) {
    bool isLoggedIn = authController.isLoggedIn.value;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.download_for_offline_outlined,
              size: 90,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              isLoggedIn
                  ? "Start exploring and download your favourites"
                  : "Please sign in to view your downloads",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Download your favourite movies and shows to watch offline anytime.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 25),

            /// 🔥 Button Changes Based On Login
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (isLoggedIn) {
                  // Go to Home tab
                  homeController.selectedIndex.value = 0;
                } else {
                  Get.to(() => const SignInPage());
                }
              },
              child: Text(
                isLoggedIn ? "Explore" : "Sign In",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
