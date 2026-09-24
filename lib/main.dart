import 'dart:io';
import 'dart:ui';
import 'package:roccoplay/utils/network_overrides.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:roccoplay/app/routes/app_pages.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import 'package:roccoplay/view/homePages/mainHomepage.dart';
import 'package:roccoplay/view_model/like_dislike_controller/like_dislike_controller.dart';
import 'package:roccoplay/view_model/watchlist_controller/watchlist_controller.dart';

import 'package:roccoplay/view_model/home_controller/home_controller.dart';

import 'app/routes/app_routes.dart';
import 'app/theme/app_colors.dart';
import 'data/network/api_network_service.dart';
import 'data/network/base_api_service.dart';
import 'utils/app_session.dart';
import 'utils/notification_service.dart';
import 'view_model/auth_controller/auth_controller.dart';
import 'view_model/primium_controller/premium_controller.dart';
import 'widgets/ad_widget/app_open_ad_helper.dart';
import 'widgets/ad_widget/interstitial_ad_helper.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        // On web, exclude mouse so trackpad/wheel scrolling is smooth
        if (!kIsWeb) PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }
}

Future<void> main() async {
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      const channel = MethodChannel('com.roccoplay.app/proxy');
      final Map? proxyDetails = await channel.invokeMethod('getSystemProxy');
      if (proxyDetails != null && proxyDetails['host'] != null) {
        final host = proxyDetails['host'];
        final port = proxyDetails['port'] ?? 8080;
        AuditNetworkOverrides.proxyStr = "PROXY $host:$port; DIRECT";
      } else {
        AuditNetworkOverrides.proxyStr = "DIRECT";
      }
    } catch (e) {
      AuditNetworkOverrides.proxyStr = "DIRECT";
    }
    HttpOverrides.global = AuditNetworkOverrides();
  }

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    await MetaEventService.instance.activateApp();
  }

  /// Lock orientations to Portrait by default
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  ///  Firebase Init
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await FirebaseAnalyticsService.instance.activateApp();
  }

  ///  Background Listener
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

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
  if (!kIsWeb) {
    Future.delayed(const Duration(seconds: 2), () {
      AppOpenAdHelper.loadAd();
      InterstitialAdHelper.loadAd();
    });
  }
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

  /// 🔥 App background/foreground track karke 30s+ minimize pe hi App Open Ad allow karo
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kIsWeb) return;
    if (state == AppLifecycleState.paused) {
      AppOpenAdHelper.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      AppOpenAdHelper.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      scrollBehavior: MyCustomScrollBehavior(),
      routingCallback: (routing) {
        if (routing != null && Get.isRegistered<HomeController>()) {
          // Use post-frame to ensure synchronization happens after route is fully settled
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Get.find<HomeController>().updateIndexFromRoute();
          });
        }
      },
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      unknownRoute: GetPage(
        name: '/notfound',
        page: () => const MainHomePage(),
      ),
      getPages: AppPages.pages,
    );
  }
}
