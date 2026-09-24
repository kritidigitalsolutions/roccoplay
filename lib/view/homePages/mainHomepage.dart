import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import 'package:roccoplay/utils/service/web_reload_helper.dart';
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

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  late final HomeController controller;
  late final AuthController authController;
  late final PremiumController premiumController;
  late final ContentController contentController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    contentController = Get.put(ContentController());
    controller = Get.put(HomeController());
    authController = Get.find<AuthController>();
    premiumController = Get.find<PremiumController>();
    
    // ✅ Sync index with initial route
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.updateIndexFromRoute();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔄 Logo click handler: Web pe full reload karo, Mobile pe home pe scroll karo aur content refresh karo
  Future<void> _handleLogoClick() async {
    if (kIsWeb) {
      performWebReload();
      return;
    }

    controller.onItemTapped(0);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    List<Future> refreshTasks = [
      contentController.fetchContent(),
      contentController.fetchCategories(),
      controller.fetchCompanyInfo(),
    ];

    if (authController.isLoggedIn.value) {
      refreshTasks.add(authController.getProfile());
      refreshTasks.add(premiumController.fetchAllSubscriptionStatus());
    }

    await Future.wait(refreshTasks);
  }

  Future<void> _launchStoreUrl(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService.to;

    return LayoutBuilder(builder: (context, constraints) {
      bool isWeb = constraints.maxWidth > 800;

      return PopScope(
        canPop: controller.selectedIndex.value == 0, // Allow pop only if on Home tab
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;

          // If not on Home tab, go back to Home tab
          if (controller.selectedIndex.value != 0) {
            controller.onItemTapped(0);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.9), // Slightly more opaque since no blur
        border: const Border(bottom: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _handleLogoClick,
              child: Image.asset('assets/images/roccoplay_logo.png', height: 45),
            ),
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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _handleLogoClick,
                    child: Image.asset('assets/images/roccoplay_logo.png', height: 40),
                  ),
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
                refreshTasks.add(premiumController.fetchAllSubscriptionStatus());
              }

              await Future.wait(refreshTasks);
            },
            color: AppColors.buttonColor,
            child: SingleChildScrollView(
              controller: _scrollController,
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

                    // Use precomputed category content map instead of filtering in build()
                    final catMap = contentController.categoryContentMap;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 1. 🔥 TOP SLIDER (Trending)
                        if (contentController.trendingContent.isNotEmpty)
                          RepaintBoundary(
                            child: Column(
                              children: [
                                AutoSlider(
                                  content: contentController.trendingContent,
                                  isSignedIn: authController.isLoggedIn.value,
                                ),
                                const SizedBox(height: 25),
                              ],
                            ),
                          ),

                        /// 2. 🔹 OTHER CATEGORIES (Strictly alternating vertical & horizontal layouts)
                        ...() {
                          final visibleCategories = contentController.categories
                              .where((cat) => cat.slug != 'trending')
                              .where((cat) {
                                final items = catMap[cat.slug];
                                return items != null && items.isNotEmpty;
                              })
                              .toList();

                          bool nextIsHorizontal = false; // Alternates: 1st vertical, 2nd horizontal, 3rd vertical...
                          final List<Widget> categoryWidgets = [];

                          for (int i = 0; i < visibleCategories.length; i++) {
                            final category = visibleCategories[i];
                            final categoryContent = catMap[category.slug]!;

                            // Dynamic detection of Top 10 category
                            final cleanSlug = category.slug
                                .toLowerCase()
                                .replaceAll(RegExp(r'[-_\s]'), '');
                            final cleanName = category.name
                                .toLowerCase()
                                .replaceAll(RegExp(r'[-_\s]'), '');
                            final isTop10 = cleanSlug == 'top10' ||
                                cleanName == 'top10' ||
                                category.layout == 'top10';

                            // Dynamically alternate layout
                            final bool isHorizontal;
                            if (isTop10) {
                              // Top 10 is always Horizontal Cards with Big Digits
                              isHorizontal = true;
                              nextIsHorizontal = false; // Next alternates to Vertical
                            } else {
                              isHorizontal = nextIsHorizontal;
                              nextIsHorizontal = !nextIsHorizontal;
                            }

                            Widget categoryWidget;
                            if (isTop10) {
                              categoryWidget = RepaintBoundary(
                                child: Column(
                                  children: [
                                    Top10List(
                                      title: category.name.isNotEmpty
                                          ? category.name
                                          : "Top 10",
                                      content: categoryContent,
                                      isSignedIn:
                                          authController.isLoggedIn.value,
                                      isHorizontal: isHorizontal,
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              );
                            } else {
                              categoryWidget = RepaintBoundary(
                                child: Column(
                                  children: [
                                    HomeSliderSection(
                                      title: category.name,
                                      content: categoryContent,
                                      isSignedIn:
                                          authController.isLoggedIn.value,
                                      isHorizontal: isHorizontal,
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              );
                            }

                            categoryWidgets.add(categoryWidget);

                            // 🔥 Har 2 categories ke baad ek Banner Ad
                            if ((i + 1) % 2 == 0) {
                              categoryWidgets.add(
                                Center(
                                  child: BannerAdWidget(
                                    key: ValueKey('home_category_ad_$i'),
                                  ),
                                ),
                              );
                              categoryWidgets.add(const SizedBox(height: 15));
                            }
                          }

                          return categoryWidgets;
                        }(),


                        /// 3. 🔹 COMING SOON (uses precomputed list)
                        ComingSoonSection(
                          content: contentController.comingSoonContent,
                          isSignedIn: authController.isLoggedIn.value,
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 40),

                  /// 🔹 COMPANY INFO & STORE LINKS (Footer)
                  _buildFooter(controller),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🔹 COMPANY INFO & STORE LINKS (Footer)
  Widget _buildFooter(HomeController controller) {
    return Obx(() {
      final info = controller.companyInfo.value;
      final addressList = [
        if (info != null) info['addressLine1'],
        if (info != null &&
            info['addressLine2'] != null &&
            info['addressLine2'] != "i don't have one")
          info['addressLine2'],
        if (info != null) info['city'],
        if (info != null) info['state'],
        if (info != null && info['country'] != null)
          "${info['country']} - ${info['postalCode'] ?? ''}",
      ];

      final address = addressList
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .join(", ");

      final playStoreUrl = (info != null &&
              info['playStoreUrl'] != null &&
              info['playStoreUrl'].toString().isNotEmpty)
          ? info['playStoreUrl']
          : 'https://play.google.com/store/apps/details?id=com.roccoplay';

      final appStoreUrl = (info != null &&
              info['appStoreUrl'] != null &&
              info['appStoreUrl'].toString().isNotEmpty)
          ? info['appStoreUrl']
          : 'https://apps.apple.com';

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
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _handleLogoClick,
                child: Image.asset(
                  'assets/images/roccoplay_logo.png',
                  height: 50,
                ),
              ),
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

            if (address.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                "Office Address",
                style: TextStyle(
                  color: AppColors.buttonColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                address,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],

            if (kIsWeb) ...[
              const SizedBox(height: 25),

              /// 🔹 ALL POLICIES
              const Text(
                "Quick Links & Legal Policies",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.privacyPolicy),
                    child: const Text(
                      "Privacy Policy",
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                    ),
                  ),
                  const Text("|", style: TextStyle(color: Colors.white24)),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.termsAndConditions),
                    child: const Text(
                      "Terms & Conditions",
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                    ),
                  ),
                  const Text("|", style: TextStyle(color: Colors.white24)),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.refundPolicy),
                    child: const Text(
                      "Refund Policy",
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                    ),
                  ),
                  const Text("|", style: TextStyle(color: Colors.white24)),
                  TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.help),
                    child: const Text(
                      "Help & Support",
                      style: TextStyle(color: Colors.lightBlueAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              /// 🔹 APP STORE & PLAY STORE LINKS
              const Text(
                "Download Rocco Play App",
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 15,
                runSpacing: 10,
                children: [
                  /// Google Play Store Button
                  OutlinedButton.icon(
                    onPressed: () => _launchStoreUrl(playStoreUrl),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.android, color: Colors.greenAccent, size: 22),
                    label: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "GET IT ON",
                          style: TextStyle(fontSize: 9, color: Colors.white60),
                        ),
                        Text(
                          "Google Play",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Apple App Store Button
                  OutlinedButton.icon(
                    onPressed: () => _launchStoreUrl(appStoreUrl),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.apple, color: Colors.white, size: 24),
                    label: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Download on the",
                          style: TextStyle(fontSize: 9, color: Colors.white60),
                        ),
                        Text(
                          "App Store",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "© ${DateTime.now().year} Rocco Play. All rights reserved.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
