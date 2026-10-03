import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/app/routes/app_routes.dart';
import 'package:roccoplay/view_model/auth_controller/auth_controller.dart';
import 'package:roccoplay/view_model/content_controller/content_controller.dart';
import 'package:roccoplay/view_model/search_controller/search_controller.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../widgets/ad_widget/banner_ad_widget.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final AppSearchController controller;
  late final AuthController authController;
  late final ContentController contentController;

  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _querySubscription;
  StreamSubscription? _categorySubscription;

  final List<String> _filterCategories = const [
    "All",
    "Movies",
    "Web Series",
    "Artists",
    "Genres",
  ];

  List<ContentModel> _cachedTopSeries = [];

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AppSearchController>()
        ? Get.find<AppSearchController>()
        : Get.put(AppSearchController());
    authController = Get.find<AuthController>();
    contentController = Get.find<ContentController>();

    _computeTopSeries();

    // Reset content scroll offset to top whenever query or category changes
    _querySubscription = controller.searchQuery.listen((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    _categorySubscription = controller.selectedCategory.listen((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void dispose() {
    _querySubscription?.cancel();
    _categorySubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _computeTopSeries() {
    final List<ContentModel> topSeries = contentController.allContent
        .where((item) => item.contentType == 'series' && item.isComingSoon == false)
        .toList();

    topSeries.sort((a, b) {
      int likesA = contentController.contentLikes[a.id] ?? 0;
      int likesB = contentController.contentLikes[b.id] ?? 0;
      return likesB.compareTo(likesA);
    });

    _cachedTopSeries = topSeries;
  }

  bool _isVoiceSearching = false;

  Future<void> _startVoiceSearch() async {
    if (_isVoiceSearching) return;
    _isVoiceSearching = true;

    try {
      final result = await Get.toNamed(AppRoutes.searchWithMic);
      if (result != null && result is String && result.trim().isNotEmpty) {
        controller.searchController.text = result.trim();
        controller.updateSearchQuery(result.trim());
      }
    } catch (e) {
      debugPrint("Voice search error: $e");
    } finally {
      if (mounted) {
        _isVoiceSearching = false;
      }
    }
  }

  List<String> _getTrendingSuggestions() {
    final Set<String> suggestions = {};

    // 1. Gather from trending content
    for (final item in contentController.trendingContent) {
      if (item.title.trim().isNotEmpty) {
        suggestions.add(item.title.trim());
      }
      if (suggestions.length >= 4) break;
    }

    // 2. Gather from allContent if trending has few items
    if (suggestions.length < 4) {
      for (final item in contentController.allContent) {
        if (item.isTrending && item.title.trim().isNotEmpty) {
          suggestions.add(item.title.trim());
        }
        if (suggestions.length >= 4) break;
      }
    }

    // 3. Add top genres from existing content
    for (final item in contentController.allContent) {
      for (final g in item.genre) {
        if (g.trim().isNotEmpty && suggestions.length < 7) {
          suggestions.add(g.trim());
        }
      }
    }

    // 4. Fallback items if content is not loaded or sparse
    final fallbacks = [
      "Love vs Crime",
      "Khiladi No.1",
      "Blackmail",
      "Fareb",
      "Romance",
      "Crime",
      "Thriller",
    ];
    for (final fallback in fallbacks) {
      if (suggestions.length >= 7) break;
      suggestions.add(fallback);
    }

    return suggestions.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 800;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 850 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    /// 1. TOP COMPACT HEADER (Fixed position)
                    _buildHeader(),

                    const SizedBox(height: 12),

                    /// 2. PREMIUM SEARCH BAR (Fixed position)
                    _buildSearchBar(),

                    const SizedBox(height: 14),

                    /// 3. CATEGORY / FILTER CHIPS (Fixed position)
                    _buildFilterChips(),

                    const SizedBox(height: 10),

                    /// 4. ADS WIDGET (Fixed position)
                    const BannerAdWidget(),

                    /// 5. SEARCH RESULTS OR DISCOVERY VIEW (SCROLLABLE CONTENT AREA ONLY)
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 110),
                        child: Obx(() {
                          if (controller.searchQuery.value.trim().isNotEmpty) {
                            return _buildSearchResults(constraints.maxWidth);
                          } else {
                            return _buildDefaultDiscoveryView(context, isWeb, constraints.maxWidth);
                          }
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🌟 1. COMPACT TOP HEADER
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: "Sea",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: "rch",
                  style: TextStyle(
                    color: AppColors.buttonColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _startVoiceSearch,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B1B22),
                  border: Border.all(
                    color: AppColors.buttonColor.withOpacity(0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.buttonColor.withOpacity(0.12),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌟 2. PREMIUM SEARCH BAR
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E26),
              Color(0xFF131318),
            ],
          ),
          border: Border.all(
            color: AppColors.buttonColor.withOpacity(0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.buttonColor.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller.searchController,
          onChanged: (value) => controller.updateSearchQuery(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.buttonColor,
          decoration: InputDecoration(
            hintText: "Search for movies, shows & more...",
            hintStyle: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.search,
                color: AppColors.buttonColor,
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        splashRadius: 18,
                        onPressed: controller.clearSearch,
                      )
                    : const SizedBox.shrink()),
                IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white70, size: 20),
                  splashRadius: 18,
                  onPressed: _startVoiceSearch,
                ),
                const SizedBox(width: 4),
              ],
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  /// 🌟 3. SEARCH FILTERS / CATEGORIES
  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filterCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _filterCategories[index];
          return Obx(() {
            final isSelected = controller.selectedCategory.value == category;
            return GestureDetector(
              onTap: () {
                controller.setCategory(category);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.buttonColor : const Color(0xFF1B1B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.buttonColor
                        : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.buttonColor.withOpacity(0.35),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }

  /// 🌟 DEFAULT DISCOVERY VIEW (Trending Searches, Top Series, Real Artists)
  Widget _buildDefaultDiscoveryView(BuildContext context, bool isWeb, double screenWidth) {
    if (_cachedTopSeries.isEmpty && contentController.allContent.isNotEmpty) {
      _computeTopSeries();
    }

    final realArtists = _getRealArtists();
    final selectedCat = controller.selectedCategory.value;
    final int crossAxisCount = _getCrossAxisCount(screenWidth);

    // 1. Explicit "Artists" category filter with empty search query
    if (selectedCat == "Artists") {
      if (realArtists.isEmpty) {
        return _buildNoArtistsEmptyState();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildMatchingArtistsSection(realArtists),
        ],
      );
    }

    // 2. Explicit "Movies" category filter with empty search query
    if (selectedCat == "Movies") {
      final movies = contentController.allContent
          .where((item) => item.contentType.toLowerCase() == 'movie')
          .toList();
      if (movies.isEmpty) {
        return _buildEmptyState();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildSubSectionHeader("Movies", movies.length),
          const SizedBox(height: 8),
          _buildPosterGrid(movies, crossAxisCount),
        ],
      );
    }

    // 3. Explicit "Web Series" category filter with empty search query
    if (selectedCat == "Web Series") {
      final series = contentController.allContent
          .where((item) => item.contentType.toLowerCase() == 'series')
          .toList();
      if (series.isEmpty) {
        return _buildEmptyState();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _buildSubSectionHeader("Web Series", series.length),
          const SizedBox(height: 8),
          _buildPosterGrid(series, crossAxisCount),
        ],
      );
    }

    // 4. "All" or "Genres" category filter with empty search query
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),

        /// 4. TRENDING SEARCHES SECTION
        _buildTrendingSearches(),

        if (_cachedTopSeries.isNotEmpty) ...[
          const SizedBox(height: 24),
          /// 5. TOP SERIES CAROUSEL
          _buildTopSeries(isWeb),
        ],

        /// 6. REAL ARTISTS SECTION (ONLY RENDERED IF REAL ARTISTS EXIST!)
        /// When realArtists.isEmpty, the Artists section is COMPLETELY HIDDEN!
        if (realArtists.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildMatchingArtistsSection(realArtists),
        ],
      ],
    );
  }

  /// 🌟 4. TRENDING SEARCHES
  Widget _buildTrendingSearches() {
    final suggestions = _getTrendingSuggestions();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF191921),
              Color(0xFF121216),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text("🔥", style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      "Trending Searches",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    final selected = await Get.toNamed(AppRoutes.trendingSearches);
                    if (selected != null && selected is String && selected.trim().isNotEmpty) {
                      controller.searchController.text = selected.trim();
                      controller.updateSearchQuery(selected.trim());
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "See All",
                        style: TextStyle(
                          color: AppColors.buttonColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.buttonColor,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: suggestions.map((keyword) {
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    controller.searchController.text = keyword;
                    controller.updateSearchQuery(keyword);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22222B),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search,
                          size: 13,
                          color: AppColors.buttonColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          keyword,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 🌟 5. TOP SERIES (Horizontal Carousel with ~3 cards visible)
  Widget _buildTopSeries(bool isWeb) {
    if (_cachedTopSeries.isEmpty) {
      return const SizedBox.shrink();
    }

    final double posterWidth = isWeb ? 170.0 : 130.0;
    final double posterHeight = isWeb ? 250.0 : 190.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Top Series",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.categoryGrid,
                    arguments: {
                      'title': 'Top Series',
                      'content': _cachedTopSeries,
                    },
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "See All",
                      style: TextStyle(
                        color: AppColors.buttonColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.buttonColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: posterHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _cachedTopSeries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = _cachedTopSeries[index];
              final bool showNewBadge = index < 3 || item.releaseYear >= 2024;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Get.toNamed(
                    AppRoutes.dramaDetails,
                    arguments: item,
                  );
                },
                child: Container(
                  width: posterWidth,
                  height: posterHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF1B1B22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.poster,
                          width: posterWidth,
                          height: posterHeight,
                          fit: BoxFit.cover,
                          cacheWidth: (posterWidth * 2).toInt(),
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            "assets/images/farzi.jpg",
                            width: posterWidth,
                            height: posterHeight,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      // Bottom gradient overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 70,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // "NEW" Badge
                      if (showNewBadge)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF2A6D), AppColors.buttonColor],
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.buttonColor.withOpacity(0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              "NEW",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }



  Widget _buildArtistImage(String path) {
    final cleanPath = path.trim();
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return Image.network(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/images/user.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.person, color: Colors.white54, size: 32),
          ),
        ),
      );
    } else if (cleanPath.isNotEmpty && cleanPath.startsWith('assets/')) {
      return Image.asset(
        cleanPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.person, color: Colors.white54, size: 32),
        ),
      );
    }
    return Image.asset(
      'assets/images/user.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.person, color: Colors.white54, size: 32),
      ),
    );
  }

  /// 🎭 REAL ARTISTS HELPER (Uses ONLY real ContentModel.cast data from ContentController)
  List<Cast> _getRealArtists([String? query]) {
    final lower = query?.toLowerCase().trim() ?? "";
    final Map<String, Cast> uniqueArtists = {};

    for (final content in contentController.allContent) {
      if (content.cast != null) {
        for (final castMember in content.cast!) {
          final name = castMember.name.trim();
          // Filter out invalid/empty records and match query if provided
          if (name.isNotEmpty) {
            if (lower.isEmpty || name.toLowerCase().contains(lower)) {
              uniqueArtists.putIfAbsent(name.toLowerCase(), () => castMember);
            }
          }
        }
      }
    }

    return uniqueArtists.values.toList();
  }

  /// 📐 RESPONSIVE COLUMN CALCULATOR
  int _getCrossAxisCount(double width) {
    if (width > 1100) return 5;
    if (width > 800) return 4;
    if (width > 550) return 3;
    return 2;
  }

  /// 🌟 7. POLISHED EMPTY SEARCH STATE
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E26),
                border: Border.all(
                  color: AppColors.buttonColor.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonColor.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No results found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try searching for another movie, show or artist.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🌟 8. SEARCH RESULTS HEADER ("Search Results     1 Result")
  Widget _buildResultsHeader(int totalCount) {
    final countText = totalCount == 1 ? "1 Result" : "$totalCount Results";
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "Search Results",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.buttonColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              countText,
              style: const TextStyle(
                color: AppColors.buttonColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ SUBSECTION HEADER (e.g. "Web Series    3 Results")
  Widget _buildSubSectionHeader(String title, int count) {
    final countText = count == 1 ? "1 Result" : "$count Results";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            countText,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎬 POSTER CARD ITEM
  Widget _buildPosterCard(ContentModel item) {
    final bool isNew = item.releaseYear >= 2024 || item.isTrending;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Get.toNamed(
          AppRoutes.dramaDetails,
          arguments: item,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1B1B22),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.poster,
                      fit: BoxFit.cover,
                      cacheWidth: 360,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/images/farzi.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Subtle bottom gradient
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top Right Year Pill
                  if (item.releaseYear > 0)
                    Positioned(
                      top: 7,
                      right: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          "${item.releaseYear}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Top Left "NEW" Badge
                  if (isNew)
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2A6D), AppColors.buttonColor],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.buttonColor.withOpacity(0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Text(
                          "NEW",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.genre.isNotEmpty
                ? item.genre.first
                : (item.contentType.isNotEmpty ? item.contentType : item.language),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎬 RESPONSIVE POSTER GRID
  Widget _buildPosterGrid(List<ContentModel> items, int crossAxisCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.63,
        ),
        itemBuilder: (context, index) {
          return _buildPosterCard(items[index]);
        },
      ),
    );
  }

  /// 🎭 MATCHING ARTISTS SECTION (Uses real Cast objects from content)
  Widget _buildMatchingArtistsSection(List<Cast> artists) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubSectionHeader("Artists", artists.length),
        const SizedBox(height: 10),
        SizedBox(
          height: 105,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final artist = artists[index];
              final String name = artist.name.trim();
              final String imagePath = artist.image.trim();
              return GestureDetector(
                onTap: () {
                  Get.toNamed(
                    AppRoutes.castDetails,
                    arguments: {
                      'name': name,
                      'image': imagePath,
                    },
                  );
                },
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.buttonColor,
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.buttonColor.withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildArtistImage(imagePath),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 👤 NO ARTISTS EMPTY STATE (When "Artists" category is selected and 0 artists match)
  Widget _buildNoArtistsEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E1E26),
                border: Border.all(
                  color: AppColors.buttonColor.withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.buttonColor.withOpacity(0.12),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 36,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              "No Artists Found",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "No artists match your search.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🌟 MAIN SEARCH RESULTS DISPATCHER
  Widget _buildSearchResults(double screenWidth) {
    final matchingArtists = _getRealArtists(controller.searchQuery.value);
    final bool hasContent = controller.searchResults.isNotEmpty;
    final bool hasArtists = matchingArtists.isNotEmpty;

    // When "Artists" filter is specifically chosen:
    if (controller.selectedCategory.value == "Artists") {
      if (!hasArtists) {
        return _buildNoArtistsEmptyState();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(matchingArtists.length),
          const SizedBox(height: 8),
          _buildMatchingArtistsSection(matchingArtists),
        ],
      );
    }

    // Filter content based on category
    final List<ContentModel> movies = controller.searchResults
        .where((item) => item.contentType.toLowerCase() == 'movie')
        .toList();
    final List<ContentModel> series = controller.searchResults
        .where((item) => item.contentType.toLowerCase() == 'series')
        .toList();
    final List<ContentModel> others = controller.searchResults
        .where((item) =>
            item.contentType.toLowerCase() != 'movie' &&
            item.contentType.toLowerCase() != 'series')
        .toList();

    if (controller.selectedCategory.value == "Movies" && movies.isEmpty) {
      return _buildEmptyState();
    }
    if (controller.selectedCategory.value == "Web Series" && series.isEmpty) {
      return _buildEmptyState();
    }

    // When searching under other filters and nothing matches:
    if (!hasContent && !hasArtists) {
      return _buildEmptyState();
    }

    final int crossAxisCount = _getCrossAxisCount(screenWidth);

    // Compute total count based on active filter
    final int totalCount = controller.selectedCategory.value == "All"
        ? (controller.searchResults.length + matchingArtists.length)
        : (controller.selectedCategory.value == "Movies"
            ? movies.length
            : (controller.selectedCategory.value == "Web Series"
                ? series.length
                : controller.searchResults.length));

    final bool isMultiType = (movies.isNotEmpty ? 1 : 0) +
            (series.isNotEmpty ? 1 : 0) +
            (hasArtists ? 1 : 0) >
        1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Main Results Header: "Search Results       X Results"
        _buildResultsHeader(totalCount),

        const SizedBox(height: 8),

        /// Matching Artists: ONLY RENDERED WHEN hasArtists IS TRUE AND category is "All"!
        /// When hasArtists is false (0 results), this section is completely hidden!
        if (hasArtists && controller.selectedCategory.value == "All") ...[
          _buildMatchingArtistsSection(matchingArtists),
          const SizedBox(height: 18),
        ],

        /// If multiple types exist and category is "All", organize into clean subsections
        if (isMultiType && controller.selectedCategory.value == "All") ...[
          if (series.isNotEmpty) ...[
            _buildSubSectionHeader("Web Series", series.length),
            const SizedBox(height: 8),
            _buildPosterGrid(series, crossAxisCount),
            const SizedBox(height: 20),
          ],
          if (movies.isNotEmpty) ...[
            _buildSubSectionHeader("Movies", movies.length),
            const SizedBox(height: 8),
            _buildPosterGrid(movies, crossAxisCount),
            const SizedBox(height: 20),
          ],
          if (others.isNotEmpty) ...[
            _buildSubSectionHeader("More Shows", others.length),
            const SizedBox(height: 8),
            _buildPosterGrid(others, crossAxisCount),
            const SizedBox(height: 20),
          ],
        ] else if (hasContent) ...[
          /// Single type or specific filter selected: show direct poster grid
          if (controller.selectedCategory.value == "Movies")
            _buildPosterGrid(movies, crossAxisCount)
          else if (controller.selectedCategory.value == "Web Series")
            _buildPosterGrid(series, crossAxisCount)
          else
            _buildPosterGrid(controller.searchResults, crossAxisCount),
        ],
      ],
    );
  }
}
