import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../app/theme/app_colors.dart';
import '../../utils/custom_snackbar.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  final Map<String, dynamic>? params;

  const PaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.orderId,
    this.params,
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
    debugPrint("💳 [WEBVIEW INIT] Order ID: ${widget.orderId}");
    debugPrint("🌐 [WEBVIEW INIT] Payment URL: ${widget.paymentUrl}");
    debugPrint("📦 [WEBVIEW INIT] Params: ${widget.params}");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);

    // Bypass SSL for HDFC UAT domain on Android
    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setUserAgent(
          "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36");
    }

    final navigationDelegate = NavigationDelegate(
      onProgress: (int progress) {
        if (mounted) {
          setState(() {
            _loadingProgress = progress / 100.0;
          });
        }
      },
      onPageStarted: (String url) {
        debugPrint("🌐 [WEBVIEW PAGE STARTED] $url");
        _checkRedirect(url);
      },
      onPageFinished: (String url) async {
        debugPrint("🏁 [WEBVIEW PAGE FINISHED] $url");
        if (_checkRedirect(url)) return;

        // Check if loaded page content displays payment result text
        try {
          final pageText = await _controller.runJavaScriptReturningResult(
            'document.body ? document.body.innerText : ""',
          );
          final text = pageText.toString().toLowerCase();
          final previewText = text.length > 200 ? text.substring(0, 200) : text;
          debugPrint("📄 [WEBVIEW PAGE TEXT PREVIEW] $previewText");

          if (text.contains('payment failed') ||
              text.contains('payment cancelled') ||
              text.contains('transaction failed') ||
              text.contains('payment decline') ||
              text.contains('payment declined') ||
              text.contains('payment error') ||
              text.contains('transaction cancelled')) {
            debugPrint("❌ [WEBVIEW PAGE TEXT MATCH] Failure content detected");
            _closeWebView(false);
          } else if (text.contains('payment successful') ||
              text.contains('subscription is active') ||
              text.contains('transaction successful') ||
              text.contains('payment success') ||
              text.contains('order: sp_') ||
              text.contains('order: hdfc_') ||
              text.contains('order: zk_')) {
            debugPrint("✅ [WEBVIEW PAGE TEXT MATCH] Success content detected");
            _closeWebView(true);
          }
        } catch (e) {
          debugPrint("⚠️ [WEBVIEW PAGE TEXT READ ERROR] $e");
        }
      },
      onWebResourceError: (WebResourceError error) {
        debugPrint("❌ [WEBVIEW RESOURCE ERROR] Code: ${error.errorCode}, Description: ${error.description}, URL: ${error.url}");
        CustomSnackbar.show(
          title: "Connection Error",
          message: "Failed to load payment page",
          isError: true,
        );
      },
      onNavigationRequest: (NavigationRequest request) async {
        debugPrint("🧭 [WEBVIEW NAV REQ] ${request.url}");
        if (_checkRedirect(request.url)) {
          return NavigationDecision.prevent;
        }

        // Handle UPI and third-party app schemes (upi://, intent://, tez://, phonepe://, paytmmp://, etc.)
        if (!request.url.startsWith('http://') &&
            !request.url.startsWith('https://') &&
            !request.url.startsWith('about:') &&
            !request.url.startsWith('data:') &&
            !request.url.startsWith('javascript:')) {
          _launchExternalUrl(request.url);
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
    );

    _controller.setNavigationDelegate(navigationDelegate);

    // Bypass SSL for HDFC UAT domain on Android
    if (navigationDelegate.platform is AndroidNavigationDelegate) {
      (navigationDelegate.platform as AndroidNavigationDelegate).setOnSSlAuthError((error) {
        final androidError = error as AndroidSslAuthError;
        debugPrint("⚠️ [WEBVIEW SSL ERROR] URL: ${androidError.url}");
        if (androidError.url.contains("hdfcuat.bank.in")) {
          androidError.proceed();
        } else {
          androidError.cancel();
        }
      });
    }

    _loadPayment();
  }

  void _loadPayment() {
    if (widget.params != null && widget.params!.isNotEmpty) {
      debugPrint("🚀 [WEBVIEW LOAD] Loading HTML POST Form");
      final buffer = StringBuffer();
      buffer.write('<html><head><title>Redirecting...</title></head>');
      buffer.write('<body onload="document.forms[0].submit()">');
      buffer.write('<form action="${widget.paymentUrl}" method="POST">');

      widget.params!.forEach((key, value) {
        buffer.write(
          '<input type="hidden" name="$key" value="${_escapeHtml(value.toString())}"/>',
        );
      });

      buffer.write('</form>');
      buffer.write('</body></html>');

      final htmlContent = buffer.toString();
      _controller.loadHtmlString(htmlContent);
    } else {
      debugPrint("🚀 [WEBVIEW LOAD] Loading GET Request: ${widget.paymentUrl}");
      _controller.loadRequest(Uri.parse(widget.paymentUrl));
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    debugPrint("📱 [WEBVIEW EXTERNAL LAUNCH] Attempting to launch app URL: $urlString");
    try {
      final uri = Uri.tryParse(urlString);

      if (urlString.startsWith('intent://') || urlString.startsWith('intent:')) {
        final upiUri = _parseIntentToUpiUri(urlString);
        if (upiUri != null) {
          debugPrint("🔀 [WEBVIEW EXTERNAL] Converted Intent to UPI URI: $upiUri");
          try {
            final launched = await launchUrl(
              upiUri,
              mode: LaunchMode.externalApplication,
            );
            if (launched) {
              debugPrint("✅ [WEBVIEW EXTERNAL] Successfully launched UPI app");
              return;
            }
          } catch (e) {
            debugPrint("⚠️ [WEBVIEW EXTERNAL] Failed launching parsed UPI URI: $e");
          }
        }

        if (uri != null) {
          try {
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint("📱 [WEBVIEW EXTERNAL] Raw Intent launch result: $launched");
          } catch (e) {
            debugPrint("⚠️ [WEBVIEW EXTERNAL] Failed launching raw Intent: $e");
          }
        }
      } else if (uri != null) {
        bool launched = false;
        try {
          launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint("📱 [WEBVIEW EXTERNAL] Direct app scheme launch result: $launched");
        } catch (e) {
          debugPrint("⚠️ [WEBVIEW EXTERNAL] Direct app scheme launch error: $e");
        }

        if (!launched &&
            uri.scheme != 'upi' &&
            uri.scheme != 'http' &&
            uri.scheme != 'https') {
          final upiFallbackStr =
              urlString.replaceFirst('${uri.scheme}://', 'upi://');
          final upiFallbackUri = Uri.tryParse(upiFallbackStr);
          if (upiFallbackUri != null) {
            try {
              final fallbackLaunched = await launchUrl(
                upiFallbackUri,
                mode: LaunchMode.externalApplication,
              );
              debugPrint("🔀 [WEBVIEW EXTERNAL] Fallback upi:// launch result: $fallbackLaunched");
            } catch (e) {
              debugPrint("⚠️ [WEBVIEW EXTERNAL] Fallback upi:// launch error: $e");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ [WEBVIEW EXTERNAL ERROR] Failed to launch $urlString: $e");
    }
  }

  Uri? _parseIntentToUpiUri(String urlString) {
    try {
      String payload = urlString;
      String scheme = 'upi';

      int intentIdx = urlString.indexOf('#Intent;');
      if (intentIdx != -1) {
        String intentMeta = urlString.substring(intentIdx + 8);
        payload = urlString.substring(0, intentIdx);

        final schemeMatch = RegExp(r'scheme=([^;]+)').firstMatch(intentMeta);
        if (schemeMatch != null) {
          scheme = schemeMatch.group(1) ?? 'upi';
        }
      }

      if (payload.startsWith('intent://')) {
        payload = payload.substring(9);
      } else if (payload.startsWith('intent:')) {
        payload = payload.substring(7);
      }

      String convertedUrl = '$scheme://$payload';
      return Uri.tryParse(convertedUrl);
    } catch (e) {
      debugPrint("⚠️ [WEBVIEW INTENT PARSE ERROR] $e");
      return null;
    }
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  void _showCancelDialog() {
    debugPrint("🛑 [WEBVIEW USER ACTION] User initiated payment cancellation dialog");
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Cancel Payment?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to cancel the payment process?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint("🟢 [WEBVIEW CANCEL DIALOG] User selected NO (Continue payment)");
              Get.back();
            },
            child: const Text(
              "No",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              debugPrint("🔴 [WEBVIEW CANCEL DIALOG] User selected YES (Confirm cancel)");
              if (Get.isDialogOpen == true) Get.back(); // Close dialog
              _closeWebView(false); // Close WebView with failure/cancelled status
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.pinkAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _closeWebView(bool isSuccess) {
    if (_isRedirected) return;
    _isRedirected = true;
    debugPrint("🔒 [WEBVIEW CLOSE] Returning result: isSuccess=$isSuccess");
    if (mounted) {
      Get.back(result: isSuccess);
    }
  }

  bool _checkRedirect(String url) {
    if (_isRedirected) return true;

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    final lowerUrl = url.toLowerCase();
    final uri = Uri.tryParse(url);
    final queryParams = uri?.queryParameters ?? {};

    // Check if the URL matches payment callback, response, or status endpoints
    bool isCallbackUrl = lowerUrl.contains('/callback') ||
        lowerUrl.contains('/response') ||
        lowerUrl.contains('/sabpaisa/status') ||
        lowerUrl.contains('/zaakpay/status') ||
        lowerUrl.contains('/hdfc/status') ||
        lowerUrl.contains('/payment/success') ||
        lowerUrl.contains('/payment/fail') ||
        lowerUrl.contains('/payment/cancel') ||
        lowerUrl.contains('/payment/status') ||
        lowerUrl.contains('sabpaisa/callback') ||
        lowerUrl.contains('sabpaisa/response') ||
        lowerUrl.contains('zaakpay/callback') ||
        lowerUrl.contains('zaakpay/response') ||
        lowerUrl.contains('hdfc/callback') ||
        lowerUrl.contains('hdfc/response');

    if (isCallbackUrl) {
      debugPrint("🎯 [WEBVIEW CALLBACK DETECTED] URL: $url");
      debugPrint("🔎 [WEBVIEW CALLBACK QUERY PARAMS] $queryParams");

      bool isFailure = lowerUrl.contains('cancel') ||
          lowerUrl.contains('fail') ||
          lowerUrl.contains('declined') ||
          lowerUrl.contains('error');

      // Also inspect query parameter values for failure indicators
      queryParams.forEach((key, val) {
        final lowerVal = val.toLowerCase();
        final lowerKey = key.toLowerCase();
        if (lowerKey.contains('status') ||
            lowerKey.contains('code') ||
            lowerKey.contains('msg') ||
            lowerKey.contains('result') ||
            lowerKey.contains('state')) {
          if (lowerVal.contains('fail') ||
              lowerVal.contains('cancel') ||
              lowerVal.contains('declin') ||
              lowerVal.contains('error') ||
              lowerVal.contains('abort') ||
              lowerVal == '0' ||
              lowerVal == 'false') {
            isFailure = true;
          }
        }
      });

      debugPrint("📊 [WEBVIEW CALLBACK RESULT] isFailure=$isFailure => Closing WebView with success=${!isFailure}");
      _closeWebView(!isFailure);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isRedirected) return; // Prevent back while processing
        _showCancelDialog();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: AppColors.background,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          title: const Text(
            "Secure Payment",
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              if (!_isRedirected) {
                _showCancelDialog();
              }
            },
          ),
          bottom: _loadingProgress < 1.0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3.0),
                  child: LinearProgressIndicator(
                    value: _loadingProgress,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.pinkAccent,
                    ),
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
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
