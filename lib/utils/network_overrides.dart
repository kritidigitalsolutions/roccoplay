import 'dart:io';

class AuditNetworkOverrides extends HttpOverrides {
  static String proxyStr = "DIRECT";

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) {
        return proxyStr;
      }
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
