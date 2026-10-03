import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../content_controller/content_controller.dart';

class AppSearchController extends GetxController {
  var searchQuery = "".obs;
  final TextEditingController searchController = TextEditingController();
  
  var searchResults = <ContentModel>[].obs;
  var selectedCategory = "All".obs;
  final ContentController _contentController = Get.find<ContentController>();

  Timer? _debounceTimer;

  void setCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    if (searchQuery.value.isNotEmpty) {
      _performSearch(searchQuery.value);
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      searchResults.clear();
      return;
    }

    // Debounce 300ms to avoid heavy filtering on every keystroke
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    final lowerQuery = query.toLowerCase().trim();

    // 1. Filter contents by title, genre, or cast
    List<ContentModel> filtered = _contentController.allContent.where((item) {
      final matchesTitle = item.title.toLowerCase().contains(lowerQuery);
      final matchesGenre = item.genre.any((g) => g.toLowerCase().contains(lowerQuery));
      final matchesCast = item.cast?.any((c) => c.name.toLowerCase().contains(lowerQuery)) ?? false;
      final matchesQuery = matchesTitle || matchesGenre || matchesCast;

      if (!matchesQuery) return false;

      // Filter by selected category chip if not 'All'
      if (selectedCategory.value == "Movies") {
        return item.contentType.toLowerCase() == 'movie';
      } else if (selectedCategory.value == "Web Series") {
        return item.contentType.toLowerCase() == 'series';
      } else if (selectedCategory.value == "Artists") {
        return item.cast != null && item.cast!.any((c) => c.name.toLowerCase().contains(lowerQuery));
      } else if (selectedCategory.value == "Genres") {
        return item.genre.any((g) => g.toLowerCase().contains(lowerQuery));
      }
      return true;
    }).toList();

    // 2. Sort by like counts from ContentController cache
    filtered.sort((a, b) {
      int likesA = _contentController.contentLikes[a.id] ?? 0;
      int likesB = _contentController.contentLikes[b.id] ?? 0;
      return likesB.compareTo(likesA); // Descending (High to Low)
    });

    searchResults.assignAll(filtered);
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    searchController.clear();
    searchQuery.value = "";
    searchResults.clear();
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    super.onClose();
  }
}

