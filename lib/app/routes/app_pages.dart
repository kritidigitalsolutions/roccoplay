import 'package:get/get.dart';
import '../../modules/homePages/mainHomepage.dart';
import '../../modules/splash/splashScreen.dart';
import '../../modules/auth/signInPage.dart';
import '../../modules/auth/otpPage.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.home, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()),
    GetPage(name: AppRoutes.signIn, page: () => const SignInPage()),
    GetPage(name: AppRoutes.otpPage, page: () => const OtpPage(phoneNumber: '')), // Note: OTP page usually needs phone number
    // GetPage(name: AppRoutes.dramaDetails, page: () => SplashScreen()),
    // ... other routes
  ];
}
