import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';
import 'web_ad_view.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> with AutomaticKeepAliveClientMixin {
  BannerAd? banner;
  bool isLoaded = false;
  static DateTime? _lastLoadTime;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    loadBanner();
  }

  Future<void> loadBanner() async {
    if (kIsWeb) return;
    final now = DateTime.now();
    int delayMs = 0;
    if (_lastLoadTime != null) {
      final diffMs = now.difference(_lastLoadTime!).inMilliseconds;
      if (diffMs < 1500) {
        delayMs = 1500 - diffMs;
      }
    }
    
    _lastLoadTime = now.add(Duration(milliseconds: delayMs));

    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (!mounted) return;

    banner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              isLoaded = true;
            });
          }
        },

        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) {
            setState(() {
              banner = null;
              isLoaded = false;
            });
          }
        },
      ),
    );

    banner!.load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (kIsWeb) {
      return Center(
        child: WebAdSenseView(
          adClient: AdHelper.adSenseClient,
          adSlot: AdHelper.adSenseBannerSlot,
          height: 90,
        ),
      );
    }

    if (!isLoaded || banner == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: banner!.size.height.toDouble(),
      width: banner!.size.width.toDouble(),
      child: AdWidget(ad: banner!),
    );
  }

  @override
  void dispose() {
    banner?.dispose();
    super.dispose();
  }
}
