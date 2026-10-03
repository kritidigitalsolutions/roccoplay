import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/app/theme/app_colors.dart';
import 'package:roccoplay/view_model/content_controller/content_controller.dart';
import 'package:roccoplay/view_model/search_controller/search_controller.dart';

class TrendingSearchesPage extends StatelessWidget {
  const TrendingSearchesPage({super.key});

  List<String> _getTrendingTitles(ContentController contentController) {
    final Set<String> titles = {};

    // 1. Titles from trendingContent
    for (final item in contentController.trendingContent) {
      if (item.title.trim().isNotEmpty) {
        titles.add(item.title.trim());
      }
    }

    // 2. Titles from allContent with isTrending
    for (final item in contentController.allContent) {
      if (item.isTrending && item.title.trim().isNotEmpty) {
        titles.add(item.title.trim());
      }
    }

    // 3. Additional curated popular series / movie titles
    final defaultTitles = [
      "Love vs Crime",
      "Khiladi No.1",
      "Blackmail",
      "Fareb",
      "Dhokha",
      "Aakhri Sauda",
    ];

    for (final t in defaultTitles) {
      titles.add(t);
    }

    return titles.toList();
  }

  List<String> _getTrendingGenres(ContentController contentController) {
    final Set<String> genres = {};

    // 1. Genres from allContent
    for (final item in contentController.allContent) {
      for (final g in item.genre) {
        if (g.trim().isNotEmpty) {
          genres.add(g.trim());
        }
      }
    }

    // 2. Default genres
    final defaultGenres = [
      "Romance",
      "Crime",
      "Thriller",
      "Suspense",
      "Action",
      "Drama",
      "Mystery",
    ];

    for (final g in defaultGenres) {
      genres.add(g);
    }

    return genres.toList();
  }

  void _onSelectSuggestion(BuildContext context, String suggestion) {
    if (Get.isRegistered<AppSearchController>()) {
      final searchCtrl = Get.find<AppSearchController>();
      searchCtrl.searchController.text = suggestion;
      searchCtrl.updateSearchQuery(suggestion);
    }
    Get.back(result: suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final contentController = Get.find<ContentController>();
    final trendingTitles = _getTrendingTitles(contentController);
    final trendingGenres = _getTrendingGenres(contentController);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWeb = screenWidth > 800;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 850 : double.infinity),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🔙 TOP HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        splashRadius: 22,
                        onPressed: () => Get.back(),
                      ),
                      const SizedBox(width: 6),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "🔥 Trending ",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            TextSpan(
                              text: "Searches",
                              style: TextStyle(
                                color: AppColors.buttonColor,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white10, height: 1),

                /// 🔽 SCROLLABLE CONTENT
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// SECTION 1: POPULAR TITLES
                        const Text(
                          "Popular Shows & Movies",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Tap any search term to find matching shows and movies instantly.",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: trendingTitles.map((title) {
                            return _buildSearchChip(context, title);
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        /// SECTION 2: TRENDING GENRES
                        const Text(
                          "Popular Genres & Themes",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Explore trending genres curated for you.",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),

                        Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: trendingGenres.map((genre) {
                            return _buildSearchChip(context, genre);
                          }).toList(),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchChip(BuildContext context, String text) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onSelectSuggestion(context, text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search,
                size: 15,
                color: AppColors.buttonColor,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
