import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import 'package:roccoplay/modules/premium/paymentPage.dart';
import 'package:roccoplay/view_model/primium_controller/premium_controller.dart';
import '../../app/theme/app_colors.dart';
import '../../widgets/expendable_plan_card.dart';
import '../popUp/promo_code_popup.dart';
import '../popUp/redeem_voucher_page.dart';
import '../homePages/mainHomepage.dart';

class GoPremiumPage extends StatelessWidget {
  const GoPremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PremiumController controller = Get.put(PremiumController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 Top Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Back Icon
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
                    onPressed: () {
                      Get.offAll(() => const MainHomePage());
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 Upgrade Text
            const Text(
              "Upgrade Your Plan for More Benefits",
              style: TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ///  Custom Plan Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(child: _buildPlanButton(controller, "Yearly", 0)),
                  Expanded(child: _buildPlanButton(controller, "Monthly", 1)),
                  Expanded(child: _buildPlanButton(controller, "Others", 2)),
                ],
              ),
            ),

            /// 🔹 Plans According To Selection
            Expanded(
              child: Obx(() => buildPlanList(
                    controller.selectedPlanIndex.value == 0
                        ? "Yearly"
                        : controller.selectedPlanIndex.value == 1
                            ? "Monthly"
                            : "Others",
                  )),
            ),

            /// 🔴 Sign In / Purchase Button
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                      ),
                      onPressed: () {
                        if (controller.isUserLoggedIn.value) {
                          Get.bottomSheet(
                            const PaymentBottomSheet(),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                          );
                        } else {
                          Get.to(() => const SignInPage());
                        }
                      },
                      child: Text(
                        controller.isUserLoggedIn.value
                            ? "Continue with ${controller.selectedPrice.value}"
                            : "Sign In",
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
              ),
            ),

            /// 🔹 Bottom 50%-50%
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (controller.isUserLoggedIn.value) {
                        Get.dialog(const ApplyPromoPopup());
                      } else {
                        _showSignInPopup();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderColor),
                          right: BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                      child: const Text("Apply Promo Code",
                          style: TextStyle(color: AppColors.white)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (controller.isUserLoggedIn.value) {
                        Get.to(() => RedeemVoucherPage());
                      } else {
                        _showSignInPopup();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.borderColor),
                        ),
                      ),
                      child: const Text("Apply Prepaid Pin",
                          style: TextStyle(color: AppColors.white)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// 🔴 Plan Button UI
  Widget _buildPlanButton(PremiumController controller, String text, int index) {
    return Obx(() {
      bool isSelected = controller.selectedPlanIndex.value == index;
      return GestureDetector(
        onTap: () {
          controller.selectPlan(index);
        },
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.buttonColor : Colors.grey[850],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    });
  }

  /// 🔹 Plan List
  Widget buildPlanList(String type) {
    return ListView(
      padding: const EdgeInsets.all(15),
      children: [
        ExpandablePlanCard(
          title: "Gold $type",
          price: "₹999",
          duration: type == "Yearly" ? "/ Year" : "/ Month",
        ),
      ],
    );
  }

  /// 🔹 Sign In Required Popup
  void _showSignInPopup() {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.black,
        title: const Text("Sign In Required", style: TextStyle(color: AppColors.white)),
        content: const Text(
          "Please sign in to complete the payment.",
          style: TextStyle(color: AppColors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonColor),
            onPressed: () {
              Get.back();
              Get.to(() => const SignInPage());
            },
            child: const Text(
              "Sign In",
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
