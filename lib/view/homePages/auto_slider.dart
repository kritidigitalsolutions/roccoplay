import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/view_model/primium_controller/premium_controller.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../app/theme/app_colors.dart';

class AutoSlider extends StatefulWidget {
  final List<ContentModel> content;
  final bool isSignedIn;

  const AutoSlider({
    super.key,
    required this.content,
    required this.isSignedIn,
  });

  @override
  State<AutoSlider> createState() => _AutoSliderState();
}

// ... (existing imports)

class _AutoSliderState extends State<AutoSlider> {
  late PageController _pageController;
  int currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Default PageController, will be updated in build if necessary
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 1000,
    );
    currentPage = 1000;
    _startTimer();
  }

  void _startTimer() {
    if (_timer?.isActive ?? false) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        currentPage++;
        _pageController.animateToPage(
          currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PremiumController premiumController = Get.put(PremiumController());
    double screenWidth = MediaQuery.of(context).size.width;
    bool isWeb = screenWidth > 800;

    if (widget.content.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    // Adjust viewportFraction based on screen size
    double viewportFraction = 0.8;
    if (_pageController.viewportFraction != viewportFraction) {
      _pageController = PageController(
        viewportFraction: viewportFraction,
        initialPage: currentPage,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        double sliderHeight;
        if (isWeb) {
          // Responsive height for web banners: maintain a cinematic aspect ratio (e.g., 2.3:1)
          sliderHeight = (constraints.maxWidth * viewportFraction) / 2.3;
          // Clamp to reasonable limits for web
          if (sliderHeight > 600) sliderHeight = 600;
          if (sliderHeight < 350) sliderHeight = 350;
        } else {
          // Responsive height for mobile posters (approx 2:3 aspect ratio)
          sliderHeight = (constraints.maxWidth * viewportFraction) / 0.7;
          double screenHeight = MediaQuery.of(context).size.height;
          if (sliderHeight > screenHeight * 0.55) sliderHeight = screenHeight * 0.55;
        }

        return Column(
          children: [
            SizedBox(
              height: sliderHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: null,
                onPageChanged: (index) => setState(() => currentPage = index),
                itemBuilder: (context, index) {
                  final item = widget.content[index % widget.content.length];
                  double scale = currentPage == index ? 1 : 0.85;

                  return TweenAnimationBuilder(
                    tween: Tween<double>(begin: scale, end: scale),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _AutoSliderHoverItem(
                        item: item,
                        isWeb: isWeb,
                        isSignedIn: widget.isSignedIn,
                        onInteractionStart: _stopTimer,
                        onInteractionEnd: _startTimer,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            // ... Pagination dots Row ...
          ],
        );
      },
    );
  }
}

class _AutoSliderHoverItem extends StatefulWidget {
  final ContentModel item;
  final bool isWeb;
  final bool isSignedIn;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  const _AutoSliderHoverItem({
    required this.item,
    required this.isWeb,
    required this.isSignedIn,
    required this.onInteractionStart,
    required this.onInteractionEnd,
  });

  @override
  State<_AutoSliderHoverItem> createState() => _AutoSliderHoverItemState();
}

class _AutoSliderHoverItemState extends State<_AutoSliderHoverItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final PremiumController premiumController = Get.find<PremiumController>();

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onInteractionStart();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onInteractionEnd();
      },
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: _isHovered && widget.isWeb
                ? [
                    BoxShadow(
                      color: AppColors.buttonColor.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ]
                : [],
          ),
          child: GestureDetector(
            onTap: () {
              Get.toNamed(AppRoutes.dramaDetails, arguments: widget.item);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.isWeb ? widget.item.banner : widget.item.poster,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                    ),
                  ),
                  Container(color: AppColors.black.withOpacity(0.3)),
                  Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Obx(() {
                          final sub = premiumController.subscriptionData.value;
                          final bool isPurchased = sub != null && sub['status'] == 'active';

                          return ElevatedButton(
                            onPressed: () async {
                              if (!widget.isSignedIn) {
                                FocusManager.instance.primaryFocus?.unfocus();
                                widget.onInteractionStart();

                                await Get.toNamed(AppRoutes.signIn);

                                widget.onInteractionEnd();
                              } else if (!isPurchased) {
                                Get.toNamed(AppRoutes.goPremium);
                              } else {
                                Get.toNamed(
                                  AppRoutes.dramaDetails,
                                  arguments: widget.item,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonColor,
                            ),
                            child: Text(
                              !widget.isSignedIn
                                  ? "Sign In"
                                  : (isPurchased ? "Play Video" : "Subscribe"),
                              style: TextStyle(
                                color: AppColors.buttonTextColor,
                                fontSize: widget.isWeb ? 16 : 14,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Text(
                          widget.item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: widget.isWeb ? 24 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
