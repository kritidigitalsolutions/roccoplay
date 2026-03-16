import 'package:flutter/material.dart';
import 'package:roccoplay/modules/profile/privacy_policy_page.dart';
import 'package:roccoplay/modules/profile/profile_selection_page.dart';
import 'package:roccoplay/modules/profile/refund_policy_page.dart';
import 'package:roccoplay/modules/profile/setting_page.dart';
import 'package:roccoplay/modules/profile/terms_condition_page.dart';
import 'package:roccoplay/modules/profile/watchlist.dart';
import '../../app/theme/app_colors.dart';
import '../premium/goPremium.dart';
import 'account_setting.dart';
import 'activate_tv_page.dart';
import 'Rate_your_app.dart';
import 'help_page.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfilePage({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // appBar: AppBar(
      //   backgroundColor: Colors.black,
      //   title: const Text("Profile"),
      // ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // =======================
            // TOP PROFILE BOX
            // =======================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.pink, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [

                    // ---------- SECTION 1 ----------
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [

                          const Icon(Icons.person,
                              color: AppColors.white, size: 40),

                          const SizedBox(width: 12),

                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Default",
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "+91 9876543210",
                                style: TextStyle(
                                    color: AppColors.grey, fontSize: 14),
                              ),
                            ],
                          ),

                          // const Spacer(),
                          //
                          // GestureDetector(
                          //   onTap: () {
                          //     Navigator.push(context, MaterialPageRoute(builder: (context)=>ProfileSelectionPage()
                          //     ),
                          //     );
                          //   },
                          //   child: const Text(
                          //     "Switch Profile",
                          //     style: TextStyle(
                          //         color: AppColors.buttonColor,
                          //         fontWeight: FontWeight.bold),
                          //   ),
                          // )
                        ],
                      ),
                    ),

                    const Divider(color: Colors.grey),

                    // ---------- SECTION 2 ----------
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [

                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "No Active Plans",
                                style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),

                          const Spacer(),

                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GoPremiumPage(),
                                ),
                              );
                            },
                            child: const Text(
                                "SUBSCRIBE",
                                style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                ),),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =======================
            // MENU ITEMS
            // =======================
            buildMenuItem(context, Icons.person_outline, "My Account", const AccountSettingsPage()),
            buildMenuItem(context, Icons.bookmark_border, "Watchlist", const WatchlistPage()),
            buildMenuItem(context, Icons.settings_outlined, "Settings", const SettingsPage()),
            buildMenuItem(context, Icons.rate_review, "Rate Our App", const ReviewPage()),
            buildMenuItem(context, Icons.info_outline, "Term & Conditions", const TermsAndConditionsPage()),
            buildMenuItem(context, Icons.privacy_tip, "Privacy Policy", const PrivacyPolicyPage()),
            buildMenuItem(context, Icons.currency_rupee, "Refund Policy", const RefundPolicyPage()),
            // buildMenuItem(context, Icons.lock_outline, "Apply Prepaid PIN", const AccountSettingsPage()),
            buildMenuItem(context, Icons.help_outline, "Help", const HelpSupportPage()),

            const SizedBox(height: 20),
            // =======================
            // SIGN OUT BUTTON
            // =======================
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () {
                  onLogout();
                },
                child: const Text(
                  "SIGN OUT",
                  style: TextStyle(
                    color: AppColors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // =======================
            // VERSION INFO
            // =======================
            const Text(
              "App Version 1.0.0",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 6),

            const Text(
              "Device: Android",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // =======================
  // REUSABLE MENU ITEM
  // =======================
  Widget buildMenuItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget page,
      ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => page,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),

            const SizedBox(width: 15),

            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
              ),
            ),

            const Spacer(),

            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
