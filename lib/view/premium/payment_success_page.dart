import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/home_controller/home_controller.dart';
import '../../view_model/primium_controller/premium_controller.dart';
import '../homePages/mainHomepage.dart';

class PaymentSuccessPage extends StatelessWidget {
  final String orderId;
  final num amount;
  final String planName;
  final String? paymentMode;
  final String? transactionId;
  final String? message;
  final DateTime? timestamp;

  const PaymentSuccessPage({
    super.key,
    required this.orderId,
    required this.amount,
    required this.planName,
    this.paymentMode = "HDFC Bank (SmartGateway)",
    this.transactionId,
    this.message,
    this.timestamp,
  });

  void _onDone() {
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().selectedIndex.value = 0;
    }
    if (Get.isRegistered<PremiumController>()) {
      Get.find<PremiumController>().fetchAllSubscriptionStatus();
    }
    Get.offAll(() => const MainHomePage());
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'dd MMM yyyy, hh:mm:ss a',
    ).format(timestamp ?? DateTime.now());
    final displayAmount = "₹${amount.toStringAsFixed(2)}";

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onDone();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            "Transaction Status",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: _onDone,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),

                      /// 🔹 Success Animated Icon Badge
                      Center(
                        child: Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Color(0xFF10B981),
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      /// 🔹 Success Headline
                      const Text(
                        "Payment Successful!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (message != null && message!.trim().isNotEmpty)
                            ? message!
                            : "Your transaction has been processed in real-time.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      /// 🔹 Amount Paid Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.4),
                              const Color(0xFF1F1F2E),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Amount Paid",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayAmount,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "CONFIRMED",
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🔹 Real-Time Receipt Details Card (Bank Required Fields)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16161F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Transaction Details",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _detailRow(
                              title: "Order Number",
                              value: orderId,
                              showCopy: true,
                              context: context,
                            ),
                            const Divider(color: Colors.white12, height: 20),
                            _detailRow(
                              title: "Purchased Plan",
                              value: planName,
                            ),
                            const Divider(color: Colors.white12, height: 20),
                            _detailRow(
                              title: "Payment Gateway",
                              value: paymentMode ?? "HDFC Bank (SmartGateway)",
                            ),
                            if (transactionId != null &&
                                transactionId!.isNotEmpty) ...[
                              const Divider(color: Colors.white12, height: 20),
                              _detailRow(
                                title: "Reference ID",
                                value: transactionId!,
                                showCopy: true,
                                context: context,
                              ),
                            ],
                            const Divider(color: Colors.white12, height: 20),
                            _detailRow(
                              title: "Date & Time",
                              value: formattedDate,
                            ),
                            const Divider(color: Colors.white12, height: 20),
                            _detailRow(
                              title: "Status",
                              value: "SUCCESS",
                              valueColor: const Color(0xFF10B981),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// 🔹 VIP Access Benefits Note
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F2E).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.buttonColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              color: AppColors.buttonColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your VIP membership is now active. Enjoy unlimited access and ad-free streaming!",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// 🔹 Bottom Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _onDone,
                    child: const Text(
                      "Start Watching",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow({
    required String title,
    required String value,
    Color? valueColor,
    bool isBold = false,
    bool showCopy = false,
    BuildContext? context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (showCopy && context != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$title copied to clipboard"),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF1E1E2C),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
