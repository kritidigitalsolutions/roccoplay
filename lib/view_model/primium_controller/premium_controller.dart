import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/plan_response/plan_model.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/premium_repository.dart';
import '../../utils/app_session.dart';
import '../auth_controller/auth_controller.dart';

class PremiumController extends GetxController {
  late final PremiumRepository _repository;
  final AuthController _authController = Get.find<AuthController>();

  var selectedPlanIndex = 0.obs;
  // Use AuthController's isLoggedIn status instead of local copy
  RxBool get isUserLoggedIn => _authController.isLoggedIn;

  var selectedPrice = "0".obs;
  var isLoading = true.obs;
  var isSubscribing = false.obs;
  var isRedeeming = false.obs;
  var isApplyingPromo = false.obs;
  var plans = <PlanModel>[].obs;

  // Promo Code State
  var appliedPromoCode = "".obs;
  var originalPrice = 0.0.obs;
  var discountedPrice = 0.0.obs;
  var isPromoApplied = false.obs;

  // Subscription Status Data
  var subscriptionData = Rxn<Map<String, dynamic>>();
  var isLoadingStatus = false.obs;

  @override
  void onInit() {
    super.onInit();
    _repository = PremiumRepository(Get.find<BaseApiService>());

    // Fetch plans and subscription status
    fetchPlans();

    // Fetch status if logged in
    ever(isUserLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        fetchSubscriptionStatus();
      } else {
        subscriptionData.value = null;
      }
    });

    if (isUserLoggedIn.value) {
      fetchSubscriptionStatus();
    }
  }

  Future<void> fetchPlans() async {
    try {
      isLoading.value = true;
      final response = await _repository.getPlans();
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['plans'];
        plans.assignAll(data.map((e) => PlanModel.fromJson(e)).toList());
        if (plans.isNotEmpty) {
          selectPlan(0);
        }
      }
    } catch (e) {
      print("Error fetching plans: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void selectPlan(int index) {
    selectedPlanIndex.value = index;
    isPromoApplied.value = false;
    appliedPromoCode.value = "";
    if (index < plans.length) {
      originalPrice.value = (plans[index].price ?? 0).toDouble();
      discountedPrice.value = originalPrice.value;
      selectedPrice.value = "₹${plans[index].price}";
    }
  }

  Future<void> fetchSubscriptionStatus() async {
    if (!isUserLoggedIn.value) return;
    try {
      isLoadingStatus.value = true;
      final response = await _repository.getSubscriptionStatus();
      if (response != null && response['success'] == true) {
        subscriptionData.value = response['subscription'];
      }
    } catch (e) {
      print("Error fetching subscription status: $e");
    } finally {
      isLoadingStatus.value = false;
    }
  }

  /// 🔹 Apply Promo Code (Local Calculation)
  /// "free ke bad jitna number likhe h utna hi discont ho jana chaiye amount m"
  Future<void> applyPromoCode(String promoCode) async {
    if (plans.isEmpty || selectedPlanIndex.value >= plans.length) return;

    try {
      isApplyingPromo.value = true;
      String code = promoCode.toUpperCase();

      // Extract numeric part from codes like FREE30, WELCOME50, ROCCO50
      final RegExp regExp = RegExp(r'\d+');
      final match = regExp.firstMatch(code);

      if (match != null) {
        double discountValue = double.parse(match.group(0)!);
        isPromoApplied.value = true;
        appliedPromoCode.value = code;

        // Apply FLAT rupee discount based on the number in the code
        discountedPrice.value = originalPrice.value - discountValue;
        if (discountedPrice.value < 0) discountedPrice.value = 0;

        selectedPrice.value = "₹${discountedPrice.value.toStringAsFixed(1)}";

        Get.snackbar("Success", "Promo code applied: ₹$discountValue Discount!",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Invalid Promo Code Format",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      isPromoApplied.value = false;
      appliedPromoCode.value = "";
      discountedPrice.value = originalPrice.value;
      selectedPrice.value = "₹${originalPrice.value}";
    } finally {
      isApplyingPromo.value = false;
    }
  }

  Future<void> subscribeToPlan(String planId, {String? promoCode}) async {
    try {
      isSubscribing.value = true;
      final response = await _repository.subscribeToPlan(planId, promoCode: promoCode ?? (isPromoApplied.value ? appliedPromoCode.value : null));

      if (response != null && response['success'] == true) {
        if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
          Get.back();
        }
        _showStatusDialog(
          title: "Success",
          message: "Successfully plan purchase",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        fetchSubscriptionStatus(); // Refresh status after purchase
      }
    } catch (e) {
      if (Get.isBottomSheetOpen == true || Get.isDialogOpen == true) {
        Get.back();
      }

      String errorMsg = e.toString();
      if (errorMsg.contains("already purchased") || errorMsg.contains("already has an active subscription")) {
        _showStatusDialog(
          title: "Info",
          message: "Already purchased",
          icon: Icons.info_outline,
          iconColor: Colors.blue,
        );
      } else {
        Get.snackbar("Error", errorMsg);
      }
    } finally {
      isSubscribing.value = false;
    }
  }

  Future<void> redeemVoucher(String code) async {
    try {
      isRedeeming.value = true;
      final response = await _repository.redeemVoucher(code);
      if (response != null && response['success'] == true) {
        _showStatusDialog(
          title: "Success",
          message: response['message'] ?? "Voucher redeemed successfully",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        fetchSubscriptionStatus(); // Refresh status
      }
    } catch (e) {
      String errorMsg = e.toString();
      // Handle "Already used" or other specific messages from API
      if (errorMsg.contains("Already used")) {
        Get.snackbar("Info", "This voucher has already been used",
            backgroundColor: Colors.orange, colorText: Colors.white);
      } else {
        Get.snackbar("Error", errorMsg,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } finally {
      isRedeeming.value = false;
    }
  }

  void _showStatusDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(icon, color: iconColor, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        actions: [
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Get.back(),
                child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }

  String formatDate(String? dateStr) {
    if (dateStr == null) return "N/A";
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return "N/A";
    }
  }
}
