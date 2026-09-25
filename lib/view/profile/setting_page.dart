import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';
import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';
import '../../view_model/profile/settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = Get.put(SettingsController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text("Settings", style: TextStyle(color: AppColors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 800;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _buildSectionHeader("Notifications"),
                Obx(
                  () => _buildSwitchTile(
                    "Push Notifications",
                    controller.isPushNotificationsEnabled.value,
                    controller.togglePushNotifications,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("Playback"),
                Obx(
                  () => _buildSwitchTile(
                    "Auto Play",
                    controller.isAutoPlayEnabled.value,
                    controller.toggleAutoPlay,
                  ),
                ),
                Obx(
                  () => _buildSwitchTile(
                    "WiFi Only",
                    controller.isWiFiOnlyEnabled.value,
                    controller.toggleWiFiOnly,
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionHeader("Account"),
                _buildActionTile("Language", "English", () {}),
                _buildActionTile("App Version", "1.0.0", null),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => Get.toNamed(AppRoutes.deleteAccount),
                  title: const Text(
                    "Delete Account",
                    style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.redAccent,
                    size: 14,
                  ),
                ),
                const SizedBox(height: 15),

                NativeAdWidget(
                  adType: TemplateType.small,
                  constraints: BoxConstraints(
                    minWidth: isWeb ? 600 : constraints.maxWidth,
                    minHeight: 80,
                    maxWidth: isWeb ? 600 : constraints.maxWidth,
                    maxHeight: 100,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.pinkAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.pinkAccent,
      ),
    );
  }

  Widget _buildActionTile(String title, String trailing, VoidCallback? onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: Text(
        trailing,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }
}
