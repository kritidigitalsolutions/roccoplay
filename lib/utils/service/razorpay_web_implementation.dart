import 'dart:js_interop';

@JS('checkoutRazorpay')
external void _checkoutRazorpay(JSAny? options, JSFunction onSuccess, JSFunction onFailure);

class RazorpayWebService {
  static void checkout({
    required Map<String, dynamic> options,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String errorMessage) onFailure,
  }) {
    _checkoutRazorpay(
      options.jsify(),
      ((JSString paymentId, JSString orderId, JSString signature) {
        onSuccess(paymentId.toDart, orderId.toDart, signature.toDart);
      }).toJS,
      ((JSString errorMessage) {
        onFailure(errorMessage.toDart);
      }).toJS,
    );
  }
}
