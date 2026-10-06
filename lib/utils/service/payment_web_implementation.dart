import 'dart:html' as html;

class PaymentWebHelper {
  static void submitPostForm(String url, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      html.window.open(url, '_blank');
      return;
    }

    final form = html.FormElement()
      ..action = url
      ..method = 'POST'
      ..target = '_blank';

    params.forEach((key, value) {
      final input = html.InputElement()
        ..type = 'hidden'
        ..name = key
        ..value = value?.toString() ?? '';
      form.append(input);
    });

    html.document.body?.append(form);
    form.submit();
    form.remove();
  }
}
