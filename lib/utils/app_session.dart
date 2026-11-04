
import 'package:hive/hive.dart';

class AppSession {
  static const String boxName = "appBox";
  static const String loginKey = "isLoggedIn";
  static const String tokenKey = "token";

  /// Save login status
  static Future<void> setLogin(bool value) async {
    var box = Hive.box(boxName);
    await box.put(loginKey, value);
  }

  /// Get login status
  static bool getLogin() {
    var box = Hive.box(boxName);
    return box.get(loginKey, defaultValue: false);
  }

  /// Save Token
  static Future<void> setToken(String token) async {
    var box = Hive.box(boxName);
    await box.put(tokenKey, token);
  }

  /// Get Token
  static String? getToken() {
    var box = Hive.box(boxName);
    return box.get(tokenKey);
  }

  /// Logout (clear all session data)
  static Future<void> clearSession() async {
    var box = Hive.box(boxName);
    await box.delete(loginKey);
    await box.delete(tokenKey);
  }

  /// 🎁 Check if a popup action has already been completed in local storage
  static bool isPopupCompleted(String popupId) {
    if (popupId.isEmpty) return false;
    try {
      var box = Hive.box(boxName);
      return box.get('popup_completed_$popupId', defaultValue: false) == true;
    } catch (_) {
      return false;
    }
  }

  /// 💾 Save popup action completed in local storage
  static Future<void> setPopupCompleted(String popupId) async {
    if (popupId.isEmpty) return;
    try {
      var box = Hive.box(boxName);
      await box.put('popup_completed_$popupId', true);
    } catch (_) {}
  }
}

