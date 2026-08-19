import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/plan_response/plan_model.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/premium_repository.dart';
import '../../utils/constants.dart';
import '../../utils/custom_snackbar.dart';
import '../auth_controller/auth_controller.dart';
import '../../view/premium/payment_webview_page.dart';

class PremiumController extends GetxController {
  late final PremiumRepository _repository;
  final AuthController _authController = Get.find<AuthController>();
  late Razorpay _razorpay;

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

  // ✅ Helper to check if ANY plan is active
  bool get hasActiveSubscription =>
      subscriptionData.value != null &&
      subscriptionData.value!['status'] == 'active';

  @override
  void onInit() {
    super.onInit();
    _repository = PremiumRepository(Get.find<BaseApiService>());
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

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

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
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
      originalPrice.value = (plans[index].price).toDouble();
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

  /// 🔹 Start Payment Process (Triggered when user clicks Continue)
  Future<void> startPayment(String planId) async {
    // ✅ Check if already has an active plan
    if (hasActiveSubscription) {
      CustomSnackbar.show(title: "Info", message: "Already Purchased");
      return;
    }

    try {
      // ✅ Close bottom sheet if open before starting payment
      if (Get.isBottomSheetOpen == true) Get.back();

      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      // Prepare request body with promo code if applied
      Map<String, dynamic> body = {"planId": planId};
      if (isPromoApplied.value) {
        body["promoCode"] = appliedPromoCode.value;
      }

      // 1. Create Order on Backend
      final response = await apiService.postApi(AppConstants.createOrder, body);

      MetaEventService.instance.subscriptionStart(
        planId: planId,
        amount: response['finalAmount'],
        currency: 'IN',
      );
      FirebaseAnalyticsService.instance.subscriptionStart(
        planId: planId,
        amount: response['finalAmount'],
        currency: 'IN',
      );

      if (response != null && response['success'] == true) {
        var options = {
          'key': response['key'],
          'amount': response['order']['amount'],
          'name': 'Rocco Play',
          'order_id': response['order']['id'],
          'description': 'Subscription Plan',
          'prefill': {
            'contact': _authController.userData.value?['phone'] ?? '',
            'email': _authController.userData.value?['email'] ?? '',
          },
          'notes': {
            'planId': planId,
            'promoCode': isPromoApplied.value ? appliedPromoCode.value : "",
          },
        };

        _razorpay.open(options);
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("already has an active subscription") ||
          errorMsg.contains("already purchased")) {
        CustomSnackbar.show(title: "Info", message: "Already Purchased");
      } else {
        print(e.toString());
        CustomSnackbar.show(
          title: "Payment Failed",
          message: "Something went wrong",
          isError: true,
        );
      }
    } finally {
      isSubscribing.value = false;
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      final String planId = plans[selectedPlanIndex.value].id;
      var amount = plans[selectedPlanIndex.value].price;

      // 2. Verify Payment on Backend
      final verifyResponse = await apiService
          .postApi(AppConstants.verifyPayment, {
            "razorpay_order_id": response.orderId,
            "razorpay_payment_id": response.paymentId,
            "razorpay_signature": response.signature,
            "planId": planId,
          });

      if (verifyResponse != null && verifyResponse['success'] == true) {
        MetaEventService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'IN',
        );
        FirebaseAnalyticsService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'IN',
        );
        CustomSnackbar.show(
          title: "Success",
          message: "Payment Success",
          isSuccess: true,
        );

        fetchSubscriptionStatus();
      }
    } catch (e) {
      CustomSnackbar.show(
        title: "Payment Failed",
        message: "Something went wrong",
        isError: true,
      );
    } finally {
      isSubscribing.value = false;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    isSubscribing.value = false;
    CustomSnackbar.show(
      title: "Payment Failed",
      message: "Payment Failed",
      isError: true,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    CustomSnackbar.show(
      title: "External Wallet",
      message: "Wallet: ${response.walletName}",
    );
  }

  /// 🔹 Apply Code Logic
  Future<void> applyPromoCode(String promoCode) async {
    if (plans.isEmpty || selectedPlanIndex.value >= plans.length) return;

    try {
      isApplyingPromo.value = true;
      String code = promoCode.toUpperCase();

      final RegExp regExp = RegExp(r'\d+');
      final match = regExp.firstMatch(code);

      if (match != null) {
        double numericValue = double.parse(match.group(0)!);
        isPromoApplied.value = true;
        appliedPromoCode.value = code;

        // Check if it's a Voucher/Flat discount or a Percentage Promo
        if (code.contains("VOUCH") || code.contains("FLAT")) {
          // ➖ VOUCHER: Implement "-" Flat Calculations
          discountedPrice.value = originalPrice.value - numericValue;
          if (discountedPrice.value < 0) discountedPrice.value = 0;

          CustomSnackbar.show(
            title: "Success",
            message: "Voucher applied: ₹$numericValue Flat Off!",
            isSuccess: true,
          );
        } else {
          // 🏷️ PROMO CODE: Implement "%" Percentage Calculations
          double discountAmount = (originalPrice.value * numericValue) / 100;
          discountedPrice.value = originalPrice.value - discountAmount;
          if (discountedPrice.value < 0) discountedPrice.value = 0;

          CustomSnackbar.show(
            title: "Success",
            message: "Promo applied: $numericValue% Discount Off!",
            isSuccess: true,
          );
        }

        selectedPrice.value = "₹${discountedPrice.value.toStringAsFixed(1)}";
      } else {
        CustomSnackbar.show(
          title: "Error",
          message: "Invalid Code Format",
          isError: true,
        );
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
    if (hasActiveSubscription) {
      CustomSnackbar.show(title: "Info", message: "Already Purchased");
      return;
    }

    // If it's a paid plan, fetch payment gateways and choose/select.
    if (discountedPrice.value > 0) {
      try {
        isSubscribing.value = true;
        final apiService = Get.find<BaseApiService>();
        final response = await apiService.getApi(AppConstants.paymentGateways);

        isSubscribing.value = false;

        if (response != null && response['success'] == true) {
          final gateways = response['gateways'] as Map<String, dynamic>? ?? {};
          final isRazorpayEnabled = gateways['razorpay']?['enabled'] == true;
          final isZaakpayEnabled = gateways['zaakpay']?['enabled'] == true;
          final isHdfcEnabled = gateways['hdfc']?['enabled'] == true;

          final enabledGateways = [];
          if (isRazorpayEnabled) enabledGateways.add('razorpay');
          if (isZaakpayEnabled) enabledGateways.add('zaakpay');
          if (isHdfcEnabled) enabledGateways.add('hdfc');

          if (enabledGateways.length > 1) {
            _showGatewaySelectionBottomSheet(planId, gateways: gateways);
          } else if (enabledGateways.length == 1) {
            final activeGateway = enabledGateways.first;
            if (activeGateway == 'zaakpay') {
              startZaakpayPayment(planId);
            } else if (activeGateway == 'hdfc') {
              startHdfcPayment(planId);
            } else {
              startPayment(planId);
            }
          } else {
            CustomSnackbar.show(
              title: "Error",
              message: "No active payment gateways available",
              isError: true,
            );
          }
        } else {
          // Fallback to Razorpay if API returns error
          startPayment(planId);
        }
      } catch (e) {
        isSubscribing.value = false;
        // Fallback to Razorpay if API call fails
        startPayment(planId);
      }
    } else {
      try {
        isSubscribing.value = true;
        final response = await _repository.subscribeToPlan(
          planId,
          promoCode:
              promoCode ??
              (isPromoApplied.value ? appliedPromoCode.value : null),
        );

        if (response != null && response['success'] == true) {
          MetaEventService.instance.paymentComplete(
            planId: planId,
            amount: 0.0,
            currency: 'INR',
          );
          FirebaseAnalyticsService.instance.paymentComplete(
            planId: planId,
            amount: 0.0,
            currency: 'INR',
          );
          CustomSnackbar.show(
            title: "Success",
            message: "Payment Success",
            isSuccess: true,
          );
          fetchSubscriptionStatus();
        }
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains("already has an active subscription") ||
            errorMsg.contains("already purchased")) {
          CustomSnackbar.show(title: "Info", message: "Already Purchased");
        } else {
          CustomSnackbar.show(
            title: "Payment Failed",
            message: "Something went wrong",
            isError: true,
          );
        }
      } finally {
        isSubscribing.value = false;
      }
    }
  }

  /// 🔹 Start Zaakpay Payment Process
  Future<void> startZaakpayPayment(String planId) async {
    try {
      if (Get.isBottomSheetOpen == true) Get.back();

      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      // Prepare request body with promo code if applied
      Map<String, dynamic> body = {"planId": planId};
      if (isPromoApplied.value) {
        body["promoCode"] = appliedPromoCode.value;
      }

      // 1. Initiate Zaakpay Payment on Backend
      final response = await apiService.postApi(
        AppConstants.initiateZaakpay,
        body,
      );

      if (response != null && response['success'] == true) {
        final paymentUrl = response['paymentUrl'] as String?;
        final orderId = response['orderId'] as String?;
        var params = response['params'] as Map<String, dynamic>?;

        if (paymentUrl != null && orderId != null && params != null) {
          if (params.containsKey('returnUrl')) {
            String returnUrl = params['returnUrl'] ?? '';
            if (returnUrl.contains('localhost')) {
              try {
                final uri = Uri.parse(AppConstants.baseUrl);
                final authority = uri.authority;
                returnUrl = returnUrl.replaceAll(
                  RegExp(r'localhost(:\d+)?'),
                  authority,
                );

                params = Map<String, dynamic>.from(params);
                params['returnUrl'] = returnUrl;
                debugPrint("🔄 Patched returnUrl for development: $returnUrl");
              } catch (e) {
                debugPrint("Error patching returnUrl: $e");
              }
            }
          }

          // Open Zaakpay WebView Page
          final result = await Get.to(
            () => PaymentWebViewPage(
              paymentUrl: paymentUrl,
              orderId: orderId,
              params: params!,
            ),
          );

          if (result == true) {
            // WebView redirection callback completed, now check status from server
            await verifyZaakpayPayment(orderId, planId);
          } else {
            CustomSnackbar.show(
              title: "Payment Cancelled",
              message: "Payment was not completed",
              isError: true,
            );
          }
        } else {
          CustomSnackbar.show(
            title: "Error",
            message: "Invalid response from server",
            isError: true,
          );
        }
      } else {
        CustomSnackbar.show(
          title: "Error",
          message: response?['message'] ?? "Something went wrong",
          isError: true,
        );
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("already has an active subscription") ||
          errorMsg.contains("already purchased")) {
        CustomSnackbar.show(title: "Info", message: "Already Purchased");
      } else {
        print(e.toString());
        CustomSnackbar.show(
          title: "Payment Failed",
          message: "Something went wrong",
          isError: true,
        );
      }
    } finally {
      isSubscribing.value = false;
    }
  }

  /// 🔹 Verify Zaakpay Payment on Backend (with retry logic)
  Future<void> verifyZaakpayPayment(String orderId, String planId) async {
    isSubscribing.value = true;
    final apiService = Get.find<BaseApiService>();

    int maxAttempts = 3;
    int delaySeconds = 2;
    dynamic verifyResponse;
    bool isSuccess = false;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
          "🔄 Zaakpay verification attempt $attempt of $maxAttempts for Order: $orderId",
        );
        verifyResponse = await apiService.getApi(
          AppConstants.zaakpayStatus(orderId),
        );

        if (verifyResponse != null && verifyResponse['success'] == true) {
          isSuccess = true;
          break;
        }
      } catch (e) {
        debugPrint("⚠️ Attempt $attempt failed: $e");
        if (attempt == maxAttempts) {
          verifyResponse = null;
        }
      }

      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    try {
      if (isSuccess && verifyResponse != null) {
        final amount = plans[selectedPlanIndex.value].price;

        MetaEventService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'IN',
        );
        FirebaseAnalyticsService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'IN',
        );

        CustomSnackbar.show(
          title: "Success",
          message: "Payment Success",
          isSuccess: true,
        );

        fetchSubscriptionStatus();
      } else {
        CustomSnackbar.show(
          title: "Payment Failed",
          message:
              verifyResponse?['message'] ??
              "Payment verification failed after $maxAttempts attempts",
          isError: true,
        );
      }
    } catch (e) {
      print("Zaakpay verification final failed: $e");
      CustomSnackbar.show(
        title: "Payment Failed",
        message: "Something went wrong during verification",
        isError: true,
      );
    } finally {
      isSubscribing.value = false;
    }
  }

  /// 🔹 Start HDFC Payment Process
  Future<void> startHdfcPayment(String planId) async {
    try {
      if (Get.isBottomSheetOpen == true) Get.back();

      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      // Prepare request body with promo code if applied
      Map<String, dynamic> body = {"planId": planId};
      if (isPromoApplied.value) {
        body["promoCode"] = appliedPromoCode.value;
      }

      // 1. Initiate HDFC Payment on Backend
      final response = await apiService.postApi(
        AppConstants.initiateHdfc,
        body,
      );

      if (response != null && response['success'] == true) {
        final paymentUrl = response['paymentUrl'] as String?;
        final orderId = response['orderId'] as String?;
        var params = response['params'] as Map<String, dynamic>?;

        if (paymentUrl != null && orderId != null && params != null) {
          if (params.containsKey('returnUrl')) {
            String returnUrl = params['returnUrl'] ?? '';
            if (returnUrl.contains('localhost')) {
              try {
                final uri = Uri.parse(AppConstants.baseUrl);
                final authority = uri.authority;
                returnUrl = returnUrl.replaceAll(
                  RegExp(r'localhost(:\d+)?'),
                  authority,
                );

                params = Map<String, dynamic>.from(params);
                params['returnUrl'] = returnUrl;
                debugPrint(
                  "🔄 Patched HDFC returnUrl for development: $returnUrl",
                );
              } catch (e) {
                debugPrint("Error patching HDFC returnUrl: $e");
              }
            }
          }

          // Open HDFC WebView Page
          final result = await Get.to(
            () => PaymentWebViewPage(
              paymentUrl: paymentUrl,
              orderId: orderId,
              params: params!,
            ),
          );

          if (result == true) {
            // WebView redirection callback completed, now check status from server
            await verifyHdfcPayment(orderId, planId);
          } else {
            CustomSnackbar.show(
              title: "Payment Cancelled",
              message: "Payment was not completed",
              isError: true,
            );
          }
        } else {
          CustomSnackbar.show(
            title: "Error",
            message: "Invalid response from server",
            isError: true,
          );
        }
      } else {
        CustomSnackbar.show(
          title: "Error",
          message: response?['message'] ?? "Something went wrong",
          isError: true,
        );
      }
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains("already has an active subscription") ||
          errorMsg.contains("already purchased")) {
        CustomSnackbar.show(title: "Info", message: "Already Purchased");
      } else {
        print(e.toString());
        CustomSnackbar.show(
          title: "Payment Failed",
          message: "Something went wrong",
          isError: true,
        );
      }
    } finally {
      isSubscribing.value = false;
    }
  }

  /// 🔹 Verify HDFC Payment on Backend (with retry logic)
  Future<void> verifyHdfcPayment(String orderId, String planId) async {
    isSubscribing.value = true;
    final apiService = Get.find<BaseApiService>();

    int maxAttempts = 3;
    int delaySeconds = 2;
    dynamic verifyResponse;
    bool isSuccess = false;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
          "🔄 HDFC verification attempt $attempt of $maxAttempts for Order: $orderId",
        );
        verifyResponse = await apiService.getApi(
          AppConstants.hdfcStatus(orderId),
        );

        if (verifyResponse != null && verifyResponse['success'] == true) {
          isSuccess = true;
          break;
        }
      } catch (e) {
        debugPrint("⚠️ Attempt $attempt failed: $e");
        if (attempt == maxAttempts) {
          verifyResponse = null;
        }
      }

      if (attempt < maxAttempts) {
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    try {
      if (isSuccess && verifyResponse != null) {
        final amount = plans[selectedPlanIndex.value].price;

        MetaEventService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'IN',
        );
        FirebaseAnalyticsService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'IN',
        );

        CustomSnackbar.show(
          title: "Success",
          message: "Payment Success",
          isSuccess: true,
        );

        fetchSubscriptionStatus();
      } else {
        CustomSnackbar.show(
          title: "Payment Failed",
          message:
              verifyResponse?['message'] ??
              "Payment verification failed after $maxAttempts attempts",
          isError: true,
        );
      }
    } catch (e) {
      print("HDFC verification final failed: $e");
      CustomSnackbar.show(
        title: "Payment Failed",
        message: "Something went wrong during verification",
        isError: true,
      );
    } finally {
      isSubscribing.value = false;
    }
  }

  /// 🔹 Selection Bottom Sheet for Payment Gateways
  void _showGatewaySelectionBottomSheet(
    String planId, {
    required Map<String, dynamic> gateways,
  }) {
    final isRazorpayEnabled = gateways['razorpay']?['enabled'] == true;
    final isZaakpayEnabled = gateways['zaakpay']?['enabled'] == true;
    final isHdfcEnabled = gateways['hdfc']?['enabled'] == true;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[950],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.pinkAccent.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// 🔹 Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const Text(
              "Select Payment Method",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Choose your preferred gateway to complete the purchase safely.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),

            /// Gateway Option: HDFC Bank (SmartGateway)
            if (isHdfcEnabled) ...[
              _buildGatewayTile(
                name: "HDFC Bank (SmartGateway)",
                description: "Powered by HDFC SmartGateway",
                icon: Icons.account_balance,
                gradientColors: [Colors.blue[700]!, Colors.tealAccent],
                onTap: () {
                  Get.back();
                  startHdfcPayment(planId);
                },
              ),
              const SizedBox(height: 16),
            ],

            /// Gateway Option: Zaakpay
            if (isZaakpayEnabled) ...[
              _buildGatewayTile(
                name: "Zaakpay",
                description: "Cards, Net Banking, Wallets",
                icon: Icons.security,
                gradientColors: [Colors.deepPurple, Colors.purpleAccent],
                onTap: () {
                  Get.back();
                  startZaakpayPayment(planId);
                },
              ),
              const SizedBox(height: 16),
            ],

            /// Gateway Option: Razorpay
            if (isRazorpayEnabled) ...[
              _buildGatewayTile(
                name: "Razorpay",
                description: "UPI, Cards, Wallets & Net Banking",
                icon: Icons.payment,
                gradientColors: [Colors.blue, Colors.indigoAccent],
                onTap: () {
                  Get.back();
                  startPayment(planId);
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildGatewayTile({
    required String name,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> redeemVoucher(String code) async {
    try {
      isRedeeming.value = true;
      final response = await _repository.redeemVoucher(code);
      if (response != null && response['success'] == true) {
        final planId =
            response['planId'] ??
            response['plan_id'] ??
            response['data']?['planId'] ??
            'voucher_redeem';
        final double amount =
            double.tryParse((response['amount'] ?? 0.0).toString()) ?? 0.0;

        MetaEventService.instance.paymentComplete(
          planId: planId.toString(),
          amount: amount,
          currency: 'INR',
        );
        FirebaseAnalyticsService.instance.paymentComplete(
          planId: planId.toString(),
          amount: amount,
          currency: 'INR',
        );

        CustomSnackbar.show(
          title: "Success",
          message: "Redeemed successfully",
          isSuccess: true,
        );
        fetchSubscriptionStatus();
      }
    } catch (e) {
      CustomSnackbar.show(
        title: "Error",
        message: "Something went wrong",
        isError: true,
      );
    } finally {
      isRedeeming.value = false;
    }
  }

  // void _showStatusDialog({
  //   required String title,
  //   required String message,
  //   required IconData icon,
  //   required Color iconColor,
  // }) {
  //   Get.dialog(
  //     AlertDialog(
  //       backgroundColor: Colors.grey[900],
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: Icon(icon, color: iconColor, size: 60),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Text(
  //             title,
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontSize: 22,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //           const SizedBox(height: 10),
  //           Text(
  //             message,
  //             textAlign: TextAlign.center,
  //             style: const TextStyle(color: Colors.white70, fontSize: 16),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         Center(
  //           child: SizedBox(
  //             width: double.infinity,
  //             child: ElevatedButton(
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: AppColors.buttonColor,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12),
  //                 ),
  //               ),
  //               onPressed: () => Get.back(),
  //               child: const Text(
  //                 "OK",
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
