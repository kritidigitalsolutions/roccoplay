import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/primium_controller/premium_controller.dart';
import '../../widgets/ad_widget/banner_ad_widget.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final PremiumController premiumController = Get.put(PremiumController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.isLoggedIn.value) {
        authController.getProfile();
        premiumController.fetchAllSubscriptionStatus();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 800;
            final double bottomClearance = isWeb
                ? 40.0
                : (MediaQuery.of(context).padding.bottom + 95.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 600 : double.infinity,
                ),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    isWeb ? 24 : 0,
                    0,
                    isWeb ? 24 : 0,
                    bottomClearance,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),

                      /// 🔹 TOP COMPACT HEADER (Consistent with Search, Plans, Downloads)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: "Mo",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              TextSpan(
                                text: "re",
                                style: TextStyle(
                                  color: AppColors.buttonColor,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      /// 🔹 1. PROFILE / SUBSCRIPTION CARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF14141E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.buttonColor.withOpacity(0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.buttonColor.withOpacity(0.06),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Profile Image from API
                                    Obx(() {
                                      final user = authController.userData.value;
                                      final imageUrl = user?['avatar'] ?? user?['image'] ?? user?['profileImage'];

                                      return CircleAvatar(
                                        radius: isWeb ? 32 : 26,
                                        backgroundColor: Colors.grey[850],
                                        backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                                        child: (imageUrl == null || imageUrl.isEmpty)
                                            ? Icon(
                                                Icons.person,
                                                color: AppColors.white,
                                                size: isWeb ? 36 : 28,
                                              )
                                            : null,
                                      );
                                    }),

                                    const SizedBox(width: 14),

                                    // Name and Phone from API
                                    Expanded(
                                      child: Obx(() {
                                        final user = authController.userData.value;
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user?['name'] ?? "User Name",
                                              style: TextStyle(
                                                color: AppColors.white,
                                                fontSize: isWeb ? 18 : 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user?['phone'] ?? "No Phone",
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),

                              Divider(color: Colors.white.withOpacity(0.06), height: 1),

                              // ---------- DYNAMIC PLAN SECTION ----------
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Obx(() {
                                  final sub = premiumController.subscriptionData.value;
                                  final bool hasActiveSub = sub != null && sub['status'] == 'active';

                                  return Row(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            hasActiveSub ? Icons.verified : Icons.stars_rounded,
                                            color: hasActiveSub ? Colors.green : AppColors.buttonColor,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            hasActiveSub ? (sub['plan']?['name'] ?? "Active Plan") : "No Active Plans",
                                            style: TextStyle(
                                              color: hasActiveSub ? Colors.white : Colors.white70,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      if (!hasActiveSub)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.buttonColor,
                                            foregroundColor: AppColors.white,
                                            elevation: 2,
                                            shadowColor: AppColors.buttonColor.withOpacity(0.35),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () => AppRoutes.toGoPremium(),
                                          child: const Text(
                                            "SUBSCRIBE NOW",
                                            style: TextStyle(
                                              color: AppColors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.green.withOpacity(0.4)),
                                          ),
                                          child: const Text(
                                            "ACTIVE",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),

                      /// 🔹 2. AD AREA (In normal layout flow with clean spacing)
                      const SizedBox(height: 16),
                      const Center(child: BannerAdWidget()),
                      const SizedBox(height: 10),

                      /// 🔹 3. ACCOUNT SECTION
                      _buildSectionHeader("ACCOUNT"),
                      _buildSectionCard([
                        _buildMenuItem(
                          context: context,
                          icon: Icons.person_outline,
                          title: "My Account",
                          route: AppRoutes.accountSetting,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.bookmark_border,
                          title: "Watchlist",
                          route: AppRoutes.watchList,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.settings_outlined,
                          title: "Settings",
                          route: AppRoutes.settings,
                          showDivider: false,
                        ),
                      ]),

                      /// 🔹 4. SUPPORT & INFORMATION SECTION
                      _buildSectionHeader("SUPPORT & INFORMATION"),
                      _buildSectionCard([
                        _buildMenuItem(
                          context: context,
                          icon: Icons.rate_review_outlined,
                          title: "Rate Our App",
                          route: AppRoutes.review,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.description_outlined,
                          title: "Terms & Conditions",
                          route: AppRoutes.termsAndConditions,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.privacy_tip_outlined,
                          title: "Privacy Policy",
                          route: AppRoutes.privacyPolicy,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.currency_rupee,
                          title: "Refund Policy",
                          route: AppRoutes.refundPolicy,
                        ),
                        _buildMenuItem(
                          context: context,
                          icon: Icons.help_outline,
                          title: "Help",
                          route: AppRoutes.help,
                          showDivider: false,
                        ),
                      ]),

                      /// 🔹 5. SIGN OUT / SIGN IN BUTTON
                      const SizedBox(height: 24),
                      Center(
                        child: Obx(() {
                          final bool isLoggedIn = authController.isLoggedIn.value;
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: isLoggedIn ? onLogout : () => Get.toNamed(AppRoutes.signIn),
                            child: Text(
                              isLoggedIn ? "SIGN OUT" : "SIGN IN",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          );
                        }),
                      ),

                      /// 🔹 6. APP VERSION
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "App Version 1.0.0",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔹 Refined Section Header with RoccoPlay Pink Accent
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.buttonColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// 🔹 Grouped Section Card
  Widget _buildSectionCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
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
      ),
    );
  }

  /// 🔹 Compact Menu Item Row
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => Get.toNamed(route),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.85),
                  size: 20,
                ),
                const SizedBox(width: 14),
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
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 13,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            color: Colors.white.withOpacity(0.06),
            height: 1,
            indent: 50,
            endIndent: 16,
          ),
      ],
    );
  }
}
