import 'package:get/get.dart';
import '../../data/network/base_api_service.dart';
import '../../utils/app_session.dart';
import '../../utils/constants.dart';
import '../auth_controller/auth_controller.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  var isLoggedIn = false.obs;
  var companyInfo = Rxn<Map<String, dynamic>>();
  var isLoadingCompanyInfo = false.obs;

  final List<String> webSeriesImages = [
    "assets/images/taskaree.jpg",
    "assets/images/sahid_teri_bato.jpg",
    "assets/images/farzi.jpg",
    "assets/images/khaki.webp",
    "assets/images/kota_factory.jpg",
    "assets/images/asur.webp",
    "assets/images/asur2.jpeg",
  ];

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    fetchCompanyInfo();
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
    selectedIndex.value = index;
  }

  void logout() async {
    final authController = Get.find<AuthController>();
    await authController.logout();
    isLoggedIn.value = false;
    selectedIndex.value = 0;
  }
}
