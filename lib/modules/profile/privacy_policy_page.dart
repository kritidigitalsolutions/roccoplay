import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Privacy Policy",
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
              "Privacy Policy",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 15),

            Text(
              "RoccoPlay values your privacy. This policy explains how we collect, use, and protect your information.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "1. Information We Collect",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "We may collect personal information such as your name, email address, phone number, and device information when you register or use our app.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "2. How We Use Information",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "Your information is used to provide services, improve app performance, personalize content, and enhance security.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "3. Data Protection",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "We implement security measures to protect your data from unauthorized access or misuse.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "4. Third-Party Services",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "Our app may use third-party services such as payment gateways and analytics tools that may collect certain data.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "5. Changes to Privacy Policy",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "We may update this privacy policy from time to time. Continued use of the app means you accept the updated policy.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 40),

            Center(
              child: Text(
                "© 2026 RoccoPlay",
                style: TextStyle(color: Colors.white54),
              ),
            )
          ],
        ),
      ),
    );
  }
}
