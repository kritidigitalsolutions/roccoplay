import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PaymentBottomSheet extends StatelessWidget {
  const PaymentBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // 🔥 Half screen
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [

              /// 🔥 Drag Handle
              Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              /// Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Select Payment Method",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Divider(color: Colors.grey),

              /// Payment Methods List
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [

                    paymentTile(Icons.account_balance_wallet, "UPI"),
                    paymentTile(Icons.credit_card, "Credit / Debit Card"),
                    paymentTile(Icons.account_balance, "Net Banking"),
                    paymentTile(Icons.payments, "Wallet"),
                    paymentTile(Icons.qr_code, "Scan & Pay"),

                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🔹 Payment Tile
  Widget paymentTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        // Handle payment click
      },
    );
  }
}
