import 'package:flutter/material.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {

  bool loginExpanded = false;
  bool subscriptionExpanded = false;
  // bool profileExpanded = false;
  // bool activeExpanded = false;

  // List<String> profiles = ["Krishna", "Kids", "Guest"];

  @override
  Widget build(BuildContext context) {
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

            /// LOGIN
            _buildExpandableSection(
              title: "Login Information",
              isExpanded: loginExpanded,
              onTap: () {
                setState(() {
                  loginExpanded = !loginExpanded;
                });
              },
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Phone: +91 9876543210",
                      style: TextStyle(color: Colors.white)),
                  SizedBox(height: 5),
                  Text("Email: krishna@email.com",
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// SUBSCRIPTION
            _buildExpandableSection(
              title: "Subscription",
              isExpanded: subscriptionExpanded,
              onTap: () {
                setState(() {
                  subscriptionExpanded = !subscriptionExpanded;
                });
              },
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
            ),

            // const SizedBox(height: 15),
            //
            // /// PROFILE
            // _buildExpandableSection(
            //   title: "Profile & Parental Control",
            //   isExpanded: profileExpanded,
            //   onTap: () {
            //     setState(() {
            //       profileExpanded = !profileExpanded;
            //     });
            //   },
            //   child: Column(
            //     children: profiles.map((profile) {
            //       return Container(
            //         margin: const EdgeInsets.only(bottom: 10),
            //         padding: const EdgeInsets.all(12),
            //         decoration: BoxDecoration(
            //           color: Colors.grey[900],
            //           borderRadius: BorderRadius.circular(10),
            //         ),
            //         child: Row(
            //           children: [
            //             const CircleAvatar(
            //               backgroundColor: Colors.red,
            //               child: Icon(Icons.person, color: Colors.white),
            //             ),
            //             const SizedBox(width: 10),
            //             Text(
            //               profile,
            //               style: const TextStyle(color: Colors.white),
            //             ),
            //             const Spacer(),
            //             const Icon(
            //               Icons.arrow_forward_ios,
            //               size: 14,
            //               color: Colors.white54,
            //             )
            //           ],
            //         ),
            //       );
            //     }).toList(),
            //   ),
            // ),

            // const SizedBox(height: 15),
            //
            // /// ACTIVE SCREENS
            // _buildExpandableSection(
            //   title: "Active Screens & Devices",
            //   isExpanded: activeExpanded,
            //   onTap: () {
            //     setState(() {
            //       activeExpanded = !activeExpanded;
            //     });
            //   },
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //
            //       Row(
            //         children: [
            //
            //           Expanded(
            //             child: ElevatedButton(
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: Colors.red,
            //               ),
            //               onPressed: () {},
            //               child: const Text(
            //                 "Active Devices",
            //                 style: TextStyle(color: Colors.white),
            //               ),
            //             ),
            //           ),
            //
            //           const SizedBox(width: 10),
            //
            //           Expanded(
            //             child: ElevatedButton(
            //               style: ElevatedButton.styleFrom(
            //                 backgroundColor: Colors.grey,
            //               ),
            //               onPressed: () {},
            //               child: const Text(
            //                 "Active Screens",
            //                 style: TextStyle(color: Colors.white),
            //               ),
            //             ),
            //           ),
            //         ],
            //       ),
            //
            //       const SizedBox(height: 15),
            //
            //       const Text(
            //         "📱 iPhone 14 - Meerut",
            //         style: TextStyle(color: Colors.white),
            //       ),
            //
            //       SizedBox(height: 8),
            //
            //       const Text(
            //         "💻 MacBook - Last active 2h ago",
            //         style: TextStyle(color: Colors.white),
            //       ),
            //
            //       SizedBox(height: 8),
            //
            //       const Text(
            //         "Currently using 2 out of 4 screens",
            //         style: TextStyle(color: Colors.white70),
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// EXPANDABLE SECTION
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
              isExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),

            onTap: onTap,
          ),

          AnimatedCrossFade(
            firstChild: const SizedBox(),
            secondChild: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          )
        ],
      ),
    );
  }
}
