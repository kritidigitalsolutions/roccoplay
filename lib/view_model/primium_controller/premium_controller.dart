import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  var plans = <PlanModel>[].obs;

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
    if (index < plans.length) {
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

  Future<void> subscribeToPlan(String planId) async {
    try {
      isSubscribing.value = true;
      final response = await _repository.subscribeToPlan(planId);

      if (response != null && response['success'] == true) {
        Get.back(); // Close bottom sheet
        _showStatusDialog(
          title: "Success",
          message: "Successfully plan purchase",
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
        fetchSubscriptionStatus(); // Refresh status after purchase
      }
    } catch (e) {
      Get.back();
      if (e.toString().contains("already purchased") ||
          e.toString().contains("already has an active subscription") ||
          e.toString().contains("400")) {

        _showStatusDialog(
          title: "Info",
          message: "Already purchased",
          icon: Icons.info_outline,
          iconColor: Colors.blue,
        );
      } else {
        Get.snackbar("Error", e.toString());
      }
    } finally {
      isSubscribing.value = false;
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
                  backgroundColor: Colors.pinkAccent,
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
