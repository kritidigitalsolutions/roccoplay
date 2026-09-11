import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/network/base_api_service.dart';
import '../../utils/app_session.dart';
import '../../utils/constants.dart';
import '../auth_controller/auth_controller.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var isLoggedIn = false.obs;
  var companyInfo = Rxn<Map<String, dynamic>>();
  var isLoadingCompanyInfo = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    fetchCompanyInfo();
    updateIndexFromRoute();
  }

  /// ✅ Synchronize selected index with the current URL route
  void updateIndexFromRoute() {
    String currentRoute = Get.currentRoute;
    if (currentRoute == AppRoutes.home) {
      selectedIndex.value = 0;
    } else if (currentRoute == AppRoutes.search) {
      selectedIndex.value = 1;
    } else if (currentRoute == AppRoutes.goPremium) {
      selectedIndex.value = 2;
    } else if (currentRoute == AppRoutes.downloads) {
      selectedIndex.value = 3;
    } else if (currentRoute == AppRoutes.profile) {
      selectedIndex.value = 4;
    }
  }

  Future<void> fetchCompanyInfo() async {
    try {
      isLoadingCompanyInfo.value = true;
      final apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(AppConstants.companyInfo);
      if (response != null && response['success'] == true) {
        companyInfo.value = response['data'];
      }
    } catch (e) {
      print("Error fetching company info: $e");
    } finally {
      isLoadingCompanyInfo.value = false;
    }
  }

  void checkLoginStatus() async {
    isLoggedIn.value = AppSession.getLogin();
  }

  void onItemTapped(int index) {
    if (selectedIndex.value == index) return;

    selectedIndex.value = index;

    if (kIsWeb) {
      // ✅ Change browser URL according to selected tab (Post-frame to avoid lock)
      SchedulerBinding.instance.addPostFrameCallback((_) {
        switch (index) {
          case 0:
            Get.toNamed(AppRoutes.home);
            break;
          case 1:
            Get.toNamed(AppRoutes.search);
            break;
          case 2:
            Get.toNamed(AppRoutes.goPremium);
            break;
          case 3:
            Get.toNamed(AppRoutes.downloads);
            break;
          case 4:
            Get.toNamed(AppRoutes.profile);
            break;
        }
      });
    }
  }

  void logout() async {
    final authController = Get.find<AuthController>();
    await authController.logout();
    isLoggedIn.value = false;
    selectedIndex.value = 0;
    if (kIsWeb) Get.offAllNamed(AppRoutes.home);
  }
}
