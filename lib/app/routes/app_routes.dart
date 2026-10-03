import 'package:get/get.dart';
import '../../view_model/home_controller/home_controller.dart';

abstract class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const dramaDetails = '/dramaDetails';
  static const goPremium = '/goPremium';
  static const castDetails = '/castDetails';
  static const langauge = '/langauge';
  static const watchList = '/watchList';
  static const artist = '/artist';
  static const profile = '/profile';
  static const videoPlayer = '/VideoPlayer';
  static const accountSetting = '/accountSetting';
  static const otpPage = '/otpPage';
  static const navbar = '/navbar';
  static const signIn = '/signIn';
  static const createProfile = '/createProfile';
  static const manageProfile= '/manageProfile';
  static const manageDevice= '/ manageDevice';
  static const profileSelection= '/profileSelection';
  static const setting = '/setting';
  static const downloads= '/downloads';
  static const payment= '/payment';
  static const search= '/search';
  static const top10= '/top10';
  static const trendingSearches = '/trendingSearches';
  static const searchWithMic= '/searchWithMic';
  static const notifications= '/notifications';
  static const privacyPolicy= '/privacyPolicy';
  static const termsAndConditions= '/termsAndConditions';
  static const redeemVoucher= '/redeemVoucher';
  static const categoryGrid= '/categoryGrid';
  static const advancedVideoPlayer= '/advancedVideoPlayer';
  static const settings= '/settings';
  static const review= '/review';
  static const refundPolicy= '/refundPolicy';
  static const help= '/help';
  static const deleteAccount= '/deleteAccount';

  static DateTime _lastPremiumNav = DateTime(0);

  /// Safe navigation to Subscription/Plans preventing rapid double-taps and duplicate routes
  static void toGoPremium() {
    final now = DateTime.now();
    if (now.difference(_lastPremiumNav).inMilliseconds < 750) return;
    if (Get.currentRoute == goPremium) return;
    _lastPremiumNav = now;

    // If currently on MainHomePage shell routes, switch to Plans tab (index 2) directly
    final currentRoute = Get.currentRoute;
    final isMainShellRoute = currentRoute == home ||
        currentRoute == '/' ||
        currentRoute == search ||
        currentRoute == downloads ||
        currentRoute == profile ||
        currentRoute == navbar;

    if (isMainShellRoute && Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().onItemTapped(2);
      return;
    }

    Get.toNamed(goPremium, preventDuplicates: true);
  }
}
