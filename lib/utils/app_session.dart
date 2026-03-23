// import 'package:shared_preferences/shared_preferences.dart';
//
// class AppSession {
//
//   static const String loginKey = "isLoggedIn";
//
//   /// Save login status
//   static Future<void> setLogin(bool value) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(loginKey, value);
//   }
//
//   /// Get login status
//   static Future<bool> getLogin() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(loginKey) ?? false;
//   }
//
//   /// Logout
//   static Future<void> clearLogin() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove(loginKey);
//   }
// }

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
}

