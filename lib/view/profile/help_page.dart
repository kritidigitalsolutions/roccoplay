import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/profile/privacy_controller.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final PrivacyController controller = Get.put(PrivacyController());

  @override
  void initState() {
    super.initState();
    controller.fetchHelpData();
  }

  Future<void> _makeCall() async {
    final Uri url = Uri.parse('tel:+919876543210');
    if (!await launchUrl(url)) {
      Get.snackbar("Error", "Could not launch dialer",
          colorText: Colors.white, backgroundColor: Colors.red);
    }
  }

  Future<void> _sendEmail() async {
    final Uri url = Uri.parse('mailto:support@roccoplay.com?subject=Help Support&body=Hi Rocco Play Team,');
    if (!await launchUrl(url)) {
      Get.snackbar("Error", "Could not launch email app",
          colorText: Colors.white, backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Help & Support",
          style: TextStyle(color: AppColors.white),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Column(
        children: [
          /// 🔹 CONTACT OPTIONS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.call,
                    title: "Call Us",
                    subtitle: "9876543210",
                    onTap: _makeCall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContactCard(
                    icon: Icons.email,
                    title: "Email Us",
                    subtitle: "support@roccoplay.com",
                    onTap: _sendEmail,
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Frequently Asked Questions",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              if (controller.isLoadingHelp.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.helpData.isEmpty) {
                return const Center(
                  child: Text(
                    "No Help Data Found",
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.helpData.length,
                itemBuilder: (context, index) {
                  final help = controller.helpData[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        help['question'] ?? "",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      iconColor: AppColors.buttonColor,
                      collapsedIconColor: Colors.white,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            help['answer'] ?? "",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.buttonColor, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
