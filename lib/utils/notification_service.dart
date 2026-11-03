import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../app/routes/app_routes.dart';
import '../app/theme/app_colors.dart';
import '../data/models/response_model/content_response_model/content_model.dart';
import '../data/network/base_api_service.dart';
import '../utils/app_session.dart';
import '../utils/constants.dart';
import '../view_model/content_controller/content_controller.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Required callback for flutter_local_notifications background taps
}

class NotificationService extends GetxController {
  static NotificationService get to => Get.find();

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = false.obs;
  final RxInt unreadCount = 0.obs;

  int currentPage = 1;
  int totalPages = 1;
  int totalNotifications = 0;

  String? _currentToken;

  Future<void> init() async {
    if (kIsWeb) return; // 🛑 Firebase and notifications disabled on Web

    try {
      /// 🔐 Request Permission
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint(
          "🔔 FCM Notification permission status: ${settings.authorizationStatus}");

      // Get FCM Token
      _currentToken = await _firebaseMessaging.getToken();

      if (_currentToken != null) {
        uploadToken();
      }
    } catch (e) {
      debugPrint("⚠️ FCM Token error: $e");
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      uploadToken();
    });

    /// 🔔 Initialize Local Notifications (SKIP ON WEB)
    if (!kIsWeb) {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidSettings);

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'roccoplay_channel',
        'RoccoPlay Notifications',
        description: 'Important notifications from RoccoPlay',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // 👉 Click on Foreground System Notification -> Navigate to content detail
          if (response.payload != null && response.payload!.isNotEmpty) {
            try {
              final decoded = jsonDecode(response.payload!);
              if (decoded is Map<String, dynamic>) {
                handleSystemNotificationTap(decoded);
                return;
              }
            } catch (e) {
              debugPrint("⚠️ Payload decode error: $e");
            }
          }
          Get.toNamed(AppRoutes.notifications);
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Check if app was opened by tapping a local notification
      final NotificationAppLaunchDetails? launchDetails =
          await _localNotificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final decoded = jsonDecode(payload);
            if (decoded is Map<String, dynamic>) {
              Future.delayed(const Duration(milliseconds: 700), () {
                handleSystemNotificationTap(decoded);
              });
            }
          } catch (_) {}
        }
      }
    }

    /// 📩 Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
      if (!kIsWeb) {
        _showLocalNotification(message);
      }
    });

    /// 📲 Notification Click (App in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
      if (message.notification != null) {
        data['title'] ??= message.notification!.title;
        data['message'] ??= message.notification!.body;
      }
      handleSystemNotificationTap(data);
    });

    /// 🚀 Notification Click when App was terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleMessage(message);
        final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
        if (message.notification != null) {
          data['title'] ??= message.notification!.title;
          data['message'] ??= message.notification!.body;
        }
        // Small delay to ensure Get router and controllers are initialized
        Future.delayed(const Duration(milliseconds: 700), () {
          handleSystemNotificationTap(data);
        });
      }
    });

    _loadNotifications();
    fetchUnreadCount();
    fetchNotifications(); // Initial fetch from server
  }

  /// 📡 1. Register / Update FCM Device Token
  Future<void> uploadToken() async {
    if (_currentToken == null || _currentToken!.isEmpty) return;

    final token = AppSession.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      try {
        await apiService.postApi(
          AppConstants.updateFcmToken,
          {'fcmToken': _currentToken},
        );
      } catch (_) {
        // Fallback to PATCH if POST is not accepted
        await apiService.pacthApi(
          AppConstants.updateFcmToken,
          {'fcmToken': _currentToken},
        );
      }
      debugPrint("✅ FCM token updated successfully");
    } catch (e) {
      debugPrint("⚠️ uploadToken error: $e");
    }
  }

  /// 🔢 3. Get Unread Notifications Count
  Future<void> fetchUnreadCount() async {
    final token = AppSession.getToken();
    if (token == null || token.isEmpty) {
      unreadCount.value =
          notifications.where((n) => n['isRead'] == false).length;
      return;
    }

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response =
          await apiService.getApi(AppConstants.getUnreadNotificationCount);
      if (response != null && response['success'] == true) {
        unreadCount.value = response['unreadCount'] ?? 0;
      }
    } catch (e) {
      unreadCount.value =
          notifications.where((n) => n['isRead'] == false).length;
    }
  }

  /// 📥 2. Fetch Notifications from Backend (Paginated)
  Future<void> fetchNotifications({int page = 1, int limit = 20, bool refresh = false}) async {
    try {
      if (page == 1 || refresh) {
        currentPage = 1;
        isLoading.value = true;
      }
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(
          '${AppConstants.getNotifications}?page=$currentPage&limit=$limit&unreadOnly=false');

      if (response != null && response['success'] == true) {
        final List fetchedList = response['notifications'] ?? [];
        final List<Map<String, dynamic>> items = fetchedList.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return {
            'id': map['id'] ?? map['_id'],
            '_id': map['_id'] ?? map['id'],
            'title': map['title'] ?? '',
            'body': map['message'] ?? map['body'] ?? '',
            'message': map['message'] ?? map['body'] ?? '',
            'time': map['createdAt'] ??
                map['sentAt'] ??
                map['time'] ??
                DateTime.now().toIso8601String(),
            'isRead': map['isRead'] ?? false,
            'type': map['type'] ?? 'GENERAL',
            'imageUrl': map['imageUrl'] ?? '',
            'attachmentType': map['attachmentType'] ?? '',
            'content': map['content'],
            'subscriptionPlan': map['subscriptionPlan'],
            'actionUrl': map['actionUrl'] ?? '',
            'metadata': map['metadata'],
          };
        }).toList();

        notifications.assignAll(items);

        if (response['pagination'] != null) {
          final pagination = Map<String, dynamic>.from(response['pagination']);
          currentPage = pagination['currentPage'] ?? 1;
          totalPages = pagination['totalPages'] ?? 1;
          totalNotifications = pagination['totalNotifications'] ?? items.length;
          hasMore.value = pagination['hasMore'] ?? (currentPage < totalPages);
        } else {
          hasMore.value = items.length >= limit;
        }

        _saveNotifications();
      }
    } catch (e) {
      debugPrint("⚠️ fetchNotifications error: $e");
    } finally {
      isLoading.value = false;
      fetchUnreadCount();
    }
  }

  /// 🔄 Load More Notifications (Next Page for Infinite Scroll)
  Future<void> loadMoreNotifications() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      final int nextPage = currentPage + 1;
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(
          '${AppConstants.getNotifications}?page=$nextPage&limit=20&unreadOnly=false');

      if (response != null && response['success'] == true) {
        final List fetchedList = response['notifications'] ?? [];
        final List<Map<String, dynamic>> newItems = fetchedList.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return {
            'id': map['id'] ?? map['_id'],
            '_id': map['_id'] ?? map['id'],
            'title': map['title'] ?? '',
            'body': map['message'] ?? map['body'] ?? '',
            'message': map['message'] ?? map['body'] ?? '',
            'time': map['createdAt'] ??
                map['sentAt'] ??
                map['time'] ??
                DateTime.now().toIso8601String(),
            'isRead': map['isRead'] ?? false,
            'type': map['type'] ?? 'GENERAL',
            'imageUrl': map['imageUrl'] ?? '',
            'attachmentType': map['attachmentType'] ?? '',
            'content': map['content'],
            'subscriptionPlan': map['subscriptionPlan'],
            'actionUrl': map['actionUrl'] ?? '',
            'metadata': map['metadata'],
          };
        }).toList();

        final existingIds = notifications.map((n) => n['id']).toSet();
        for (var item in newItems) {
          if (!existingIds.contains(item['id'])) {
            notifications.add(item);
          }
        }

        if (response['pagination'] != null) {
          final pagination = Map<String, dynamic>.from(response['pagination']);
          currentPage = pagination['currentPage'] ?? nextPage;
          totalPages = pagination['totalPages'] ?? totalPages;
          totalNotifications =
              pagination['totalNotifications'] ?? notifications.length;
          hasMore.value = pagination['hasMore'] ?? (currentPage < totalPages);
        } else {
          currentPage = nextPage;
          hasMore.value = newItems.length >= 20;
        }

        _saveNotifications();
      }
    } catch (e) {
      debugPrint("⚠️ loadMoreNotifications error: $e");
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// 🔍 4. Get Single Notification Detail (Auto Marks as Read on server)
  Future<Map<String, dynamic>?> getNotificationDetail(String id) async {
    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response =
          await apiService.getApi(AppConstants.getNotificationDetail(id));
      if (response != null &&
          response['success'] == true &&
          response['notification'] != null) {
        final notif = Map<String, dynamic>.from(response['notification']);
        final index = notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          notifications[index]['isRead'] = true;
          notifications.refresh();
          _saveNotifications();
        }
        if (unreadCount.value > 0) {
          unreadCount.value -= 1;
        }
        return notif;
      }
    } catch (e) {
      debugPrint("⚠️ getNotificationDetail error: $e");
    }
    return null;
  }

  /// ✅ 5. Mark Single Notification as Read
  Future<void> markAsRead(int index) async {
    if (index >= notifications.length) return;
    if (notifications[index]['isRead'] == true) return;

    final String? id = notifications[index]['id']?.toString() ??
        notifications[index]['_id']?.toString();

    // Optimistic UI update
    notifications[index]['isRead'] = true;
    notifications.refresh();
    if (unreadCount.value > 0) {
      unreadCount.value -= 1;
    }
    _saveNotifications();

    if (id == null || id.isEmpty) return;

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      await apiService.pacthApi(AppConstants.markNotificationRead(id), {});
    } catch (e) {
      // Error handled silently
    }
  }

  /// ✅ 6. Mark All Notifications as Read
  Future<void> markAllAsRead() async {
    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response =
          await apiService.pacthApi(AppConstants.markAllNotificationsRead, {});

      if (response != null && response['success'] == true) {
        for (var n in notifications) {
          n['isRead'] = true;
        }
        notifications.refresh();
        unreadCount.value = 0;
        _saveNotifications();
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// ❌ 7. Delete Single Notification
  Future<void> deleteSingleNotification(int index) async {
    if (index >= notifications.length) return;

    final wasUnread = notifications[index]['isRead'] == false;
    final String? id = notifications[index]['id']?.toString() ??
        notifications[index]['_id']?.toString();

    notifications.removeAt(index);
    if (wasUnread && unreadCount.value > 0) {
      unreadCount.value -= 1;
    }
    _saveNotifications();

    if (id == null || id.isEmpty) return;

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      await apiService.deleteApi(AppConstants.deleteNotification(id), {});
    } catch (e) {
      // Handled silently
    }
  }

  /// 🧹 Clear All Notifications (Local)
  void clearNotifications() {
    notifications.clear();
    unreadCount.value = 0;
    _saveNotifications();
  }

  /// 🎯 SYSTEM NOTIFICATION CLICK HANDLER:
  /// "system notification mai click karke uss content ke detail page mai open ho jaye
  /// lcik karke phele tho all content ko load karna fir ushi perticalr content ke page detail mai jna hai"
  Future<void> handleSystemNotificationTap(Map<String, dynamic> data) async {
    debugPrint("🎬 [Notification Tap Handler] data: $data");

    // 1. Parse nested data if needed
    Map<String, dynamic> contentMap = {};
    if (data['content'] != null) {
      if (data['content'] is Map) {
        contentMap = Map<String, dynamic>.from(data['content']);
      } else if (data['content'] is String) {
        try {
          contentMap = Map<String, dynamic>.from(jsonDecode(data['content']));
        } catch (_) {}
      }
    }

    Map<String, dynamic> metadataMap = {};
    if (data['metadata'] != null) {
      if (data['metadata'] is Map) {
        metadataMap = Map<String, dynamic>.from(data['metadata']);
      } else if (data['metadata'] is String) {
        try {
          metadataMap = Map<String, dynamic>.from(jsonDecode(data['metadata']));
        } catch (_) {}
      }
    }

    final String contentId = (contentMap['id'] ??
            metadataMap['contentId'] ??
            data['contentId'] ??
            data['content_id'] ??
            data['id'] ??
            '')
        .toString();

    final String slug = (contentMap['slug'] ??
            metadataMap['slug'] ??
            data['slug'] ??
            '')
        .toString();

    final String actionUrl = (data['actionUrl'] ??
            data['action_url'] ??
            metadataMap['actionUrl'] ??
            '')
        .toString();

    final String attachmentType = (data['attachmentType'] ??
            data['attachment_type'] ??
            metadataMap['attachmentType'] ??
            '')
        .toString()
        .toLowerCase();

    final String type = (data['type'] ?? '').toString().toUpperCase();

    // If it's a subscription notification -> navigate to Go Premium
    if (attachmentType == 'subscription' ||
        type == 'SUBSCRIPTION' ||
        actionUrl.contains('/plan') ||
        (metadataMap['planId'] != null &&
            metadataMap['planId'].toString().isNotEmpty)) {
      Get.toNamed(AppRoutes.goPremium);
      return;
    }

    // Extract slug from actionUrl if available (e.g. "/movie/bablusha")
    String slugFromUrl = '';
    if (actionUrl.isNotEmpty) {
      final parts = actionUrl.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2 &&
          (parts[0] == 'movie' ||
              parts[0] == 'series' ||
              parts[0] == 'content')) {
        slugFromUrl = parts[1];
      }
    }

    final String finalSlug = slug.isNotEmpty ? slug : slugFromUrl;
    final String title =
        (contentMap['title'] ?? data['title'] ?? '').toString();

    // 2. Load all content first!
    ContentController contentController;
    if (Get.isRegistered<ContentController>()) {
      contentController = Get.find<ContentController>();
    } else {
      contentController = Get.put(ContentController());
    }

    if (contentController.allContent.isEmpty) {
      try {
        await contentController.fetchContent();
      } catch (e) {
        debugPrint("⚠️ Content fetch error: $e");
      }
    }

    // 3. Find matching content in allContent
    ContentModel? matchedContent;

    if (contentId.isNotEmpty) {
      matchedContent = contentController.allContent
          .firstWhereOrNull((c) => c.id == contentId);
    }

    if (matchedContent == null && finalSlug.isNotEmpty) {
      matchedContent = contentController.allContent.firstWhereOrNull(
          (c) => c.slug.toLowerCase() == finalSlug.toLowerCase());
    }

    if (matchedContent == null && title.isNotEmpty) {
      matchedContent = contentController.allContent.firstWhereOrNull((c) =>
          c.title.toLowerCase().trim() == title.toLowerCase().trim() ||
          c.title.toLowerCase().contains(title.toLowerCase()));
    }

    // If not found yet, try one more fresh fetch
    if (matchedContent == null) {
      try {
        await contentController.fetchContent();
        if (contentId.isNotEmpty) {
          matchedContent = contentController.allContent
              .firstWhereOrNull((c) => c.id == contentId);
        }
        if (matchedContent == null && finalSlug.isNotEmpty) {
          matchedContent = contentController.allContent.firstWhereOrNull(
              (c) => c.slug.toLowerCase() == finalSlug.toLowerCase());
        }
      } catch (_) {}
    }

    // 4. Navigate to DramaDetailsPage with matched content
    if (matchedContent != null) {
      Get.toNamed(AppRoutes.dramaDetails, arguments: matchedContent);
      return;
    }

    // 5. Fallback ContentModel if content info is in notification
    if (contentId.isNotEmpty || title.isNotEmpty) {
      final poster = (contentMap['poster'] ??
              data['poster'] ??
              data['imageUrl'] ??
              '')
          .toString();
      final banner = (contentMap['banner'] ??
              data['banner'] ??
              data['imageUrl'] ??
              poster)
          .toString();
      final contentType =
          (contentMap['contentType'] ?? data['contentType'] ?? 'movie')
              .toString();

      final fallback = ContentModel(
        id: contentId.isNotEmpty ? contentId : 'unknown',
        title: title.isNotEmpty ? title : 'Content Details',
        description: (data['message'] ?? data['body'] ?? title).toString(),
        genre: [],
        releaseYear: DateTime.now().year,
        duration: '',
        language: '',
        poster: poster,
        banner: banner.isNotEmpty ? banner : poster,
        videoUrl: '',
        trailerUrl: '',
        isPremium: false,
        rating: 0.0,
        category: [],
        slug: finalSlug,
        contentType: contentType,
      );
      Get.toNamed(AppRoutes.dramaDetails, arguments: fallback);
      return;
    }

    // Fallback: open notifications screen
    Get.toNamed(AppRoutes.notifications);
  }

  void _handleMessage(RemoteMessage message) {
    fetchUnreadCount();
    fetchNotifications();
  }

  /// 🧹 Clean and extract direct image URL (handles Google Search redirect URLs)
  String _sanitizeImageUrl(String url) {
    if (url.isEmpty) return '';
    try {
      final trimmed = url.trim();
      // Google image search redirect: https://www.google.com/imgres?q=...&imgurl=https%3A%2F%2F...
      if (trimmed.contains('google.com/imgres') || trimmed.contains('imgurl=')) {
        final uri = Uri.tryParse(trimmed);
        if (uri != null && uri.queryParameters.containsKey('imgurl')) {
          final extracted = uri.queryParameters['imgurl'];
          if (extracted != null && extracted.isNotEmpty) {
            return Uri.decodeFull(extracted);
          }
        }
      }
      return Uri.decodeFull(trimmed);
    } catch (_) {
      return url.trim();
    }
  }

  /// 🖼️ Helper to download image for Android system notification tray (BigPictureStyle)
  Future<ByteArrayAndroidBitmap?> _downloadNotificationImage(String url) async {
    try {
      final sanitized = _sanitizeImageUrl(url);
      final uri = Uri.tryParse(sanitized);
      if (uri == null) return null;

      final response = await http.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept': 'image/*,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.bodyBytes.length > 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          debugPrint("⚠️ Image URL returned HTML page instead of image: $url");
          return null;
        }
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      debugPrint("⚠️ Failed to download system notification image from $url: $e");
    }
    return null;
  }

  /// 📲 Show Local Notification in System Tray with Rich Image
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final title = message.notification?.title ??
        message.data['title'] ??
        'RoccoPlay';
    final body = message.notification?.body ??
        message.data['message'] ??
        message.data['body'] ??
        '';

    // 🖼️ Collect all candidate image URLs in order of preference
    final List<String> candidateUrls = [];

    // 1. Direct imageUrl from notification or data
    String? rawImageUrl = message.notification?.android?.imageUrl ??
        message.data['imageUrl'] ??
        message.data['image'];
    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      candidateUrls.add(_sanitizeImageUrl(rawImageUrl));
      candidateUrls.add(rawImageUrl);
    }

    // 2. Content banner and poster from nested content
    if (message.data['content'] != null) {
      try {
        final contentRaw = message.data['content'];
        final contentMap =
            contentRaw is String ? jsonDecode(contentRaw) : contentRaw;
        if (contentMap is Map) {
          if (contentMap['banner'] != null &&
              contentMap['banner'].toString().isNotEmpty) {
            candidateUrls.add(contentMap['banner'].toString());
          }
          if (contentMap['poster'] != null &&
              contentMap['poster'].toString().isNotEmpty) {
            candidateUrls.add(contentMap['poster'].toString());
          }
        }
      } catch (_) {}
    }

    // 3. Root banner and poster fields
    if (message.data['banner'] != null &&
        message.data['banner'].toString().isNotEmpty) {
      candidateUrls.add(message.data['banner'].toString());
    }
    if (message.data['poster'] != null &&
        message.data['poster'].toString().isNotEmpty) {
      candidateUrls.add(message.data['poster'].toString());
    }

    // Attempt downloading candidate images until one succeeds
    ByteArrayAndroidBitmap? bigPictureBitmap;
    for (final candidate in candidateUrls) {
      if (candidate.isEmpty) continue;
      bigPictureBitmap = await _downloadNotificationImage(candidate);
      if (bigPictureBitmap != null) {
        debugPrint("✅ Notification image downloaded successfully from: $candidate");
        break;
      }
    }

    BigPictureStyleInformation? styleInfo;
    if (bigPictureBitmap != null) {
      styleInfo = BigPictureStyleInformation(
        bigPictureBitmap,
        contentTitle: title,
        summaryText: body,
        hideExpandedLargeIcon: true,
      );
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'roccoplay_channel',
      'RoccoPlay Notifications',
      channelDescription: 'Important notifications from RoccoPlay',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: styleInfo,
      autoCancel: true,
      ongoing: false,
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    // Prepare complete payload map for tap navigation
    final Map<String, dynamic> payloadMap =
        Map<String, dynamic>.from(message.data);
    if (title.isNotEmpty) payloadMap['title'] = title;
    if (body.isNotEmpty) payloadMap['message'] = body;

    await _localNotificationsPlugin.show(
      message.hashCode,
      title,
      body,
      platformDetails,
      payload: jsonEncode(payloadMap),
    );
  }

  void _loadNotifications() {
    try {
      var box = Hive.box('appBox');
      List? saved = box.get('notifications');
      if (saved != null) {
        final List<Map<String, dynamic>> convertedList = saved.map((item) {
          return Map<String, dynamic>.from(item as Map);
        }).toList();
        notifications.assignAll(convertedList);
      }
    } catch (e) {
      // Error handled silently
    }
  }

  void _saveNotifications() {
    try {
      var box = Hive.box('appBox');
      box.put('notifications', notifications.toList());
    } catch (e) {
      // Error handled silently
    }
  }
}
