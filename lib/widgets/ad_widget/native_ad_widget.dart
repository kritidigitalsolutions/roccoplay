import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/helper/ad_helper.dart';

/// ✅ Native Ad Widget (Template based)
/// Use: Search page, Download page, Series details me spaces pe
class NativeAdWidget extends StatefulWidget {
  final TemplateType adType;
  final BoxConstraints? constraints; // 👈 Custom constraints (optional)

  const NativeAdWidget({
    super.key,
    this.adType = TemplateType.medium,
    this.constraints,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint("✅ Native Ad Loaded");
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint("❌ Native Ad Failed: ${error.message}");
          ad.dispose();
          if (mounted) {
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.adType,
        mainBackgroundColor: Colors.grey[900],
        cornerRadius: 10.0,
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  /// 🎯 Default constraints based on adType
  BoxConstraints _defaultConstraints() {
    final isSmall = widget.adType == TemplateType.small;
    return BoxConstraints(
      minWidth: 320,
      minHeight: isSmall ? 80 : 320,
      maxWidth: 400,
      maxHeight: isSmall ? 100 : 400,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ConstrainedBox(
        constraints:
            widget.constraints ?? _defaultConstraints(), // 👈 custom ya default
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
