import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../navbar/bottomNavbar.dart';
import '../dramaDetails/dramaDetailsPage.dart';
import '../../utils/app_session.dart';
import 'auto_slider.dart';
import 'coming_soon.dart';
import '../navbar/downloads.dart';
import '../../widgets/home_slider_section.dart';
import '../search_pages/searchPage.dart';
import 'top_10_list.dart';
import '../auth/signInPage.dart';
import '../premium/goPremium.dart';
import '../profile/profilePage.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});

  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> {
  int _selectedIndex = 0;
  bool isLoggedIn = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<String> webSeriesImages = [
    "assets/images/taskaree.jpg",
    "assets/images/sahid_teri_bato.jpg",
    "assets/images/farzi.jpg",
    "assets/images/khaki.webp",
    "assets/images/kota_factory.jpg",
    "assets/images/asur.webp",
    "assets/images/asur2.jpeg",
  ];

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    bool login = await AppSession.getLogin();
    setState(() {
      isLoggedIn = login;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          /// PAGE CONTENT
          SafeArea(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeContent(),
                const SearchPage(),
                GoPremiumPage(),
                DownloadsPage(),
                isLoggedIn
                    ? ProfilePage(
                        onLogout: () {
                          setState(() {
                            isLoggedIn = false;
                            _selectedIndex = 0;
                          });
                        },
                      )
                    : SignInPage(
                        // onLoginSuccess: () {
                        //   setState(() {
                        //     isLoggedIn = true;
                        //     _selectedIndex = 4; // go to Profile
                        //   });
                        // },
                      ),
              ],
            ),
          ),

          if (_selectedIndex != 2 && !(_selectedIndex == 4 && !isLoggedIn))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavbar(
                selectedIndex: _selectedIndex,
                onItemTapped: _onItemTapped,
                isLoggedIn: isLoggedIn,
              ),
            ),
        ],
      ),
    );
  }

  /// 🔹 HOME CONTENT
  Widget _buildHomeContent() {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GoPremiumPage()),
                    );
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
              // InkWell(
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => LanguagePage()),
              //     );
              //   },
              //   child: const Icon(
              //     Icons.language,
              //     color: Colors.white,
              //     size: 28,
              //   ),
              // ),
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

                AutoSlider(
                  images: [
                    "assets/images/sahid_teri_bato.jpg",
                    "assets/images/farzi.jpg",
                    "assets/images/khaki.webp",
                    "assets/images/kota_factory.jpg",
                    "assets/images/taskaree.jpg",
                    "assets/images/asur.webp",
                    "assets/images/asur2.jpeg",
                  ],
                  isSignedIn: isLoggedIn,
                ),

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

                SizedBox(
                  height: 170,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: webSeriesImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DramaDetailsPage(isSignedIn: isLoggedIn),
                              ),
                            );
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              webSeriesImages[index],
                              width: 130,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),
                Top10List(
                  images: [
                    "assets/images/sahid_teri_bato.jpg",
                    "assets/images/farzi.jpg",
                    "assets/images/khaki.webp",
                    "assets/images/kota_factory.jpg",
                    "assets/images/taskaree.jpg",
                    "assets/images/asur.webp",
                    "assets/images/asur2.jpeg",
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "Mela",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),

                ComingSoonSection(
                  items: [
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
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "tranding Now",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),

                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "New in RoccoPlay",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),

                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),
                const SizedBox(height: 10),
                HomeSliderSection(
                  title: "RoccoPlay Orginal",
                  items: [
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 1"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 2"},
                    {"image": "assets/images/sahid_teri_bato.jpg", "title": "Movie 3"},
                    {"image": "assets/images/asur.webp", "title": "Movie 4"},
                    {"image": "assets/images/asur.webp", "title": "Movie 5"},
                  ],
                ),

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
