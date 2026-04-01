import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:roccoplay/app/routes/app_pages.dart';
import 'package:roccoplay/view_model/like_dislike_controller/like_dislike_controller.dart';
import 'package:roccoplay/view_model/watchlist_controller/watchlist_controller.dart';
import 'app/routes/app_routes.dart';
import 'data/network/api_network_service.dart';
import 'data/network/base_api_service.dart';
import 'utils/app_session.dart';
import 'view_model/auth_controller/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();
  await Hive.initFlutter();
  await Hive.openBox('appBox');

  // 1. Initialize Global Network Service
  final networkService = NetworkApiService();
  Get.put<BaseApiService>(networkService, permanent: true);

  // 2. Set token if already logged in
  String? token = AppSession.getToken();
  if (token != null) {
    networkService.setToken(token);
  }

  // 3. Put AuthController
  Get.put(AuthController(), permanent: true);
  Get.put(InteractionController(), permanent: true);
  Get.put(WatchlistController(), permanent: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}
