import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../view_model/content_controller/content_controller.dart';
import '../navbar/bottomNavbar.dart';
import '../dramaDetails/dramaDetailsPage.dart';
import 'auto_slider.dart';
import 'coming_soon.dart';
import '../navbar/downloads.dart';
import '../../widgets/home_slider_section.dart';
import '../search_pages/searchPage.dart';
import 'top_10_list.dart';
import '../auth/signInPage.dart';
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
    final notificationService = NotificationService.to;

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
        backgroundColor: AppColors.black,
        body: Stack(
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
                      notificationService,
                    ),
                    const SearchPage(),
                    const GoPremiumPage(),
                    const DownloadsPage(),

                    /// ✅ ONLY PROFILE HERE
                    ProfilePage(
                      onLogout: () {
                        controller.logout();
                        authController.setLoginStatus(false);
                      },
                    ),
                  ],
                ),
              ),
            ),

            /// ✅ BOTTOM NAVBAR
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
                        Get.to(() => const SignInPage());
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
    );
  }

  /// 🔹 HOME CONTENT
  Widget _buildHomeContent(
    BuildContext context,
    HomeController controller,
    AuthController authController,
    ContentController contentController,
    NotificationService notificationService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset('assets/images/roccoplay_logo.png', height: 40),
              Row(
                children: [
                  Obx(() {
                    int unreadCount = notificationService.notifications
                        .where((n) => n['isRead'] == false)
                        .length;
                    return Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            Get.to(() => const NotificationPage());
                          },
                          icon: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 28),
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
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
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
                  }),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () {
                        Get.to(() => const GoPremiumPage());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text(
                        "Go Premium",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// SCROLL
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                contentController.fetchContent(),
                contentController.fetchCategories(),
              ]);
            },
            color: AppColors.buttonColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 15),

                  Obx(() {
                    if (contentController.isLoading.value &&
                        contentController.categories.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(color: AppColors.buttonColor),
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
                            .map((category) {
                          final categoryContent = contentController.allContent
                              .where((c) =>
                                  c.category.contains(category.slug) &&
                                  c.isComingSoon == false)
                              .toList();

                          if (categoryContent.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          if (category.slug == 'top10') {
                            return Column(
                              children: [
                                Top10List(
                                  content: categoryContent,
                                  isSignedIn: authController.isLoggedIn.value,
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                HomeSliderSection(
                                  title: category.name,
                                  content: categoryContent,
                                  isSignedIn: authController.isLoggedIn.value,
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          }
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
                      "${info['country']} - ${info['postalCode']}"
                    ];

                    final address = addressList
                        .where((e) => e != null && e.toString().trim().isNotEmpty)
                        .join(", ");

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          Image.asset('assets/images/roccoplay_logo.png', height: 50),
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
    )],
    );
  }
}
