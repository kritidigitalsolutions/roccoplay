import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? banner;
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    loadBanner();
  }

  void loadBanner() {
    banner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),

      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Banner Loaded");

          setState(() {
            isLoaded = true;
          });
        },

        onAdFailedToLoad: (ad, error) {
          debugPrint("Banner Failed: ${error.message}");

          ad.dispose();

          setState(() {
            banner = null;
            isLoaded = false;
          });
        },
      ),
    );

    banner!.load();
  }

  @override
  Widget build(BuildContext context) {
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
