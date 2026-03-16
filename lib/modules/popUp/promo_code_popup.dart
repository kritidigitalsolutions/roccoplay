import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class ApplyPromoPopup extends StatefulWidget {
  const ApplyPromoPopup({Key? key}) : super(key: key);

  @override
  State<ApplyPromoPopup> createState() => _ApplyPromoPopupState();
}

class _ApplyPromoPopupState extends State<ApplyPromoPopup> {
  TextEditingController promoController = TextEditingController();

  double originalPrice = 199;
  double totalAmount = 199;

  void applyPromo() {
    if (promoController.text.trim().toLowerCase() == "rocco50") {
      setState(() {
        totalAmount = originalPrice * 0.5;
      });
    } else {
      setState(() {
        totalAmount = originalPrice;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// 🔴 Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Apply Promo Code",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: AppColors.white),
                  )
                ],
              ),

              SizedBox(height: 20),

              Text(
                "Your Plan",
                style: TextStyle(color: AppColors.grey),
              ),

              SizedBox(height: 10),

              Row(
                children: [
                  Icon(Icons.workspace_premium, color: AppColors.buttonColor),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Mobile Only",
                          style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold)),
                      Text("Billed every month",
                          style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12)),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 10),

              Text(
                "INR ${originalPrice.toStringAsFixed(0)}",
                style: TextStyle(
                  color: AppColors.buttonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 20),

              Text(
                "Have a promo code?",
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: promoController,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter Code",
                        hintStyle:
                        TextStyle(color: AppColors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: AppColors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: AppColors.buttonColor),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                    ),
                    onPressed: applyPromo,
                    child: Text("Apply",
                    style: TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold
                    ),),
                  ),
                ],
              ),

              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Amount",
                      style: TextStyle(color: AppColors.white)),
                  Text(
                    "INR ${totalAmount.toStringAsFixed(0)}",
                    style: TextStyle(
                        color: AppColors.buttonColor,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                  ),
                  onPressed: () {
                    // Navigator.pop(context);
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //       builder: (context) => PaymentPage()),
                    // );
                  },
                  child: Text(
                    "Proceed To Pay",
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
    );
  }
}
