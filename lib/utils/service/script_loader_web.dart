import 'dart:async';
import 'dart:html' as html;

class ScriptLoader {
  static final Map<String, Future<void>> _loadedScripts = {};

  static Future<void> loadScript(String url) {
    if (_loadedScripts.containsKey(url)) {
      return _loadedScripts[url]!;
    }

    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src = url
      ..type = 'text/javascript'
      ..async = true;

    script.onLoad.listen((_) {
      completer.complete();
    });

    script.onError.listen((event) {
      completer.completeError('Failed to load script: $url');
      _loadedScripts.remove(url);
    });

    html.document.head?.append(script);
    _loadedScripts[url] = completer.future;

    return completer.future;
  }
}
