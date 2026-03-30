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

class MainHomePage extends StatelessWidget {
  const MainHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ContentController contentController = Get.put(ContentController());
    final HomeController controller = Get.put(HomeController());
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          /// PAGE CONTENT
          SafeArea(
            child: Obx(() => IndexedStack(
              index: controller.selectedIndex.value,
              children: [
                _buildHomeContent(context, controller, authController, contentController),
                const SearchPage(),
                const GoPremiumPage(),
                DownloadsPage(),
                authController.isLoggedIn.value
                    ? ProfilePage(
                        onLogout: () {
                          controller.logout();
                          authController.setLoginStatus(false);
                        },
                      )
                    : const SignInPage(),
              ],
            )),
          ),

          Obx(() {
            int selectedIndex = controller.selectedIndex.value;
            bool isLoggedIn = authController.isLoggedIn.value;
            
            if (selectedIndex != 2 && !(selectedIndex == 4 && !isLoggedIn)) {
              return Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomBottomNavbar(
                  selectedIndex: selectedIndex,
                  onItemTapped: controller.onItemTapped,
                  isLoggedIn: isLoggedIn,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// 🔹 HOME CONTENT
  Widget _buildHomeContent(BuildContext context, HomeController controller, AuthController authController, ContentController contentController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/roccoplay_logo.png', height: 40),
                ],
              ),

              SizedBox(
                width: 110,
                height: 22,
                child: ElevatedButton(
                  onPressed: () {
                    Get.to(() => const GoPremiumPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    alignment: Alignment.centerLeft,
                  ),
                  child: const Text(
                    "Go Premium",
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// SCROLLABLE CONTENT
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),

                Obx(() => AutoSlider(
                  content: contentController.trendingContent,
                  isSignedIn: authController.isLoggedIn.value,
                )),

                const SizedBox(height: 25),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Web Series",
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Obx(() => SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: contentController.allContent.where((c) => c.contentType == 'series').length,
                    itemBuilder: (context, index) {
                      final item = contentController.allContent.where((c) => c.contentType == 'series').toList()[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GestureDetector(
                          onTap: () {
                            Get.to(() => DramaDetailsPage(
                              isSignedIn: authController.isLoggedIn.value,
                              content: item,
                            ));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(
                              item.poster,
                              width: 130,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                "assets/images/farzi.jpg",
                                width: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )),

                const SizedBox(height: 10),
                
                Obx(() => Top10List(
                  content: contentController.allContent.where((c) => c.category.contains('top10')).toList(),
                  isSignedIn: authController.isLoggedIn.value,
                )),

                const SizedBox(height: 10),
                
                Obx(() => HomeSliderSection(
                  title: "Movies",
                  content: contentController.allContent.where((c) => c.contentType == 'movie').toList(),
                  isSignedIn: authController.isLoggedIn.value,
                )),

                const SizedBox(height: 10),

                ComingSoonSection(
                  items: const [
                    {"image": "assets/images/asur.webp", "date": "1 March"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "date": "15 march"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "date": "10 April"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "date": "15 march"},
                    {
                      "image": "assets/images/sahid_teri_bato.jpg",
                      "date": "Coming Soon",
                    },
                    {
                      "image": "assets/images/sahid_teri_bato.jpg",
                      "date": "Coming Soon",
                    },
                  ],
                ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "tranding Now",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                //
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "New in RoccoPlay",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                //
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),
                // const SizedBox(height: 10),
                // HomeSliderSection(
                //   title: "RoccoPlay Orginal",
                //   items: [
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                //     {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 4"},
                //     {"image": "assets/images/asur.webp", "title": "Movie 5"},
                //   ],
                // ),

                const SizedBox(height: 50),

                /// 🏢 COMPANY FOOTER
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/roccoplay_logo.png',
                        height: 60,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "RoccoPlay",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Your ultimate destination for entertainment.",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 120), // Extra space for navbar
              ],
            ),
          ),
        ),
      ],
    );
  }
}
