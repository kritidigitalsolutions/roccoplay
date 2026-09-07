import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/app/theme/app_colors.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/primium_controller/premium_controller.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final PremiumController premiumController = Get.put(PremiumController());

    // Rx variables for expand/collapse logic
    final loginExpanded = true.obs; // Default expanded for better visibility
    final subscriptionExpanded = true.obs;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Account Settings",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 800;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  /// LOGIN INFORMATION SECTION
                  Obx(
                    () => _buildExpandableSection(
                      title: "Login Information",
                      icon: Icons.person_outline,
                      isExpanded: loginExpanded.value,
                      onTap: () => loginExpanded.toggle(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            Icons.phone,
                            "Phone",
                            authController.userData.value?['phone'] ?? 'N/A',
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.email,
                            "Email",
                            authController.userData.value?['email'] ?? 'N/A',
                          ),
                          const SizedBox(height: 15),
                          _buildInfoRow(
                            Icons.cake,
                            "Age",
                            authController.userData.value?['age']?.toString() ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// SUBSCRIPTION SECTION (DYNAMIC)
                  Obx(() {
                    final sub = premiumController.subscriptionData.value;
                    final hasActiveSub = sub != null && sub['status'] == 'active';

                    return _buildExpandableSection(
                      title: "Subscription",
                      icon: Icons.star_outline,
                      isExpanded: subscriptionExpanded.value,
                      onTap: () => subscriptionExpanded.toggle(),
                      child: hasActiveSub
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _buildSubscriptionBadge(
                                      sub['plan']['name'] ?? 'Premium',
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.verified, color: Colors.green, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  "Start Date",
                                  premiumController.formatDate(sub['startDate']),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.event_available,
                                  "Valid Till",
                                  premiumController.formatDate(sub['endDate']),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.currency_rupee,
                                  "Amount Paid",
                                  "₹${sub['amount']}",
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.info_outline,
                                  "Status",
                                  sub['status'].toString().toUpperCase(),
                                  color: Colors.green,
                                ),
                              ],
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Column(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.white24, size: 40),
                                    const SizedBox(height: 10),
                                    const Text(
                                      "No active subscription found",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    );
                  }),

                  const SizedBox(height: 20),

                  NativeAdWidget(
                    adType: TemplateType.medium,
                    constraints: BoxConstraints(
                      minWidth: isWeb ? 600 : constraints.maxWidth,
                      minHeight: 300,
                      maxWidth: isWeb ? 600 : constraints.maxWidth,
                      maxHeight: 350,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// INFO ROW WIDGET
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.buttonColor, size: 18),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// SUBSCRIPTION BADGE
  Widget _buildSubscriptionBadge(String planName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.buttonColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.buttonColor.withOpacity(0.5)),
      ),
      child: Text(
        planName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  /// EXPANDABLE SECTION WIDGET
  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.buttonColor.withOpacity(0.3)
              : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            leading: Icon(icon, color: Colors.white),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.white54,
            ),
            onTap: onTap,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(width: double.infinity, child: child),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
