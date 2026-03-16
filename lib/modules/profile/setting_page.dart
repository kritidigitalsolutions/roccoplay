import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool downloadWifiOnly = true;
  bool notificationsEnabled = false;

  String selectedQuality = "Auto";

  final List<String> qualityOptions = [
    "Auto",
    "High",
    "Standard",
    "Basic",
    "Low",
    "Minimum",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// ================= VIDEO QUALITY =================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _boxDecoration(),
            child: ExpansionTile(
              collapsedIconColor: Colors.white,
              iconColor: Colors.white,
              title: const Text(
                "Video Quality",
                style: TextStyle(color: Colors.white),
              ),
              children: qualityOptions.map((quality) {
                return RadioListTile(
                  activeColor: Colors.red,
                  title: Text(
                    quality,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  value: quality,
                  groupValue: selectedQuality,
                  onChanged: (value) {
                    setState(() {
                      selectedQuality = value!;
                    });
                  },
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 15),

          /// ================= DOWNLOAD OVER WIFI =================
          Container(
            decoration: _boxDecoration(),
            child: SwitchListTile(
              activeColor: AppColors.buttonColor,
              title: const Text(
                "Download Over WiFi Only",
                style: TextStyle(color: AppColors.white),
              ),
              value: downloadWifiOnly,
              onChanged: (value) {
                setState(() {
                  downloadWifiOnly = value;
                });
              },
            ),
          ),

          const SizedBox(height: 15),

          /// ================= NOTIFICATIONS =================
          Container(
            decoration: _boxDecoration(),
            child: SwitchListTile(
              activeColor: AppColors.buttonColor,
              title: const Text(
                "Notifications",
                style: TextStyle(color: AppColors.white),
              ),
              value: notificationsEnabled,
              onChanged: (value) {
                if (value == true) {
                  _showNotificationPopup();
                } else {
                  setState(() {
                    notificationsEnabled = false;
                  });
                }
              },
            ),
          ),

        ],
      ),
    );
  }

  /// ================= POPUP =================
  void _showNotificationPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.grey,
          title: const Text(
            "Allow Notifications?",
            style: TextStyle(color: AppColors.white),
          ),
          content: const Text(
            "Enable notifications to stay updated with new releases and offers.",
            style: TextStyle(color: AppColors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
              ),
              onPressed: () {
                setState(() {
                  notificationsEnabled = true;
                });
                Navigator.pop(context);
              },
              child: const Text("Proceed",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ================= COMMON BOX DECORATION =================
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
    );
  }
}
