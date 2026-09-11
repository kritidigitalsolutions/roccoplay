import 'package:get/get.dart';
import '../../view/auth/otpPage.dart';
import '../../view/auth/signInPage.dart';
import '../../view/homePages/mainHomepage.dart';
import '../../view/splash/splashScreen.dart';
import '../../view/dramaDetails/dramaDetailsPage.dart';
import '../../view/profile/account_setting.dart';
import '../../view/profile/watchlist.dart';
import '../../view/dramaDetails/cast_crewPage.dart';
import '../../view/notifications/notification_page.dart';
import '../../view/profile/privacy_policy_page.dart';
import '../../view/profile/terms_condition_page.dart';
import '../../view/popUp/redeem_voucher_page.dart';
import '../../view/dramaDetails/topArtistpage.dart';
import '../../view/popUp/search_with_mic.dart';
import '../../view/videoPlayer/video_player.dart';
import '../../view/profile/setting_page.dart';
import '../../view/profile/Rate_your_app.dart';
import '../../view/profile/refund_policy_page.dart';
import '../../view/profile/help_page.dart';
import '../../widgets/catagory_widget.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: AppRoutes.home, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.search, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.goPremium, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.downloads, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.profile, page: () => const MainHomePage()),
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.signIn, page: () => const SignInPage()),
    GetPage(
      name: AppRoutes.otpPage,
      page: () => OtpPage(phoneNumber: Get.arguments['phoneNumber']),
    ),
    GetPage(
      name: AppRoutes.dramaDetails,
      page: () => DramaDetailsPage(
        isSignedIn: Get.find<AuthController>().isLoggedIn.value,
        content: Get.arguments,
      ),
    ),
    GetPage(name: AppRoutes.accountSetting, page: () => const AccountSettingsPage()),
    GetPage(name: AppRoutes.watchList, page: () => const WatchlistPage()),
    GetPage(
      name: AppRoutes.castDetails,
      page: () => CastDetailsPage(
        castName: Get.arguments['name'],
        castImage: Get.arguments['image'],
      ),
    ),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationPage()),
    GetPage(name: AppRoutes.privacyPolicy, page: () => const PrivacyPolicyPage()),
    GetPage(name: AppRoutes.termsAndConditions, page: () => const TermsAndConditionsPage()),
    GetPage(name: AppRoutes.redeemVoucher, page: () => RedeemVoucherPage()),
    GetPage(name: AppRoutes.artist, page: () => TopArtistsPage()),
    GetPage(name: AppRoutes.searchWithMic, page: () => const VoiceListeningPage()),
    GetPage(
      name: AppRoutes.categoryGrid,
      page: () => CategoryGridPage(
        title: Get.arguments['title'],
        content: Get.arguments['content'],
        isSignedIn: Get.find<AuthController>().isLoggedIn.value,
      ),
    ),
    GetPage(
      name: AppRoutes.advancedVideoPlayer,
      page: () => AdvancedVideoPlayer(
        url: Get.arguments['url'],
        title: Get.arguments['title'],
        contentId: Get.arguments['contentId'],
      ),
    ),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    GetPage(name: AppRoutes.review, page: () => const ReviewPage()),
    GetPage(name: AppRoutes.refundPolicy, page: () => const RefundPolicyPage()),
    GetPage(name: AppRoutes.help, page: () => const HelpSupportPage()),
  ];
}
