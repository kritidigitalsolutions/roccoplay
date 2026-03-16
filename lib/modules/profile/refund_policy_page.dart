import 'package:flutter/material.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Refund Policy",
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
              "Refund Policy",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            SizedBox(height: 15),

            Text(
              "This refund policy outlines the conditions under which refunds may be issued for RoccoPlay subscriptions.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "1. Subscription Payments",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "All subscription payments made on RoccoPlay are generally non-refundable unless required by law.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "2. Technical Issues",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "If you experience technical issues that prevent access to the service, please contact our support team for assistance.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "3. Refund Requests",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "Refund requests must be submitted within 7 days of purchase. Each request will be reviewed individually.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 20),

            Text(
              "4. Cancellation",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),

            SizedBox(height: 8),

            Text(
              "You can cancel your subscription anytime, but the remaining subscription period will continue until the billing cycle ends.",
              style: TextStyle(color: Colors.white70),
            ),

            SizedBox(height: 40),

            Center(
              child: Text(
                "© 2026 RoccoPlay",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
