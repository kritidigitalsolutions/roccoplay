class RazorpayWebService {
  static void checkout({
    required Map<String, dynamic> options,
    required Function(String paymentId, String orderId, String signature) onSuccess,
    required Function(String errorMessage) onFailure,
  }) {
    // No-op for mobile
  }
}
