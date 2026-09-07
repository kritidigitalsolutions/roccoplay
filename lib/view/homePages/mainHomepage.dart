import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import 'package:roccoplay/widgets/ad_widget/banner_ad_widget.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/content_controller/content_controller.dart';
import '../../view_model/primium_controller/premium_controller.dart';
import '../navbar/bottomNavbar.dart';
import '../navbar/downloads.dart';
import 'auto_slider.dart';
import 'coming_soon.dart';
import '../../widgets/home_slider_section.dart';
import '../search_pages/searchPage.dart';
import 'top_10_list.dart';
import '../premium/goPremium.dart';
import '../profile/profilePage.dart';
import '../../view_model/home_controller/home_controller.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../utils/notification_service.dart';
import '../notifications/notification_page.dart';

class MainHomePage extends StatelessWidget {
  const MainHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ContentController contentController = Get.put(ContentController());
    final HomeController controller = Get.put(HomeController());
    final AuthController authController = Get.find<AuthController>();
    final PremiumController premiumController = Get.find<PremiumController>();
    final notificationService = NotificationService.to;

    return LayoutBuilder(builder: (context, constraints) {
      bool isWeb = constraints.maxWidth > 800;

      return PopScope(
        canPop: false, // ❌ direct pop disable
        onPopInvoked: (didPop) {
          final controller = Get.find<HomeController>();

          if (controller.selectedIndex.value != 0) {
            controller.selectedIndex.value = 0; // ✅ Home pe le jao
          } else {
            Navigator.of(context).pop(); // ✅ App exit
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: isWeb
                ? const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0F0F1A),
                        AppColors.black,
                      ],
                    ),
                  )
                : const BoxDecoration(color: AppColors.black),
            child: Column(
              children: [
              /// ✅ WEB TOP NAVBAR
              if (isWeb) _buildWebTopNavbar(controller, authController, premiumController, notificationService),

              Expanded(
                child: Stack(
                  children: [
                    /// ✅ PAGE CONTENT
                    SafeArea(
                      child: Obx(
                        () => IndexedStack(
                          index: controller.selectedIndex.value,
                          children: [
                            _buildHomeContent(
                              context,
                              controller,
                              authController,
                              contentController,
                              premiumController,
                              notificationService,
                              isWeb,
                            ),
                            const SearchPage(),
                            const GoPremiumPage(),
                            const DownloadsPage(),

                            /// ✅ ONLY PROFILE HERE
                            ProfilePage(
                              onLogout: () {
                                MetaEventService.instance.logout();
                                FirebaseAnalyticsService.instance.logout();
                                controller.logout();
                                authController.setLoginStatus(false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    /// ✅ BOTTOM NAVBAR (Mobile Only)
                    if (!isWeb)
                      Obx(() {
                        int selectedIndex = controller.selectedIndex.value;
                        bool isLoggedIn = authController.isLoggedIn.value;

                        if (selectedIndex != 2) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: CustomBottomNavbar(
                              selectedIndex: selectedIndex,
                              onItemTapped: (index) {
                                /// 🔥 LOGIN GUARD
                                if (index == 4 && !isLoggedIn) {
                                  Get.toNamed(AppRoutes.signIn);
                                  return;
                                }

                                controller.onItemTapped(index);
                              },
                              isLoggedIn: isLoggedIn,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ));
    });
  }

  /// 🔹 WEB TOP NAVBAR
  Widget _buildWebTopNavbar(
    HomeController controller,
    AuthController authController,
    PremiumController premiumController,
    NotificationService notificationService,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => controller.selectedIndex.value = 0,
                child: Image.asset('assets/images/roccoplay_logo.png', height: 45),
              ),
              const Spacer(),
              _webSearchIcon(controller),
              const SizedBox(width: 15),
              _notificationIcon(notificationService),
              const SizedBox(width: 20),
              _premiumButton(premiumController),
              const SizedBox(width: 20),
                  Obx(() {
                    bool isLoggedIn = authController.isLoggedIn.value;
                    return IconButton(
                      icon: Icon(
                        isLoggedIn ? Icons.account_circle : Icons.login,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        if (isLoggedIn) {
                          controller.selectedIndex.value = 4; // Profile
                        } else {
                          Get.toNamed(AppRoutes.signIn);
                        }
                      },
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webSearchIcon(HomeController controller) {
    return Obx(() {
      bool isSelected = controller.selectedIndex.value == 1;
      return IconButton(
        onPressed: () => controller.selectedIndex.value = 1,
        icon: Icon(
          Icons.search,
          color: isSelected ? AppColors.buttonColor : Colors.white,
          size: 28,
        ),
      );
    });
  }

  /// 🔹 NOTIFICATION ICON
  Widget _notificationIcon(NotificationService notificationService) {
    return Obx(() {
      int unreadCount = notificationService.notifications
          .where((n) => n['isRead'] == false)
          .length;
      return Stack(
        children: [
          IconButton(
            onPressed: () => Get.toNamed(AppRoutes.notifications),
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }

  /// 🔹 PREMIUM BUTTON
  Widget _premiumButton(PremiumController premiumController) {
    return Obx(() {
      final bool hasActive = premiumController.hasActiveSubscription;
      return ElevatedButton(
        onPressed: () => Get.toNamed(AppRoutes.goPremium),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasActive ? Colors.green : AppColors.buttonColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        child: Text(
          hasActive ? "Premium Active" : "Subscribe Now",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      );
    });
  }

  /// 🔹 HOME CONTENT
  Widget _buildHomeContent(
    BuildContext context,
    HomeController controller,
    AuthController authController,
    ContentController contentController,
    PremiumController premiumController,
    NotificationService notificationService,
    bool isWeb,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER (Mobile Only)
        if (!isWeb)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => controller.selectedIndex.value = 0,
                  child: Image.asset('assets/images/roccoplay_logo.png', height: 40),
                ),
                Row(
                  children: [
                    _notificationIcon(notificationService),
                    const SizedBox(width: 8),
                    _premiumButton(premiumController),
                  ],
                ),
              ],
            ),
          ),

        /// SCROLL
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              List<Future> refreshTasks = [
                contentController.fetchContent(),
                contentController.fetchCategories(),
              ];

              if (authController.isLoggedIn.value) {
                refreshTasks.add(authController.getProfile());
                refreshTasks.add(premiumController.fetchSubscriptionStatus());
              }

              await Future.wait(refreshTasks);
            },
            color: AppColors.buttonColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: const BannerAdWidget()),
                  const SizedBox(height: 15),

                  Obx(() {
                    if (contentController.isLoading.value &&
                        contentController.categories.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: AppColors.buttonColor,
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 1. 🔥 TOP SLIDER (Trending)
                        if (contentController.trendingContent.isNotEmpty)
                          Column(
                            children: [
                              AutoSlider(
                                content: contentController.trendingContent,
                                isSignedIn: authController.isLoggedIn.value,
                              ),
                              const SizedBox(height: 25),
                            ],
                          ),

                        /// 2. 🔹 OTHER CATEGORIES
                        ...contentController.categories
                            .where((cat) => cat.slug != 'trending')
                            .toList()
                            .asMap()
                            .entries
                            .expand((entry) {
                              final index = entry.key;
                              final category = entry.value;
                              final categoryContent = contentController
                                  .allContent
                                  .where(
                                    (c) =>
                                        c.category.contains(category.slug) &&
                                        c.isComingSoon == false,
                                  )
                                  .toList();

                              if (categoryContent.isEmpty) {
                                return <Widget>[];
                              }

                              Widget categoryWidget;
                              if (category.slug == 'top10') {
                                categoryWidget = Column(
                                  children: [
                                    Top10List(
                                      content: categoryContent,
                                      isSignedIn:
                                          authController.isLoggedIn.value,
                                      isHorizontal: isWeb && (index % 2 == 0),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              } else {
                                categoryWidget = Column(
                                  children: [
                                    HomeSliderSection(
                                      title: category.name,
                                      content: categoryContent,
                                      isSignedIn:
                                          authController.isLoggedIn.value,
                                      isHorizontal: isWeb && (index % 2 == 0),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                );
                              }

                              // 🔥 Har 2 categories ke baad ek Banner Ad
                              if ((index + 1) % 2 == 0) {
                                return [
                                  categoryWidget,
                                  Center(
                                    child: BannerAdWidget(
                                      key: ValueKey('home_category_ad_$index'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ];
                              }
                              return [categoryWidget];
                            }),

                        /// 3. 🔹 COMING SOON
                        ComingSoonSection(
                          content: contentController.allContent
                              .where((c) => c.isComingSoon == true)
                              .toList(),
                          isSignedIn: authController.isLoggedIn.value,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 40),

                  /// 🔹 COMPANY INFO (Footer)
                  Obx(() {
                    final info = controller.companyInfo.value;
                    if (info != null && info['status'] == 'published') {
                      final addressList = [
                        info['addressLine1'],
                        if (info['addressLine2'] != null &&
                            info['addressLine2'] != "i don't have one")
                          info['addressLine2'],
                        info['city'],
                        info['state'],
                        "${info['country']} - ${info['postalCode']}",
                      ];

                      final address = addressList
                          .where(
                            (e) => e != null && e.toString().trim().isNotEmpty,
                          )
                          .join(", ");

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 30,
                          horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/roccoplay_logo.png',
                              height: 50,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "ROCCO PLAY",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              "Office Address",
                              style: TextStyle(
                                color: AppColors.buttonColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              address,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => Get.toNamed(AppRoutes.privacyPolicy),
                                  child: const Text(
                                    "Privacy Policy",
                                    style: TextStyle(color: Colors.blue, fontSize: 12),
                                  ),
                                ),
                                const Text(" | ", style: TextStyle(color: Colors.white24)),
                                TextButton(
                                  onPressed: () => Get.toNamed(AppRoutes.termsAndConditions),
                                  child: const Text(
                                    "Terms & Conditions",
                                    style: TextStyle(color: Colors.blue, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "© ${DateTime.now().year} Rocco Play. All rights reserved.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
