import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/view_model/primium_controller/premium_controller.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../widgets/expendable_plan_card.dart';
import '../../utils/custom_snackbar.dart';

class GoPremiumPage extends StatelessWidget {
  const GoPremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final PremiumController controller = Get.put(PremiumController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWeb = constraints.maxWidth > 800;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 600 : double.infinity,
                ),
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    );
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 4),

                      /// 🔹 TOP COMPACT HEADER (Consistent with Search Screen)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Pla",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "ns",
                                        style: TextStyle(
                                          color: AppColors.buttonColor,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (Navigator.of(context).canPop())
                                  IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(),
                                    tooltip: 'Back',
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Upgrade Your Plan for More Benefits",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// 🔹 Main Scrollable Content Area (Plan Cards, Ad Container)
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [

                              /// 🔹 Expandable Plans
                              Obx(() {
                                if (controller.plans.isEmpty) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        "No plans available",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                }

                                return Column(
                                  children: controller.plans.asMap().entries.map((entry) {
                                    final int index = entry.key;
                                    final plan = entry.value;
                                    final String planKey = plan.id.isNotEmpty
                                        ? plan.id
                                        : (plan.name.isNotEmpty
                                            ? plan.name
                                            : index.toString());

                                    return Obx(() {
                                      final bool isSelected =
                                          controller.selectedPlanIndex.value == index;
                                      final bool isExpanded =
                                          controller.isPlanExpanded(planKey);

                                      return ExpandablePlanCard(
                                        key: ValueKey('plan_$planKey'),
                                        title: plan.name,
                                        price: "₹${plan.price}",
                                        duration: "/ ${plan.duration} Days",
                                        features: plan.features,
                                        isHighlighted: isSelected,
                                        isExpanded: isExpanded,
                                        onExpansionChanged: () =>
                                            controller.togglePlanExpansion(planKey),
                                        onTap: () => controller.selectPlan(index),
                                      );
                                    });
                                  }).toList(),
                                );
                              }),

                              const SizedBox(height: 10),

                              /// 🔹 Native Ad Container (Positioned naturally after plan cards in document flow)
                              NativeAdWidget(
                                adType: TemplateType.small,
                                constraints: BoxConstraints(
                                  minWidth: 320,
                                  minHeight: 90,
                                  maxWidth: isWeb ? 600 : double.infinity,
                                  maxHeight: 120,
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),

                      /// 🔴 Sign In / Purchase / Already Purchased Button
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          15.0,
                          10.0,
                          15.0,
                          (Navigator.of(context).canPop() || isWeb || kIsWeb)
                              ? 15.0
                              : 95.0,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: Obx(() {
                            if (controller.isSubscribing.value) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.buttonColor,
                                ),
                              );
                            }

                            final bool hasActive =
                                controller.hasActiveSubscription;

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasActive
                                    ? Colors.grey
                                    : AppColors.buttonColor,
                              ),
                              onPressed: () {
                                if (!controller.isUserLoggedIn.value) {
                                  Get.toNamed(AppRoutes.signIn);
                                  return;
                                }

                                if (hasActive) {
                                  CustomSnackbar.show(
                                    title: "Info",
                                    message: "Already Purchased",
                                  );
                                } else {
                                  if (controller.plans.isNotEmpty) {
                                    final selectedPlan =
                                        controller.plans[controller
                                            .selectedPlanIndex
                                            .value];
                                    controller.subscribeToPlan(selectedPlan.id);
                                  }
                                }
                              },
                              child: Text(
                                hasActive
                                    ? "Already Purchased"
                                    : (controller.isUserLoggedIn.value
                                          ? "Continue with ${controller.selectedPrice.value}"
                                          : "Sign In"),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      /// 🔹 Bottom 50%-50% (Mobile Only)
                      // if (!isWeb)
                      //   Row(
                      //     children: [
                      //       Expanded(
                      //         child: GestureDetector(
                      //           onTap: () {
                      //             if (controller.isUserLoggedIn.value) {
                      //               Get.dialog(const ApplyPromoPopup());
                      //             } else {
                      //               _showSignInPopup();
                      //             }
                      //           },
                      //           child: Container(
                      //             padding: const EdgeInsets.symmetric(
                      //               vertical: 15,
                      //             ),
                      //             alignment: Alignment.center,
                      //             decoration: const BoxDecoration(
                      //               border: Border(
                      //                 top: BorderSide(
                      //                   color: AppColors.borderColor,
                      //                 ),
                      //                 right: BorderSide(
                      //                   color: AppColors.borderColor,
                      //                 ),
                      //               ),
                      //             ),
                      //             child: const Text(
                      //               "Apply Promo Code",
                      //               style: TextStyle(color: AppColors.white),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //       Expanded(
                      //         child: GestureDetector(
                      //           onTap: () {
                      //             if (controller.isUserLoggedIn.value) {
                      //               Get.toNamed(AppRoutes.redeemVoucher);
                      //             } else {
                      //               _showSignInPopup();
                      //             }
                      //           },
                      //           child: Container(
                      //             padding: const EdgeInsets.symmetric(
                      //               vertical: 15,
                      //             ),
                      //             alignment: Alignment.center,
                      //             decoration: const BoxDecoration(
                      //               border: Border(
                      //                 top: BorderSide(
                      //                   color: AppColors.borderColor,
                      //                 ),
                      //               ),
                      //             ),
                      //             child: const Text(
                      //               "Apply Prepaid Pin",
                      //               style: TextStyle(color: AppColors.white),
                      //             ),
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔹 Sign In Required Popup
  // void _showSignInPopup() {
  //   Get.dialog(
  //     AlertDialog(
  //       backgroundColor: Colors.black,
  //       title: const Text(
  //         "Sign In Required",
  //         style: TextStyle(color: AppColors.white),
  //       ),
  //       content: const Text(
  //         "Please sign in to complete the payment.",
  //         style: TextStyle(color: AppColors.white),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Get.back(),
  //           child: const Text(
  //             "Cancel",
  //             style: TextStyle(color: AppColors.grey),
  //           ),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: AppColors.buttonColor,
  //           ),
  //           onPressed: () {
  //             Get.back();
  //             Get.toNamed(AppRoutes.signIn);
  //           },
  //           child: const Text(
  //             "Sign In",
  //             style: TextStyle(color: AppColors.white),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
