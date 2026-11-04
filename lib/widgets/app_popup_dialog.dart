import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/theme/app_colors.dart';
import '../data/models/response_model/popup_model/app_popup_model.dart';
import '../view_model/popup_controller/popup_controller.dart';

class AppPopupDialog extends StatefulWidget {
  final AppPopupItemModel popup;

  const AppPopupDialog({super.key, required this.popup});

  static const Map<String, String> imageHeaders = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': 'image/*,*/*;q=0.8',
  };

  static String normalizeImageUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty || trimmed == 'null') return '';
    if (trimmed.startsWith('//')) {
      trimmed = 'https:$trimmed';
    } else if (trimmed.startsWith('/') && !trimmed.startsWith('//')) {
      trimmed = 'https://api.roccoplay.in$trimmed';
    }
    return trimmed.replaceAll(' ', '%20');
  }

  static List<String> getCandidateUrls(AppPopupItemModel popup) {
    return [
      normalizeImageUrl(popup.imageUrl),
      normalizeImageUrl(popup.content?.banner ?? ''),
      normalizeImageUrl(popup.content?.poster ?? ''),
    ].where((u) => u.isNotEmpty && u.startsWith('http')).toList();
  }

  static ImageProvider getImageProvider(String url) {
    return NetworkImage(url, headers: imageHeaders);
  }

  @override
  State<AppPopupDialog> createState() => _AppPopupDialogState();
}

class _AppPopupDialogState extends State<AppPopupDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    // ⏱️ 20-second smooth countdown indicator
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Widget _buildImage(String url, double height, List<String> fallbackUrls) {
    if (url.isEmpty) return const SizedBox.shrink();

    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      headers: AppPopupDialog.imageHeaders,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("⚠️ [AppPopupDialog] Failed primary image $url: $error");
        if (fallbackUrls.length > 1 && fallbackUrls[1] != url) {
          return Image.network(
            fallbackUrls[1],
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            headers: AppPopupDialog.imageHeaders,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AppPopupController>();
    final size = MediaQuery.of(context).size;
    final double dialogWidth = (size.width > 600) ? 420 : size.width * 0.88;
    final double imageHeight = (size.height > 800) ? 290 : 230;

    final String displayTitle =
        widget.popup.content?.title.isNotEmpty == true
            ? widget.popup.content!.title
            : '';
    final String displayType = widget.popup.contentType.toUpperCase();

    // 🖼️ Collect and normalize candidate image URLs
    final List<String> candidateUrls =
        AppPopupDialog.getCandidateUrls(widget.popup);
    final String primaryImageUrl =
        candidateUrls.isNotEmpty ? candidateUrls.first : '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        controller.onDismissClicked();
      },
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: dialogWidth,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF14141E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.buttonColor.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.buttonColor.withOpacity(0.22),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.7),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /// 🖼️ REAL POPUP BANNER IMAGE (NO dummy placeholders)
                      if (primaryImageUrl.isNotEmpty)
                        Stack(
                          children: [
                            Container(
                              height: imageHeight,
                              width: double.infinity,
                              color: const Color(0xFF14141E),
                              child: _buildImage(
                                primaryImageUrl,
                                imageHeight,
                                candidateUrls,
                              ),
                            ),

                            /// Gradient overlay at bottom of image
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 85,
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Color(0xFF14141E),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            /// 🏷️ CONTENT TYPE BADGE (Top-Left)
                            if (displayType.isNotEmpty)
                              Positioned(
                                top: 14,
                                left: 14,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 6,
                                      sigmaY: 6,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.buttonColor
                                              .withOpacity(0.6),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: AppColors.buttonColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            displayType,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      /// 📝 POPUP CONTENT DETAILS
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Content Title
                            if (displayTitle.isNotEmpty) ...[
                              Text(
                                displayTitle,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                            ],

                            /// Description
                            if (widget.popup.description.isNotEmpty) ...[
                              Text(
                                widget.popup.description,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.78),
                                  fontSize: 13.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                            ] else
                              const SizedBox(height: 10),

                            /// 🎬 ACTION BUTTON ("Watch Now")
                            Obx(
                              () => SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: controller.isActionLoading.value
                                      ? null
                                      : () =>
                                          controller.onWatchNowClicked(context),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.buttonColor,
                                          Color(0xFF9A1B47),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.buttonColor
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: controller.isActionLoading.value
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  widget.popup.actionButtonText
                                                          .isNotEmpty
                                                      ? widget.popup.actionButtonText
                                                      : "Watch Now",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 0.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// ⏳ 20s AUTO-DISMISS ANIMATED PROGRESS BAR
                      AnimatedBuilder(
                        animation: _timerController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: 1.0 - _timerController.value,
                            backgroundColor: Colors.white.withOpacity(0.06),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.buttonColor,
                            ),
                            minHeight: 2.5,
                          );
                        },
                      ),
                    ],
                  ),

                  /// ❌ TOP-RIGHT CLOSE BUTTON
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: controller.onDismissClicked,
                        borderRadius: BorderRadius.circular(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
