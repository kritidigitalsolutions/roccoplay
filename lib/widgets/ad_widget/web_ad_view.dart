import 'package:flutter/material.dart';
import 'web_ad_view_stub.dart'
    if (dart.library.html) 'web_ad_view_web.dart';

class WebAdSenseView extends StatelessWidget {
  final String adClient;
  final String adSlot;
  final double height;

  const WebAdSenseView({
    super.key,
    required this.adClient,
    required this.adSlot,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return getWebAdView(adClient, adSlot, height: height);
  }
}
