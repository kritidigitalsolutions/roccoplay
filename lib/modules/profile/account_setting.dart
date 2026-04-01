import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../view_model/auth_controller/auth_controller.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    // Rx variables for expand/collapse logic (No setState)
    final loginExpanded = false.obs;
    final subscriptionExpanded = false.obs;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Account Settings",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// LOGIN INFORMATION SECTION
            Obx(() => _buildExpandableSection(
                  title: "Login Information",
                  isExpanded: loginExpanded.value,
                  onTap: () => loginExpanded.toggle(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Phone: ${authController.userData.value?['phone'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Email: ${authController.userData.value?['email'] ?? 'N/A'}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                )),

            const SizedBox(height: 15),

            /// SUBSCRIPTION SECTION
            Obx(() => _buildExpandableSection(
                  title: "Subscription",
                  isExpanded: subscriptionExpanded.value,
                  onTap: () => subscriptionExpanded.toggle(),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Plan: Premium",
                          style: TextStyle(color: Colors.white)),
                      SizedBox(height: 5),
                      Text("Valid Till: 30 March 2026",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  /// EXPANDABLE SECTION WIDGET
  Widget _buildExpandableSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
            onTap: onTap,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(width: double.infinity, child: child),
            ),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          )
        ],
      ),
    );
  }
}
