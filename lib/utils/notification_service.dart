import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../data/network/base_api_service.dart';
import '../utils/constants.dart';

class NotificationService extends GetxController {
  static NotificationService get to => Get.find();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;

  Future<void> init() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Get FCM Token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");

    if (token != null) {
      sendTokenToBackend(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      sendTokenToBackend(newToken);
    });

    // Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotificationsPlugin.initialize(initializationSettings);

    // Handle background messages handled in main.dart

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
      _showLocalNotification(message);
    });

    // Handle notification click when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Load saved notifications from Hive
    _loadNotifications();
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.postApi(
        AppConstants.updateFcmToken,
        {'fcmToken': token},
      );
      print("FCM Token sent to backend: $response");
    } catch (e) {
      print("Error sending FCM Token to backend: $e");
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.notification != null) {
      final newNotification = {
        'title': message.notification!.title,
        'body': message.notification!.body,
        'time': DateTime.now().toString(),
        'isRead': false,
      };
      notifications.insert(0, newNotification);
      _saveNotifications();
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'roccoplay_channel',
      'RoccoPlay Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _localNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
    );
  }

  void _loadNotifications() {
    var box = Hive.box('appBox');
    List? saved = box.get('notifications');
    if (saved != null) {
      notifications.assignAll(List<Map<String, dynamic>>.from(saved));
    }
  }

  void _saveNotifications() {
    var box = Hive.box('appBox');
    box.put('notifications', notifications.toList());
  }

  void markAsRead(int index) {
    notifications[index]['isRead'] = true;
    notifications.refresh();
    _saveNotifications();
  }

  void clearNotifications() {
    notifications.clear();
    _saveNotifications();
  }
}
