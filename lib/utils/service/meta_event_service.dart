import 'package:facebook_app_events/facebook_app_events.dart';

class MetaEventService {
  MetaEventService._();

  static final MetaEventService instance = MetaEventService._();

  final FacebookAppEvents _facebookAppEvents = FacebookAppEvents();

  /// Meta Event: App Install / App Open
  /// (Facebook SDK detects first-time install automatically when this fires)
  Future<void> activateApp() async {
    try {
      await _facebookAppEvents.activateApp();
    } catch (_) {}
  }

  /// Meta Event: Login Success
  Future<void> login({String method = "mobile"}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: "login",
        parameters: {"method": method},
      );
    } catch (_) {}
  }

  /// Meta Event: Registration Complete
  Future<void> register({String method = "mobile"}) async {
    try {
      await _facebookAppEvents.logEvent(
        name: "CompleteRegistration",
        parameters: {"method": method},
      );
    } catch (_) {}
  }

  /// Meta Event: Logout
  Future<void> logout() async {
    try {
      await _facebookAppEvents.logEvent(name: "logout");
    } catch (_) {}
  }

  /// Meta Event: Subscription Started (before payment is confirmed)
  Future<void> subscriptionStart({
    required String planId,
    required int amount,
    required String currency,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: "InitiatedCheckout",
        parameters: {"plan_id": planId, "value": amount, "currency": currency},
      );
    } catch (_) {}
  }

  /// Meta Event: Final Payment / Purchase Complete
  Future<void> paymentComplete({
    required double amount,
    required String currency,
    required String planId,
  }) async {
    try {
      await _facebookAppEvents.logPurchase(amount: amount, currency: currency);
      await _facebookAppEvents.logEvent(
        name: "SubscriptionComplete",
        parameters: {"plan_id": planId, "value": amount, "currency": currency},
      );
    } catch (_) {}
  }

  /// Meta Event: Video Play
  Future<void> videoPlay({
    required String contentId,
    required String contentName,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: "video_play",
        parameters: {"content_id": contentId, "content_name": contentName},
      );
    } catch (_) {}
  }

  /// Meta Event: Download Content
  Future<void> download({
    required String contentId,
    required String contentName,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: "download",
        parameters: {"content_id": contentId, "content_name": contentName},
      );
    } catch (_) {}
  }

  // /// Meta Event: Bookmark Content
  Future<void> bookmark({
    required String contentId,
    required String contentName,
  }) async {
    try {
      await _facebookAppEvents.logEvent(
        name: "Liked",
        parameters: {"content_id": contentId, "content_name": contentName},
      );
    } catch (_) {}
  }
}
