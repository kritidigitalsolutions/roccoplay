import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
import '../view/dramaDetails/dramaDetailsPage.dart';
import '../view_model/auth_controller/auth_controller.dart';
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

  static ContentModel? pendingContentNavigation;

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxInt unreadCount = 0.obs;

  // Pagination state
  int currentPage = 1;
  int totalPages = 1;
  bool hasMore = true;
  final int pageLimit = 20;

  String? _currentToken;

  Future<void> init() async {
    if (kIsWeb) return; // 🛑 Firebase and notifications disabled on Web

    try {
      /// 🔐 Request Permission
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      debugPrint(
        "🔔 FCM Notification permission status: ${settings.authorizationStatus}",
      );

      /// 🔔 Ensure Foreground Notification Presentation Options are active
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

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
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'roccoplay_channel',
        'RoccoPlay Notifications',
        description: 'Important notifications from RoccoPlay',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      const AndroidNotificationChannel channelV2 = AndroidNotificationChannel(
        'roccoplay_channel_v2',
        'RoccoPlay Notifications',
        description: 'Important notifications from RoccoPlay',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        await androidPlugin.createNotificationChannel(channelV2);
        try {
          await androidPlugin.requestNotificationsPermission();
        } catch (_) {}
      }

      await _localNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint(
            "📲 [Local Notification Tap] payload: ${response.payload}",
          );
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
              Future.delayed(const Duration(milliseconds: 500), () {
                handleSystemNotificationTap(decoded);
              });
            }
          } catch (_) {}
        }
      }
    }

    /// 📩 Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        "📩 [FCM onMessage] Foreground message arrived: ${message.messageId}",
      );
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
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint(
          "🚀 [FCM getInitialMessage] Cold boot from notification: ${message.data}",
        );
        _handleMessage(message);
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          message.data,
        );
        if (message.notification != null) {
          data['title'] ??= message.notification!.title;
          data['message'] ??= message.notification!.body;
        }
        Future.delayed(const Duration(milliseconds: 500), () {
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
        await apiService.postApi(AppConstants.updateFcmToken, {
          'fcmToken': _currentToken,
        });
      } catch (_) {
        // Fallback to PATCH if POST is not accepted
        await apiService.pacthApi(AppConstants.updateFcmToken, {
          'fcmToken': _currentToken,
        });
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
      unreadCount.value = notifications
          .where((n) => n['isRead'] == false)
          .length;
      return;
    }

    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(
        AppConstants.getUnreadNotificationCount,
      );
      if (response != null && response['success'] == true) {
        unreadCount.value = response['unreadCount'] ?? 0;
      }
    } catch (e) {
      unreadCount.value = notifications
          .where((n) => n['isRead'] == false)
          .length;
    }
  }

  /// 📥 2. Fetch Notifications from Backend (Paginated)
  Future<void> fetchNotifications({
    int page = 1,
    int limit = 20,
    bool refresh = false,
  }) async {
    final targetPage = refresh ? 1 : page;
    try {
      if (targetPage == 1) {
        currentPage = 1;
        hasMore = true;
        isLoading.value = true;
      } else {
        isLoadingMore.value = true;
      }

      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(
        '${AppConstants.getNotifications}?page=$targetPage&limit=$limit&unreadOnly=false',
      );

      if (response != null && response['success'] == true) {
        final List fetchedList = response['notifications'] ?? [];
        final newItems = fetchedList.map((e) {
          final map = Map<String, dynamic>.from(e as Map);
          return {
            'id': map['id'] ?? map['_id'],
            '_id': map['_id'] ?? map['id'],
            'title': map['title'] ?? '',
            'body': map['message'] ?? map['body'] ?? '',
            'message': map['message'] ?? map['body'] ?? '',
            'time':
                map['createdAt'] ??
                map['sentAt'] ??
                map['time'] ??
                DateTime.now().toString(),
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

        if (response['pagination'] != null) {
          final pag = response['pagination'];
          currentPage = pag['currentPage'] ?? targetPage;
          totalPages = pag['totalPages'] ?? 1;
          hasMore = pag['hasMore'] ?? (currentPage < totalPages);
        } else {
          hasMore = newItems.length >= limit;
          currentPage = targetPage;
        }

        if (targetPage == 1) {
          notifications.assignAll(newItems);
        } else {
          final existingIds = notifications.map((n) => n['id']).toSet();
          for (var item in newItems) {
            if (!existingIds.contains(item['id'])) {
              notifications.add(item);
            }
          }
        }
        _saveNotifications();
      }
    } catch (e) {
      debugPrint("⚠️ fetchNotifications error: $e");
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      fetchUnreadCount();
    }
  }

  /// 🔄 Load next page when reaching bottom of notifications
  Future<void> loadMoreNotifications() async {
    if (isLoading.value || isLoadingMore.value || !hasMore) return;
    await fetchNotifications(page: currentPage + 1, limit: pageLimit);
  }

  /// 🔍 4. Get Single Notification Detail (Auto Marks as Read on server)
  Future<Map<String, dynamic>?> getNotificationDetail(String id) async {
    try {
      final BaseApiService apiService = Get.find<BaseApiService>();
      final response = await apiService.getApi(
        AppConstants.getNotificationDetail(id),
      );
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

    final String? id =
        notifications[index]['id']?.toString() ??
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
      final response = await apiService.pacthApi(
        AppConstants.markAllNotificationsRead,
        {},
      );

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
    final String? id =
        notifications[index]['id']?.toString() ??
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

  /// Helper to safely parse maps that might be stringified (JSON or Dart map string)
  Map<String, dynamic> _parseFlexibleMap(dynamic value) {
    if (value == null) return {};
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final str = value.trim();
      if (str.isEmpty || str == 'null') return {};
      try {
        final decoded = jsonDecode(str);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}

      // Fallback: match key-value pairs like {id: 123, title: ABC}
      final Map<String, dynamic> result = {};
      final regex = RegExp(r'(\w+)\s*:\s*([^,}]+)');
      for (final m in regex.allMatches(str)) {
        final k = m.group(1)?.trim();
        final v = m.group(2)?.trim();
        if (k != null && v != null) {
          result[k] = v;
        }
      }
      return result;
    }
    return {};
  }

  /// 🎯 SYSTEM NOTIFICATION CLICK HANDLER:
  /// "system notification mai click karke uss content ke detail page mai open ho jaye
  /// lcik karke phele tho all content ko load karna fir ushi perticalr content ke page detail mai jna hai"
  Future<void> handleSystemNotificationTap(Map<String, dynamic> data) async {
    debugPrint("🎬 [Notification Tap Handler] data: $data");

    // 0. If notification ID was passed, find full details from cached notifications
    final notifId = (data['notificationId'] ?? data['_id'] ?? data['id'])
        ?.toString();
    Map<String, dynamic>? cachedNotif;
    if (notifId != null && notifId.isNotEmpty) {
      cachedNotif = notifications.firstWhereOrNull(
        (n) => n['id'] == notifId || n['_id'] == notifId,
      );
    }

    // 1. Parse content and metadata
    final Map<String, dynamic> contentMap = _parseFlexibleMap(
      cachedNotif?['content'] ?? data['content'],
    );
    final Map<String, dynamic> metadataMap = _parseFlexibleMap(
      cachedNotif?['metadata'] ?? data['metadata'],
    );

    final String actionUrl =
        (cachedNotif?['actionUrl'] ??
                data['actionUrl'] ??
                data['action_url'] ??
                metadataMap['actionUrl'] ??
                '')
            .toString();

    final String attachmentType =
        (cachedNotif?['attachmentType'] ??
                data['attachmentType'] ??
                data['attachment_type'] ??
                metadataMap['attachmentType'] ??
                '')
            .toString()
            .toLowerCase();

    final String type = (cachedNotif?['type'] ?? data['type'] ?? '')
        .toString()
        .toUpperCase();

    // Check if subscription notification
    if (attachmentType == 'subscription' ||
        type == 'SUBSCRIPTION' ||
        actionUrl.contains('/plan') ||
        (metadataMap['planId'] != null &&
            metadataMap['planId'].toString().isNotEmpty)) {
      _navigateToRoute(AppRoutes.goPremium);
      return;
    }

    // Extract target content ID (NEVER use notification ID)
    final String contentId =
        (contentMap['id'] ??
                metadataMap['contentId'] ??
                data['contentId'] ??
                data['content_id'] ??
                '')
            .toString();

    // Extract slug
    String slugFromUrl = '';
    if (actionUrl.isNotEmpty) {
      final cleanUrl = actionUrl.replaceAll(RegExp(r'^[/#]+'), '');
      final parts = cleanUrl.split('/').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        slugFromUrl = parts[1];
      } else if (parts.isNotEmpty) {
        slugFromUrl = parts[0];
      }
    }

    final String slug =
        (contentMap['slug'] ??
                metadataMap['slug'] ??
                data['slug'] ??
                slugFromUrl)
            .toString();

    // Extract title
    final String title =
        (contentMap['title'] ??
                metadataMap['title'] ??
                data['contentTitle'] ??
                (data['title'] != 'test' ? data['title'] : '') ??
                '')
            .toString();

    // 2. Ensure content is loaded (especially during cold boot)
    ContentController contentController;
    if (Get.isRegistered<ContentController>()) {
      contentController = Get.find<ContentController>();
    } else {
      contentController = Get.put(ContentController(), permanent: true);
    }

    if (contentController.allContent.isEmpty) {
      try {
        await contentController.fetchContent();
      } catch (e) {
        debugPrint("⚠️ Content fetch error: $e");
      }
    }

    ContentModel? matchedContent;

    // Search in allContent by ID
    if (contentId.isNotEmpty) {
      matchedContent = contentController.allContent.firstWhereOrNull(
        (c) => c.id == contentId,
      );
    }

    // Search in allContent by slug
    if (matchedContent == null && slug.isNotEmpty) {
      matchedContent = contentController.allContent.firstWhereOrNull(
        (c) => c.slug.toLowerCase() == slug.toLowerCase(),
      );
    }

    // Search in categoryContentMap
    if (matchedContent == null) {
      for (final list in contentController.categoryContentMap.values) {
        if (contentId.isNotEmpty) {
          matchedContent = list.firstWhereOrNull((c) => c.id == contentId);
          if (matchedContent != null) break;
        }
        if (slug.isNotEmpty) {
          matchedContent = list.firstWhereOrNull(
            (c) => c.slug.toLowerCase() == slug.toLowerCase(),
          );
          if (matchedContent != null) break;
        }
      }
    }

    // Search by title
    if (matchedContent == null && title.isNotEmpty) {
      matchedContent = contentController.allContent.firstWhereOrNull(
        (c) =>
            c.title.toLowerCase().trim() == title.toLowerCase().trim() ||
            c.title.toLowerCase().contains(title.toLowerCase()),
      );
    }

    // 3. If matched in cache, navigate directly to DramaDetailsPage!
    if (matchedContent != null) {
      _navigateToDramaDetails(matchedContent);
      return;
    }

    // 4. Fallback ContentModel from notification payload (opens INSTANTLY)
    final poster =
        (contentMap['poster'] ?? data['poster'] ?? data['imageUrl'] ?? '')
            .toString();
    final banner =
        (contentMap['banner'] ?? data['banner'] ?? data['imageUrl'] ?? poster)
            .toString();
    final contentType =
        (contentMap['contentType'] ??
                metadataMap['contentType'] ??
                data['contentType'] ??
                'series')
            .toString();
    final finalTitle = title.isNotEmpty
        ? title
        : (slug.isNotEmpty ? slug : 'Content Details');
    final finalId = contentId.isNotEmpty
        ? contentId
        : (slug.isNotEmpty
              ? slug
              : DateTime.now().millisecondsSinceEpoch.toString());

    final fallback = ContentModel(
      id: finalId,
      title: finalTitle,
      description:
          (contentMap['description'] ??
                  data['message'] ??
                  data['body'] ??
                  finalTitle)
              .toString(),
      genre: [],
      releaseYear: DateTime.now().year,
      duration: '',
      language: '',
      poster: poster.isNotEmpty ? poster : banner,
      banner: banner.isNotEmpty ? banner : poster,
      videoUrl: '',
      trailerUrl: '',
      isPremium: false,
      rating: 0.0,
      cast: [],
      category: ['series', 'drama'],
      slug: slug,
      contentType: contentType,
      seasons: [],
    );

    _navigateToDramaDetails(fallback);
  }

  void _navigateToRoute(String routeName) {
    if (Get.currentRoute == AppRoutes.splash) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        Get.toNamed(routeName);
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.toNamed(routeName);
    });
  }

  void _navigateToDramaDetails(ContentModel content) {
    debugPrint(
      "🚀 [Navigate to DramaDetails] title: ${content.title}, id: ${content.id}",
    );

    pendingContentNavigation = content;

    // If app is currently on splash screen, navigate to home then open details
    if (Get.currentRoute == AppRoutes.splash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.home);
        Future.delayed(const Duration(milliseconds: 300), () {
          Get.toNamed(
            AppRoutes.dramaDetails,
            arguments: content,
            preventDuplicates: false,
          );
        });
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.toNamed(
          AppRoutes.dramaDetails,
          arguments: content,
          preventDuplicates: false,
        );
      } catch (e) {
        debugPrint("⚠️ Get.toNamed failed: $e, using direct Get.to");
        Get.to(
          () => DramaDetailsPage(
            isSignedIn: Get.isRegistered<AuthController>()
                ? Get.find<AuthController>().isLoggedIn.value
                : false,
            content: content,
          ),
        );
      }
    });
  }

  void _handleMessage(RemoteMessage message) {
    fetchUnreadCount();
    fetchNotifications();
  }

  /// 🧹 Clean and extract direct image URL (handles Google Search redirect URLs)
  static String sanitizeImageUrl(String url) {
    if (url.isEmpty) return '';
    try {
      var trimmed = url.trim();
      // Google image search redirect: https://www.google.com/imgres?q=...&imgurl=https%3A%2F%2F...
      if (trimmed.contains('google.com/imgres') ||
          trimmed.contains('imgurl=')) {
        final uri = Uri.tryParse(trimmed);
        if (uri != null && uri.queryParameters.containsKey('imgurl')) {
          final extracted = uri.queryParameters['imgurl'];
          if (extracted != null && extracted.isNotEmpty) {
            trimmed = Uri.decodeFull(extracted);
          }
        }
      }
      return trimmed.replaceAll(' ', '%20');
    } catch (_) {
      return url.trim().replaceAll(' ', '%20');
    }
  }

  /// 🖼️ Helper to download image for Android system notification tray (BigPictureStyle)
  Future<ByteArrayAndroidBitmap?> _downloadNotificationImage(String url) async {
    try {
      final sanitized = sanitizeImageUrl(url);
      final uri = Uri.tryParse(sanitized);
      if (uri == null) return null;

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
              'Accept': 'image/*,*/*;q=0.8',
            },
          )
          .timeout(const Duration(milliseconds: 2000));

      if (response.statusCode == 200 &&
          response.bodyBytes.length > 200 &&
          response.bodyBytes.length < 500000) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          return null;
        }
        return ByteArrayAndroidBitmap(response.bodyBytes);
      }
    } catch (e) {
      debugPrint(
        "⚠️ Failed to download system notification image from $url: $e",
      );
    }
    return null;
  }

  /// 📲 Show Local Notification in System Tray with Rich Image
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final title =
          message.notification?.title ?? message.data['title'] ?? 'RoccoPlay';
      final body =
          message.notification?.body ??
          message.data['message'] ??
          message.data['body'] ??
          '';

      // Prepare complete payload map for tap navigation
      final Map<String, dynamic> payloadMap = Map<String, dynamic>.from(
        message.data,
      );
      if (title.isNotEmpty) payloadMap['title'] = title;
      if (body.isNotEmpty) payloadMap['message'] = body;

      // 🖼️ Collect all candidate image URLs in order of preference
      final List<String> candidateUrls = [];
      void addCandidate(dynamic raw) {
        if (raw == null) return;
        final s = raw.toString().trim();
        if (s.isEmpty || s == 'null') return;
        final clean = sanitizeImageUrl(s);
        if (clean.isNotEmpty &&
            !clean.contains('google.com/search') &&
            !candidateUrls.contains(clean)) {
          candidateUrls.add(clean);
        }
      }

      // 1. Direct imageUrl from notification or data
      addCandidate(message.notification?.android?.imageUrl);
      addCandidate(message.data['imageUrl']);
      addCandidate(message.data['image']);

      // 2. Content banner and poster from nested content
      if (message.data['content'] != null) {
        try {
          final contentRaw = message.data['content'];
          final contentMap = contentRaw is String
              ? jsonDecode(contentRaw)
              : contentRaw;
          if (contentMap is Map) {
            addCandidate(contentMap['banner']);
            addCandidate(contentMap['poster']);
          }
        } catch (_) {}
      }

      // 3. Root banner and poster fields
      addCandidate(message.data['banner']);
      addCandidate(message.data['poster']);

      // Attempt downloading candidate images safely
      ByteArrayAndroidBitmap? bigPictureBitmap;
      String? successfulImageUrl;
      for (final candidate in candidateUrls) {
        try {
          bigPictureBitmap = await _downloadNotificationImage(candidate);
          if (bigPictureBitmap != null) {
            successfulImageUrl = candidate;
            debugPrint(
              "✅ Notification image downloaded successfully from: $candidate",
            );
            break;
          }
        } catch (_) {}
      }

      BigPictureStyleInformation? styleInfo;
      if (bigPictureBitmap != null) {
        styleInfo = BigPictureStyleInformation(
          bigPictureBitmap,
          contentTitle: title,
          summaryText: body,
          hideExpandedLargeIcon: false,
        );
      }

      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'roccoplay_channel',
            'RoccoPlay Notifications',
            channelDescription: 'Important notifications from RoccoPlay',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            icon: '@mipmap/launcher_icon',
            styleInformation: styleInfo,
            autoCancel: true,
            ongoing: false,
            playSound: true,
            enableVibration: true,
            channelShowBadge: true,
            visibility: NotificationVisibility.public,
          );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      // Safe 32-bit positive integer ID for Android NotificationManager
      final int notificationId = (message.hashCode & 0x7FFFFFFF) == 0
          ? DateTime.now().millisecondsSinceEpoch.remainder(100000)
          : (message.hashCode & 0x7FFFFFFF);

      await _localNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: jsonEncode(payloadMap),
      );

      // 🔔 ALSO Show an in-app animated banner if the app is currently in foreground
      _showInAppNotificationBanner(
        title: title,
        body: body,
        data: payloadMap,
        imageUrl: successfulImageUrl ?? candidateUrls.firstOrNull,
      );
    } catch (e) {
      debugPrint("⚠️ _showLocalNotification error: $e");
    }
  }

  /// 🔔 In-App banner when notification arrives while app is in foreground
  void _showInAppNotificationBanner({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? imageUrl,
  }) {
    if (Get.context == null) return;
    try {
      Get.snackbar(
        title,
        body.isNotEmpty ? body : "Tap to view details",
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFF1E1E28),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderRadius: 14,
        borderColor: AppColors.buttonColor.withOpacity(0.4),
        borderWidth: 1,
        icon: (imageUrl != null && imageUrl.isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_active,
                    color: AppColors.buttonColor,
                    size: 26,
                  ),
                ),
              )
            : const Icon(
                Icons.notifications_active,
                color: AppColors.buttonColor,
                size: 26,
              ),
        onTap: (_) {
          handleSystemNotificationTap(data);
        },
      );
    } catch (e) {
      debugPrint("⚠️ _showInAppNotificationBanner error: $e");
    }
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
