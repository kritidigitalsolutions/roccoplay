import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';
import '../../app/theme/app_colors.dart';
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
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Get.back(),
          tooltip: 'Back',
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWeb = constraints.maxWidth > 800;
          final double bottomPadding = MediaQuery.of(context).padding.bottom + 20;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 600 : double.infinity,
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding),
                children: [
                  /// 1. NOTIFICATIONS SECTION
                  _buildSectionHeader("Notifications"),
                  _buildSectionCard(
                    children: [
                      Obx(
                        () => _buildSwitchTile(
                          title: "Push Notifications",
                          value: controller.isPushNotificationsEnabled.value,
                          onChanged: controller.togglePushNotifications,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  /// 2. PLAYBACK SECTION
                  _buildSectionHeader("Playback"),
                  _buildSectionCard(
                    children: [
                      Obx(
                        () => _buildSwitchTile(
                          title: "Auto Play",
                          value: controller.isAutoPlayEnabled.value,
                          onChanged: controller.toggleAutoPlay,
                        ),
                      ),
                      _buildDivider(),
                      Obx(
                        () => _buildSwitchTile(
                          title: "WiFi Only",
                          value: controller.isWiFiOnlyEnabled.value,
                          onChanged: controller.toggleWiFiOnly,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  /// 3. ACCOUNT SECTION
                  _buildSectionHeader("Account"),
                  _buildSectionCard(
                    children: [
                      _buildActionTile(
                        title: "Language",
                        trailing: "English",
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        title: "App Version",
                        trailing: "1.0.0",
                        onTap: null,
                      ),
                    ],
                  ),

                  /// 4. AD SECTION
                  const SizedBox(height: 24),
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
        },
      ),
    );
  }

  /// Section Header with RoccoPlay Pink Accent
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.buttonColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Grouped Section Container
  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  /// Subtle Row Divider
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.06),
      indent: 16,
      endIndent: 16,
    );
  }

  /// Switch Tile with RoccoPlay Theme
  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.buttonColor,
              inactiveThumbColor: Colors.grey.shade400,
              inactiveTrackColor: const Color(0xFF2A2A38),
            ),
          ],
        ),
      ),
    );
  }

  /// Action Tile for Read-only or Navigation Values
  Widget _buildActionTile({
    required String title,
    required String trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              trailing,
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
