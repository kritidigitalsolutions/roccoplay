import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const Text(
            "How can we help you?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),

          const SizedBox(height: 20),

          /// Cancel Subscription
          _helpItem(
            icon: Icons.cancel_outlined,
            title: "Cancel Subscription",
            subtitle: "Manage or cancel your subscription",
            onTap: () {},
          ),

          /// Contact Support
          _helpItem(
            icon: Icons.support_agent,
            title: "Contact Support Team",
            subtitle: "Chat or email our support team",
            onTap: () {},
          ),

          /// Account Help
          _helpItem(
            icon: Icons.person,
            title: "Account Help",
            subtitle: "Issues with login or account",
            onTap: () {},
          ),

          /// Report Problem
          _helpItem(
            icon: Icons.bug_report,
            title: "Report a Problem",
            subtitle: "Video not playing or app issue",
            onTap: () {},
          ),

          /// FAQ
          _helpItem(
            icon: Icons.help_outline,
            title: "Frequently Asked Questions",
            subtitle: "Find quick answers",
            onTap: () {},
          ),

          const SizedBox(height: 30),

          const Divider(color: Colors.white24),

          const SizedBox(height: 20),

          const Text(
            "Need more help?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Email: support@roccoplay.com",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 5),

          const Text(
            "Response time: within 24 hours",
            style: TextStyle(color: Colors.white54),
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              "© 2026 RoccoPlay",
              style: TextStyle(color: Colors.white38),
            ),
          )
        ],
      ),
    );
  }

  /// HELP ITEM TILE
  Widget _helpItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.buttonColor),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.white),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.white),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.white,
        ),
        onTap: onTap,
      ),
    );
  }
}
