import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class RedeemVoucherPage extends StatefulWidget {
  const RedeemVoucherPage({Key? key}) : super(key: key);

  @override
  State<RedeemVoucherPage> createState() => _RedeemVoucherPageState();
}

class _RedeemVoucherPageState extends State<RedeemVoucherPage> {
  TextEditingController voucherController = TextEditingController();
  String errorMessage = "";

  void redeemVoucher() {
    String code = voucherController.text.trim();

    if (code.isEmpty) {
      setState(() {
        errorMessage = "Please enter voucher code";
      });
    } else if (code != "ROCCO100") {
      setState(() {
        errorMessage = "Invalid voucher code";
      });
    } else {
      setState(() {
        errorMessage = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Voucher Applied Successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      /// 🔴 HEADER
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Redeem Voucher",
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
      ),

      /// 🔴 BODY
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                /// 🔹 Logo
                Image.asset(
                  "assets/images/roccoplay_logo.png",
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),

                SizedBox(height: 20),

                /// 🔹 Instruction Text
                Text(
                  "Please enter the voucher code below",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                  ),
                ),

                SizedBox(height: 20),

                /// 🔹 TextField
                TextField(
                  controller: voucherController,
                  style: TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: "Enter Voucher Code",
                    hintStyle: TextStyle(color: AppColors.grey),
                    errorText:
                    errorMessage.isEmpty ? null : errorMessage,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                      BorderSide(color: AppColors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                      BorderSide(color: AppColors.buttonColor),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide:
                      BorderSide(color: AppColors.buttonColor),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                /// 🔴 Apply Button
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                    ),
                    onPressed: redeemVoucher,
                    child: Text(
                      "Apply",
                      style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
