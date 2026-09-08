import 'dart:js' as js;
import 'package:js/js.dart' show allowInterop;

class RazorpayWebService {
  static void checkout({
    required Map<String, dynamic> options,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String errorMessage) onFailure,
  }) {
    js.context.callMethod('checkoutRazorpay', [
      js.JsObject.jsify(options),
      allowInterop((paymentId, orderId, signature) {
        onSuccess(paymentId, orderId, signature);
      }),
      allowInterop((errorMessage) {
        onFailure(errorMessage);
      }),
    ]);
  }
}
