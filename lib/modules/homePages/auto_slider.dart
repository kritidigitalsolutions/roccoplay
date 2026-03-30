import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../dramaDetails/dramaDetailsPage.dart';
import '../premium/goPremium.dart';
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

class _AutoSliderState extends State<AutoSlider> {
  late PageController _pageController;
  int currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.75,
      initialPage: 1000,
    );
    currentPage = 1000;

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.content.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        currentPage++;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void didUpdateWidget(AutoSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content.length != widget.content.length) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.content.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: _pageController,
            itemCount: null,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = widget.content[index % widget.content.length];
              double scale = currentPage == index ? 1 : 0.9;

              return TweenAnimationBuilder(
                tween: Tween<double>(begin: scale, end: scale),
                duration: const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      Get.to(() => DramaDetailsPage(isSignedIn: widget.isSignedIn, content: item));
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            item.banner,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset("assets/images/farzi.jpg", fit: BoxFit.cover),
                          ),
                          Container(
                            color: AppColors.black.withOpacity(0.3),
                          ),
                          Positioned(
                            bottom: 25,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (!widget.isSignedIn) {
                                      Get.to(() => const SignInPage());
                                    } else {
                                      Get.to(() => const GoPremiumPage());
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.buttonColor,
                                  ),
                                  child: Text(
                                    widget.isSignedIn ? "Subscribe" : "Sign In",
                                    style: const TextStyle(color: AppColors.buttonTextColor),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 18,
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
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = _pageController.hasClients ? (_pageController.page ?? currentPage.toDouble()) : currentPage.toDouble();
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                double diff = (page - page.round()).abs();
                int distanceFromCenter = (index - 2).abs();
                double scale = distanceFromCenter == 0 ? 1.4 - (diff * 0.4) : (distanceFromCenter == 1 ? 1.0 - (diff * 0.2) : 0.8);
                double opacity = distanceFromCenter == 0 ? 1.0 : (distanceFromCenter == 1 ? 0.6 : 0.3);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}
