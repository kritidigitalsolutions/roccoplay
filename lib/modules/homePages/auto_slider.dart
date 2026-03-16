import 'dart:async';
import 'package:flutter/material.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import '../dramaDetails/dramaDetailsPage.dart';
import '../premium/goPremium.dart';
import '../../app/theme/app_colors.dart';

class AutoSlider extends StatefulWidget {
  final List<String> images;
  final bool isSignedIn;

  const AutoSlider({
    super.key,
    required this.images,
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
      initialPage: 1000, // infinite effect
    );

    currentPage = 1000;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      currentPage++;

      _pageController.animateToPage(
        currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🔥 SLIDER
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: PageView.builder(
            controller: _pageController,
            itemCount: null, // Infinite
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final imageIndex =
                  index % widget.images.length;

              double scale =
              currentPage == index ? 1 : 0.9;

              return TweenAnimationBuilder(
                tween:
                Tween<double>(begin: scale, end: scale),
                duration:
                const Duration(milliseconds: 400),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DramaDetailsPage(
                                isSignedIn:
                                widget.isSignedIn,
                              ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            widget.images[imageIndex],
                            fit: BoxFit.cover,
                          ),

                          /// Dark Overlay
                          Container(
                            color: AppColors.black
                                .withOpacity(0.3),
                          ),

                          /// Bottom Content
                          Positioned(
                            bottom: 25,
                            left: 0,
                            right: 0,
                            child: Column(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    if (!widget
                                        .isSignedIn) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                              SignInPage(),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                              GoPremiumPage(),
                                        ),
                                      );
                                    }
                                  },
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    AppColors
                                        .buttonColor,
                                  ),
                                  child: Text(
                                    widget.isSignedIn
                                        ? "Subscribe"
                                        : "Sign In",
                                    style:
                                    const TextStyle(
                                      color: AppColors
                                          .buttonTextColor,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                    height: 8),

                                const Text(
                                  "Movie Title",
                                  style: TextStyle(
                                    color:
                                    AppColors.white,
                                    fontSize: 18,
                                    fontWeight:
                                    FontWeight.bold,
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

        /// 🔥 DOT INDICATOR
        SizedBox(height: 18),

        AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = 0;

            if (_pageController.hasClients &&
                _pageController.page != null) {
              page = _pageController.page!;
            } else {
              page = currentPage.toDouble();
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                double diff = (page - page.round()).abs();

                // Distance from center (2 is center index)
                int distanceFromCenter = (index - 2).abs();

                double scale;
                double opacity;

                if (distanceFromCenter == 0) {
                  // Center dot
                  scale = 1.4 - (diff * 0.4);
                  opacity = 1.0;
                } else if (distanceFromCenter == 1) {
                  scale = 1.0 - (diff * 0.2);
                  opacity = 0.6;
                } else {
                  scale = 0.8;
                  opacity = 0.3;
                }

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 4),
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
