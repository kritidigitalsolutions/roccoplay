import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';

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
      debugPrint("⏳ Throttling banner ad request: delaying by ${delayMs}ms");
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (!mounted) return;

    banner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner Loaded");
          if (mounted) {
            setState(() {
              isLoaded = true;
            });
          }
        },

        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner Failed: ${error.message}");
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

    if (!isLoaded || banner == null) {
      return const SizedBox();
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
