import 'package:get/get.dart';
import '../../utils/app_session.dart';

class PremiumController extends GetxController {
  var selectedPlanIndex = 0.obs;
  var isUserLoggedIn = false.obs;
  var selectedPrice = "₹999".obs;

  final List<Map<String, dynamic>> plans = [
    {
      "name": "Yearly",
      "price": "₹999",
      "duration": "/ Year",
      "features": ["4K Streaming", "No Ads", "4 Screens", "Download Content"]
    },
    {
      "name": "Monthly",
      "price": "₹199",
      "duration": "/ Month",
      "features": ["HD Streaming", "No Ads", "1 Screen"]
    },
    {
      "name": "Others",
      "price": "₹49",
      "duration": "/ Week",
      "features": ["SD Streaming", "Ads included", "1 Screen"]
    },
  ];

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    isUserLoggedIn.value = await AppSession.getLogin();
  }

  void selectPlan(int index) {
    selectedPlanIndex.value = index;
    if (index < plans.length) {
      selectedPrice.value = plans[index]['price'];
    }
  }
}
