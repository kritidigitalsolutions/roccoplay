import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:roccoplay/app/routes/app_pages.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import 'package:roccoplay/view_model/like_dislike_controller/like_dislike_controller.dart';
import 'package:roccoplay/view_model/watchlist_controller/watchlist_controller.dart';

import 'app/routes/app_routes.dart';
import 'data/network/api_network_service.dart';
import 'data/network/base_api_service.dart';
import 'utils/app_session.dart';
import 'utils/notification_service.dart';
import 'view_model/auth_controller/auth_controller.dart';
import 'view_model/primium_controller/premium_controller.dart';
import 'widgets/ad_widget/app_open_ad_helper.dart';
import 'widgets/ad_widget/interstitial_ad_helper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MobileAds.instance.initialize();
  await MetaEventService.instance.activateApp();

  /// Lock orientations to Portrait by default
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  ///  Firebase Init
  await Firebase.initializeApp();
  await FirebaseAnalyticsService.instance.activateApp();

  ///  Background Listener
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  ///  Local Storage
  await GetStorage.init();
  await Hive.initFlutter();
  await Hive.openBox('appBox');

  /// Network Service
  final networkService = NetworkApiService();
  Get.put<BaseApiService>(networkService, permanent: true);

  ///  Token Setup
  String? token = AppSession.getToken();

  if (token != null) {
    networkService.setToken(token);
  }

  ///  Notification Service (DON'T AWAIT ❌)
  Get.put(NotificationService(), permanent: true);

  ///  Controllers
  Get.put(AuthController(), permanent: true);
  Get.put(PremiumController(), permanent: true);
  Get.put(InteractionController(), permanent: true);
  Get.put(WatchlistController(), permanent: true);

  ///  Run App FIRST (IMPORTANT)
  runApp(const MyApp());

  ///  Initialize Notifications AFTER UI LOAD (FIX)
  Future.delayed(const Duration(seconds: 1), () {
    NotificationService.to.init();
  });

  /// 🔥 Ads Preload
  Future.delayed(const Duration(seconds: 2), () {
    AppOpenAdHelper.loadAd();
    InterstitialAdHelper.loadAd();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 🔥 App foreground me aane pe App Open Ad show karo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppOpenAdHelper.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
