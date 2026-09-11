import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:roccoplay/utils/service/razorpay_web_service.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import '../../data/models/response_model/plan_response/plan_model.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/premium_repository.dart';
import '../../utils/constants.dart';
import '../../utils/custom_snackbar.dart';
import '../auth_controller/auth_controller.dart';
import '../../view/premium/payment_webview_page.dart';
import '../../view/premium/payment_success_page.dart';

class PremiumController extends GetxController {
  late final PremiumRepository _repository;
  final AuthController _authController = Get.find<AuthController>();
  Razorpay? _razorpay;

  var selectedPlanIndex = 0.obs;
  // Use AuthController's isLoggedIn status instead of local copy
  RxBool get isUserLoggedIn => _authController.isLoggedIn;

  var currentPlatform = (kIsWeb ? "website" : "hinge").obs; // Auto-detect platform

  var selectedPrice = "0".obs;
  var isLoading = true.obs;
  var isSubscribing = false.obs;
  var isRedeeming = false.obs;
  var isApplyingPromo = false.obs;
  
  // Separate lists for App and Website plans
  var appPlans = <PlanModel>[].obs;
  var webPlans = <PlanModel>[].obs;
  
  // Computed property to get plans for current platform
  List<PlanModel> get plans {
    final current = currentPlatform.value;
    if (current == "website") {
      return webPlans.where((p) => p.platform == "website").toList();
    } else {
      // Show plans that are NOT website plans (hinge, app, android, etc.)
      return appPlans.where((p) => p.platform != "website").toList();
    }
  }

  // Promo Code State
  var appliedPromoCode = "".obs;
  var originalPrice = 0.0.obs;
  var discountedPrice = 0.0.obs;
  var isPromoApplied = false.obs;

  // Subscription Status Data
  var appSubscriptionData = Rxn<Map<String, dynamic>>();
  var webSubscriptionData = Rxn<Map<String, dynamic>>();
  
  // Computed property for current subscription data
  Rxn<Map<String, dynamic>> get subscriptionData => 
      currentPlatform.value == "website" ? webSubscriptionData : appSubscriptionData;

  var isLoadingStatus = false.obs;
  var isLoadingGateways = false.obs;
  var paymentGateways = Rxn<Map<String, dynamic>>();

  // ✅ Helper to check if ANY plan is active for current platform
  bool get hasActiveSubscription =>
      subscriptionData.value != null &&
      subscriptionData.value!['status'] == 'active';

  @override
  void onInit() {
    super.onInit();
    _repository = PremiumRepository(Get.find<BaseApiService>());
    
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }

    // Fetch plans for current platform only
    fetchAllPlans();
    fetchPaymentGateways();

