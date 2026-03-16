import 'package:get/get_navigation/src/routes/get_route.dart';
import '../../modules/homePages/mainHomepage.dart';
import '../../modules/splash/splashScreen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.home, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()), // GetPage(name: AppRoutes.dramaDetails, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.goPremium, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.castDetails, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.langauge, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.watchList, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.artist, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.profile, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.videoPlayer, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.accountSetting, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.otpPage, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.navbar, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.signIn, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.createProfile, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.manageProfile, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.manageDevice, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.profileSelection, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.setting, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.downloads, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.payment, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.search, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.top10, page: () => SplashScreen()),
    // GetPage(name: AppRoutes.searchWithMic, page: () => SplashScreen()),

  ];
}
