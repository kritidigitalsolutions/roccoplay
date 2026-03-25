import 'package:flutter/material.dart';

import '../../data/providers/privacy_provider.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {

  String title = "";
  String content = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPrivacy();
  }

  void fetchPrivacy() async {
    final data = await PrivacyService.getPrivacyPolicy();

    if (data != null) {
      setState(() {
        title = data['document']['title'] ?? "";
        content = data['document']['content'] ?? "";
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

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

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            const Center(
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
