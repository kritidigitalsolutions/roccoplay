import 'package:flutter/material.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Terms & Conditions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 15),

            Text(
              "Welcome to RoccoPlay. By using our app, you agree to the following terms and conditions.",
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),

            SizedBox(height: 20),

            /// 1
            Text(
              "1. Account Usage",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "Users must provide accurate login information. You are responsible for maintaining the confidentiality of your account and password.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            /// 2
            Text(
              "2. Subscription",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "Some features of RoccoPlay require a paid subscription. Subscription fees are non-refundable unless otherwise stated.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            /// 3
            Text(
              "3. Content Usage",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "All videos, movies, and shows available on RoccoPlay are protected by copyright. Users are not allowed to copy, record, or distribute the content.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            /// 4
            Text(
              "4. Devices & Screens",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "Your subscription allows a limited number of devices and screens. Exceeding this limit may temporarily block streaming.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            /// 5
            Text(
              "5. Privacy",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "We respect your privacy. Personal information such as email and phone number will only be used to improve service and security.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            /// 6
            Text(
              "6. Changes to Terms",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "RoccoPlay reserves the right to update these terms at any time. Continued use of the app means you accept the updated terms.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 40),

            Center(
              child: Text(
                "© 2026 RoccoPlay. All Rights Reserved.",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
