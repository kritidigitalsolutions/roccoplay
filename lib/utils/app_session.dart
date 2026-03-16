import 'package:shared_preferences/shared_preferences.dart';

class AppSession {

  static const String loginKey = "isLoggedIn";

  /// Save login status
  static Future<void> setLogin(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(loginKey, value);
  }

  /// Get login status
  static Future<bool> getLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(loginKey) ?? false;
  }

  /// Logout
  static Future<void> clearLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(loginKey);
  }
}
