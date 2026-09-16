import 'dart:async';

class ScriptLoader {
  static Future<void> loadScript(String url) async {
    // No-op on non-web platforms
    return;
  }
}