    // Fetch status if logged in
    ever(isUserLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        fetchAllSubscriptionStatus();
      } else {
        appSubscriptionData.value = null;
        webSubscriptionData.value = null;
      }
    });

    if (isUserLoggedIn.value) {
      fetchAllSubscriptionStatus();
    }
  }

  Future<void> fetchAllPlans() async {
    isLoading.value = true;
    await fetchPlans(currentPlatform.value);
    isLoading.value = false;
    if (plans.isNotEmpty) {
      selectPlan(0);
    }
  }

  Future<void> fetchPlans(String platform) async {
    try {
      final response = await _repository.getPlans(platform: platform);
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['plans'];
        final planList = data
            .map((e) => PlanModel.fromJson(e))
            .where((p) => platform == "website" ? p.platform == "website" : p.platform != "website")
            .toList();
        if (platform == "website") {
          webPlans.assignAll(planList);
        } else {
          appPlans.assignAll(planList);
        }
      }
    } catch (e) {
      print("Error fetching $platform plans: $e");
    }
  }

  Future<void> fetchPaymentGateways() async {
    try {
      isLoadingGateways.value = true;
      final apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(AppConstants.paymentGateways);
      if (response != null && response['success'] == true) {
        paymentGateways.value = response['gateways'];
      }
    } catch (e) {
      print("Error fetching gateways: $e");
    } finally {
      isLoadingGateways.value = false;
    }
  }

  void switchPlatform(String platform) {
    if (currentPlatform.value == platform) return;
    currentPlatform.value = platform;
    selectPlan(0);
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

  Future<void> fetchAllSubscriptionStatus() async {
    if (!isUserLoggedIn.value) return;
    isLoadingStatus.value = true;
    await fetchSubscriptionStatus(currentPlatform.value);
    isLoadingStatus.value = false;
  }

  Future<void> fetchSubscriptionStatus(String platform) async {
    try {
      final response = await _repository.getSubscriptionStatus(platform: platform);
      if (response != null && response['success'] == true) {
        if (platform == "website") {
          webSubscriptionData.value = response['subscription'];
        } else {
          appSubscriptionData.value = response['subscription'];
        }
      }
    } catch (e) {
      print("Error fetching $platform subscription status: $e");
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
      String phone = _authController.userData.value?['phone'] ?? '';
      phone = phone.replaceAll(RegExp(r'\D'), '');
      if (phone.length > 10) {
        phone = phone.substring(phone.length - 10);
      }

      Map<String, dynamic> body = {
        "planId": planId,
        "phone": phone,
        "email": _authController.userData.value?['email'] ?? '',
        "platform": currentPlatform.value,
      };
      if (isPromoApplied.value) {
        body["promoCode"] = appliedPromoCode.value;
      }

      // 1. Create Order on Backend
      final response = await apiService.postApi(
        AppConstants.createOrder,
        body,
      );

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

        if (kIsWeb) {
          RazorpayWebService.checkout(
            options: options,
            onSuccess: (paymentId, orderId, signature) {
              _verifyRazorpayPayment(
                paymentId: paymentId,
                orderId: orderId,
                signature: signature,
              );
            },
            onFailure: (errorMessage) {
              isSubscribing.value = false;
              CustomSnackbar.show(
                title: "Payment Failed",
                message: errorMessage,
                isError: true,
              );
            },
          );
        } else {
          _razorpay?.open(options);
        }
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
    _verifyRazorpayPayment(
      paymentId: response.paymentId ?? "",
      orderId: response.orderId ?? "",
      signature: response.signature ?? "",
    );
  }

  Future<void> _verifyRazorpayPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      final String planId = plans[selectedPlanIndex.value].id;
      var amount = plans[selectedPlanIndex.value].price;

      // 2. Verify Payment on Backend
      final verifyResponse = await apiService.postApi(
        AppConstants.verifyPayment,
        {
          "razorpay_order_id": orderId,
          "razorpay_payment_id": paymentId,
          "razorpay_signature": signature,
          "planId": planId,
        },
      );

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

        fetchSubscriptionStatus(currentPlatform.value);
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

        // If gateways are not loaded, try fetching again
        if (paymentGateways.value == null) {
          await fetchPaymentGateways();
        }

        isSubscribing.value = false;

        if (paymentGateways.value != null) {
          final gateways = paymentGateways.value!;
          
          final enabledGateways = [];
          if (gateways['razorpay']?['enabled'] == true) enabledGateways.add('razorpay');
          if (gateways['zaakpay']?['enabled'] == true) enabledGateways.add('zaakpay');
          if (gateways['hdfc']?['enabled'] == true) enabledGateways.add('hdfc');
          if (gateways['sabpaisa']?['enabled'] == true) enabledGateways.add('sabpaisa');

          if (enabledGateways.isNotEmpty) {
            _showGatewaySelectionBottomSheet(planId, gateways: gateways);
          } else {
            CustomSnackbar.show(
              title: "Error",
              message: "No active payment gateways available",
              isError: true,
            );
          }
        } else {
          // Fallback to Razorpay or show error
          CustomSnackbar.show(
            title: "Error",
            message: "Unable to load payment methods. Please try again.",
            isError: true,
          );
        }
      } catch (e) {
        isSubscribing.value = false;
        CustomSnackbar.show(
          title: "Error",
          message: "Something went wrong while fetching payment methods",
          isError: true,
        );
      }
    } else {
      try {
        isSubscribing.value = true;
        final response = await _repository.subscribeToPlan(
          planId,
          promoCode:
              promoCode ??
              (isPromoApplied.value ? appliedPromoCode.value : null),
          platform: currentPlatform.value,
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
          fetchSubscriptionStatus(currentPlatform.value);
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

  /// 🔹 Helper for Web Payment Status
  void _showWebPaymentStatusDialog({
    required String orderId,
    required String planId,
    required Function(String, String) onCheckStatus,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF16161F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.pinkAccent),
            SizedBox(width: 10),
            Text("Payment Started",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          "We've opened the payment gateway in a new tab. Once you complete the payment, come back here and click the button below to activate your plan.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Get.back();
                  onCheckStatus(orderId, planId);
                },
                child: const Text(
                  "Check Payment Status",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// 🔹 Start Zaakpay Payment Process
  Future<void> startZaakpayPayment(String planId) async {
    try {
      if (Get.isBottomSheetOpen == true) Get.back();

      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      // Prepare request body with promo code if applied
      String phone = _authController.userData.value?['phone'] ?? '';
      phone = phone.replaceAll(RegExp(r'\D'), '');
      if (phone.length > 10) {
        phone = phone.substring(phone.length - 10);
      }

      Map<String, dynamic> body = {
        "planId": planId,
        "phone": phone,
        "email": _authController.userData.value?['email'] ?? '',
        "name": _authController.userData.value?['name'] ?? '',
        "platform": currentPlatform.value,
      };
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

          if (kIsWeb) {
            // Launch Zaakpay in new tab
            final Uri uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              _showWebPaymentStatusDialog(
                orderId: orderId,
                planId: planId,
                onCheckStatus: verifyZaakpayPayment,
              );
            } else {
              CustomSnackbar.show(
                title: "Error",
                message: "Could not open payment page",
                isError: true,
              );
            }
          } else {
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

        fetchSubscriptionStatus(currentPlatform.value);
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

      // Prepare request body (Strictly planId and promoCode as per spec for HDFC)
      Map<String, dynamic> body = {
        "planId": planId,
      };
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

        if (paymentUrl != null && orderId != null) {
          if (params != null && params.containsKey('returnUrl')) {
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

          if (kIsWeb) {
            // Launch HDFC in new tab
            final Uri uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              _showWebPaymentStatusDialog(
                orderId: orderId,
                planId: planId,
                onCheckStatus: verifyHdfcPayment,
              );
            } else {
              CustomSnackbar.show(
                title: "Error",
                message: "Could not open payment page",
                isError: true,
              );
            }
          } else {
            // Open HDFC WebView Page
            final result = await Get.to(
              () => PaymentWebViewPage(
                paymentUrl: paymentUrl,
                orderId: orderId,
                params: params,
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

  /// 🔹 Start SabPaisa Payment Process
  Future<void> startSabPaisaPayment(String planId) async {
    try {
      if (Get.isBottomSheetOpen == true) Get.back();

      isSubscribing.value = true;
      final apiService = Get.find<BaseApiService>();

      // Prepare request body with promo code if applied
      String phone = _authController.userData.value?['phone'] ?? '';
      // Remove any non-digit characters and handle +91 prefix
      phone = phone.replaceAll(RegExp(r'\D'), '');
      if (phone.length > 10) {
        phone = phone.substring(phone.length - 10);
      }

      Map<String, dynamic> body = {
        "planId": planId,
        "phone": phone,
        "email": _authController.userData.value?['email'] ?? '',
        "name": _authController.userData.value?['name'] ?? '',
        "platform": currentPlatform.value,
      };
      if (isPromoApplied.value) {
        body["promoCode"] = appliedPromoCode.value;
      }

      // 1. Initiate SabPaisa Payment on Backend
      final response = await apiService.postApi(
        AppConstants.initiateSabPaisa,
        body,
      );

      if (response != null && response['success'] == true) {
        final paymentUrl = (response['paymentUrl'] ?? response['checkoutUrl']) as String?;
        final orderId = response['orderId'] as String?;
        final params = response['params'] as Map<String, dynamic>?;

        if (paymentUrl != null && orderId != null) {
          if (kIsWeb) {
            // Launch SabPaisa in new tab
            final Uri uri = Uri.parse(paymentUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              _showWebPaymentStatusDialog(
                orderId: orderId,
                planId: planId,
                onCheckStatus: verifySabPaisaPayment,
              );
            } else {
              CustomSnackbar.show(
                title: "Error",
                message: "Could not open payment page",
                isError: true,
              );
            }
          } else {
            // Open SabPaisa WebView Page
            final result = await Get.to(
              () => PaymentWebViewPage(
                paymentUrl: paymentUrl,
                orderId: orderId,
                params: params,
              ),
            );

            if (result == true) {
              await verifySabPaisaPayment(orderId, planId);
            } else {
              CustomSnackbar.show(
                title: "Payment Cancelled",
                message: "Payment was not completed",
                isError: true,
              );
            }
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

  /// 🔹 Verify SabPaisa Payment on Backend (with retry logic)
  Future<void> verifySabPaisaPayment(String orderId, String planId) async {
    isSubscribing.value = true;
    final apiService = Get.find<BaseApiService>();

    int maxAttempts = 3;
    int delaySeconds = 2;
    dynamic verifyResponse;
    bool isSuccess = false;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        debugPrint(
          "🔄 SabPaisa verification attempt $attempt of $maxAttempts for Order: $orderId",
        );
        verifyResponse = await apiService.getApi(
          AppConstants.sabPaisaStatus(orderId),
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
        final plan = plans.isNotEmpty && selectedPlanIndex.value < plans.length
            ? plans[selectedPlanIndex.value]
            : null;
        final num amount =
            plan?.price ?? (verifyResponse['data']?['amount'] ?? 0);
        final planName = plan?.name ?? "VIP Subscription";
        final transactionId = verifyResponse['data']?['transactionId'] ??
            verifyResponse['data']?['bankRefNo'] ??
            verifyResponse['transactionId']?.toString();

        MetaEventService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'INR',
        );
        FirebaseAnalyticsService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'INR',
        );

        fetchSubscriptionStatus(currentPlatform.value);

        Get.off(
          () => PaymentSuccessPage(
            orderId: orderId,
            amount: amount,
            planName: planName,
            paymentMode: "SabPaisa",
            transactionId: transactionId,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        CustomSnackbar.show(
          title: "Payment Failed",
          message: verifyResponse?['message'] ??
              "Payment verification could not be confirmed.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("SabPaisa verification final failed: $e");
      CustomSnackbar.show(
        title: "Payment Failed",
        message: "Something went wrong during verification",
        isError: true,
      );
    } finally {
      isSubscribing.value = false;
    }
  }

  /// 🔹 Helper to show full-screen verification loader
  void _showHdfcVerificationDialog() {
    if (Get.isDialogOpen != true) {
      Get.dialog(
        PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: const Color(0xFF16161F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.pinkAccent),
                  const SizedBox(height: 20),
                  const Text(
                    "Verifying Payment...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Confirming transaction with HDFC Bank in real-time. Please do not close the app.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  void _closeHdfcVerificationDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  /// 🔹 Verify HDFC Payment on Backend (with retry logic)
  Future<void> verifyHdfcPayment(String orderId, String planId) async {
    isSubscribing.value = true;
    _showHdfcVerificationDialog();
    final apiService = Get.find<BaseApiService>();

    int maxAttempts = 4;
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

    _closeHdfcVerificationDialog();

    try {
      if (isSuccess && verifyResponse != null) {
        final plan = plans.isNotEmpty && selectedPlanIndex.value < plans.length
            ? plans[selectedPlanIndex.value]
            : null;
        final num amount = plan?.price ?? (verifyResponse['data']?['amount'] ?? 0);
        final planName = plan?.name ?? "VIP Subscription";
        final transactionId = verifyResponse['data']?['transactionId'] ??
            verifyResponse['data']?['bankRefNo'] ??
            verifyResponse['transactionId']?.toString();

        MetaEventService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'INR',
        );
        FirebaseAnalyticsService.instance.paymentComplete(
          planId: planId,
          amount: amount.toDouble(),
          currency: 'INR',
        );

        fetchSubscriptionStatus(currentPlatform.value);

        // 🎯 Navigate directly to dedicated Real-Time Payment Success Page
        Get.off(
          () => PaymentSuccessPage(
            orderId: orderId,
            amount: amount,
            planName: planName,
            paymentMode: "HDFC Bank (SmartGateway)",
            transactionId: transactionId,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        CustomSnackbar.show(
          title: "Payment Failed",
          message:
              verifyResponse?['message'] ??
              "Payment verification could not be confirmed. Please check your account or contact support.",
          isError: true,
        );
      }
    } catch (e) {
      debugPrint("HDFC verification final failed: $e");
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
    final isSabPaisaEnabled = gateways['sabpaisa']?['enabled'] == true;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F0F15), // Solid dark background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
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

            /// Gateway Option: Razorpay
            if (isRazorpayEnabled) ...[
              _buildGatewayTile(
                name: gateways['razorpay']?['name'] ?? "Razorpay",
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

            /// Gateway Option: HDFC Bank (SmartGateway)
            if (isHdfcEnabled) ...[
              _buildGatewayTile(
                name: gateways['hdfc']?['name'] ?? "HDFC Bank (SmartGateway)",
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
                name: gateways['zaakpay']?['name'] ?? "Zaakpay",
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

            /// Gateway Option: SabPaisa
            if (isSabPaisaEnabled) ...[
              _buildGatewayTile(
                name: gateways['sabpaisa']?['name'] ?? "SabPaisa",
                description: "UPI, Cards, Net Banking",
                icon: Icons.account_balance_wallet,
                gradientColors: [Colors.orange, Colors.deepOrange],
                onTap: () {
                  Get.back();
                  startSabPaisaPayment(planId);
                },
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7), // Dim the background
      enterBottomSheetDuration: const Duration(milliseconds: 300),
      exitBottomSheetDuration: const Duration(milliseconds: 300),
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
        fetchSubscriptionStatus(currentPlatform.value);
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

  @override
  void onClose() {
    _razorpay?.clear();
    super.onClose();
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
