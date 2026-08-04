import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseAnalyticsService {
  FirebaseAnalyticsService._();

  static final FirebaseAnalyticsService instance = FirebaseAnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Turn this off before release builds if you don't want console noise.
  static const bool _debugLogging = true;

  void _log(String eventName, {Map<String, dynamic>? params, Object? error}) {
    if (!_debugLogging) return;
    if (error != null) {
      debugPrint('❌ [Analytics] "$eventName" FAILED → $error');
    } else {
      debugPrint(
        '✅ [Analytics] "$eventName" fired ${params != null ? "→ $params" : ""}',
      );
    }
  }

  // --- App Open ---------------------------------------------------------------

  /// Firebase Event: App activated / opened
  Future<void> activateApp() async {
    try {
      await _analytics.logAppOpen();
      _log('app_open');
    } catch (e) {
      _log('app_open', error: e);
    }
  }

  // --- Auth --------------------------------------------------------------------

  /// Firebase Event: Login
  Future<void> login({String method = "mobile"}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      _log('login', params: {'method': method});
    } catch (e) {
      _log('login', error: e);
    }
  }

  /// Firebase Event: Registration / Sign Up
  Future<void> register({String method = "mobile"}) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      _log('sign_up', params: {'method': method});
    } catch (e) {
      _log('sign_up', error: e);
    }
  }

  /// Firebase Event: Logout (custom event)
  Future<void> logout() async {
    try {
      await _analytics.logEvent(name: "logout");
      _log('logout');
    } catch (e) {
      _log('logout', error: e);
    }
  }

  // --- Subscription / Payment --------------------------------------------------

  /// Firebase Event: Checkout initiated (subscription start)
  Future<void> subscriptionStart({
    required String planId,
    required int amount,
    required String currency,
  }) async {
    try {
      await _analytics.logBeginCheckout(
        value: amount.toDouble(),
        currency: currency,
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: planId,
            currency: currency,
            price: amount.toDouble(),
          ),
        ],
      );
      _log(
        'begin_checkout',
        params: {'planId': planId, 'amount': amount, 'currency': currency},
      );
    } catch (e) {
      _log('begin_checkout', error: e);
    }
  }

  /// Firebase Event: Purchase complete
  Future<void> paymentComplete({
    required double amount,
    required String currency,
    required String planId,
  }) async {
    try {
      await _analytics.logPurchase(
        value: amount,
        currency: currency,
        transactionId: planId,
        items: [
          AnalyticsEventItem(
            itemId: planId,
            itemName: planId,
            currency: currency,
            price: amount,
          ),
        ],
      );
      _log(
        'purchase',
        params: {'planId': planId, 'amount': amount, 'currency': currency},
      );
    } catch (e) {
      _log('purchase', error: e);
    }
  }

  // --- Content -----------------------------------------------------------------

  /// Firebase Event: Video play
  Future<void> videoPlay({
    required String contentId,
    required String contentName,
  }) async {
    try {
      await _analytics.logSelectContent(
        contentType: "video",
        itemId: contentId,
      );
      await _analytics.logEvent(
        name: "video_play",
        parameters: {"content_id": contentId, "content_name": contentName},
      );
      _log(
        'video_play',
        params: {'content_id': contentId, 'content_name': contentName},
      );
    } catch (e) {
      _log('video_play', error: e);
    }
  }

  /// Firebase Event: Download content
  Future<void> download({
    required String contentId,
    required String contentName,
  }) async {
    try {
      await _analytics.logEvent(
        name: "download",
        parameters: {"content_id": contentId, "content_name": contentName},
      );
      _log(
        'download',
        params: {'content_id': contentId, 'content_name': contentName},
      );
    } catch (e) {
      _log('download', error: e);
    }
  }

  /// Firebase Event: Bookmark / Like content
  Future<void> bookmark({
    required String contentId,
    required String contentName,
  }) async {
    try {
      await _analytics.logEvent(
        name: "liked",
        parameters: {"content_id": contentId, "content_name": contentName},
      );
      _log(
        'liked',
        params: {'content_id': contentId, 'content_name': contentName},
      );
    } catch (e) {
      _log('liked', error: e);
    }
  }
}
