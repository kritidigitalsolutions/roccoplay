import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final Map<String, dynamic> params;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    required this.params,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  double _loadingProgress = 0.0;
  bool _isRedirected = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            debugPrint("🔍 WebView Page Started: $url");
          },
          onPageFinished: (String url) {
            _checkRedirect(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint("🔍 WebView Navigation Request: ${request.url}");
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadPaymentForm();
  }

  void _loadPaymentForm() {
    // Generate HTML with auto-submitting form containing post parameters
    // This is the most reliable way to submit a POST form in WKWebView / WebView
    final buffer = StringBuffer();
    buffer.write('<html><head><title>Redirecting...</title></head>');
    buffer.write('<body onload="document.forms[0].submit()">');
    buffer.write('<form action="${widget.paymentUrl}" method="POST">');
    
    widget.params.forEach((key, value) {
      buffer.write('<input type="hidden" name="$key" value="${_escapeHtml(value.toString())}"/>');
    });
    
    buffer.write('</form>');
    buffer.write('</body></html>');

    final htmlContent = buffer.toString();
    _controller.loadHtmlString(htmlContent);
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  bool _checkRedirect(String url) {
    debugPrint("🔍 WebView Navigated to URL: $url");
    if (_isRedirected) return true;

    // Only match actual HTTP/HTTPS URL navigations
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    // Check if the URL contains the callback redirect pattern
    if (url.contains('/payment/zaakpay/callback') || url.contains('/zaakpay/response') || url.contains('zaakpay/callback') ||
        url.contains('/payment/hdfc/callback') || url.contains('hdfc/callback') || url.contains('/hdfc/response')) {
      if (mounted) {
        setState(() {
          _isRedirected = true;
        });
      }
      debugPrint("🎯 Callback URL fully loaded onPageFinished! Closing WebView and returning success.");
      Get.back(result: true);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.grey[950],
        title: const Text(
          "Secure Payment",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Confirm cancellation
            Get.dialog(
              AlertDialog(
                backgroundColor: Colors.grey[900],
                title: const Text("Cancel Payment?", style: TextStyle(color: Colors.white)),
                content: const Text(
                  "Are you sure you want to cancel the payment process?",
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("No", style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back(); // Close dialog
                      Get.back(result: false); // Close WebView
                    },
                    child: const Text("Yes, Cancel", style: TextStyle(color: Colors.pinkAccent)),
                  ),
                ],
              ),
            );
          },
        ),
        bottom: _loadingProgress < 1.0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3.0),
                child: LinearProgressIndicator(
                  value: _loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isRedirected)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.pinkAccent),
                    const SizedBox(height: 20),
                    const Text(
                      "Processing Payment...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Please do not close this screen or press back.",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
