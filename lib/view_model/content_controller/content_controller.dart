import 'package:get/get.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../data/models/response_model/category_model/category_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/network/api_network_service.dart';

class ContentController extends GetxController {
  final ContentRepository _repository = ContentRepository(NetworkApiService());

  var isLoading = true.obs;
  var allContent = <ContentModel>[].obs;
  var trendingContent = <ContentModel>[].obs;
  var categories = <CategoryModel>[].obs;
  
  // Cache for likes: ContentID -> LikeCount
  var contentLikes = <String, int>{}.obs;

  // Precomputed category content map — avoids repeated .where() in build()
  var categoryContentMap = <String, List<ContentModel>>{}.obs;
  var comingSoonContent = <ContentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
    fetchContent();
  }

  /// 🔄 Clears all content state & forces UI to show loading, then re-fetches fresh data from API
  Future<void> hardRefreshContent() async {
    isLoading.value = true;
    allContent.clear();
    trendingContent.clear();
    categories.clear();
    categoryContentMap.clear();
    comingSoonContent.clear();

    await Future.wait([
      fetchCategories(),
      fetchContent(),
    ]);
  }

  Future<void> fetchContent() async {
    try {
      isLoading.value = true;
      final content = await _repository.getAllContent();
      
      // Preserve any items already added to allContent from category responses
      final existingIds = content.map((e) => e.id).toSet();
      for (final item in allContent) {
        if (!existingIds.contains(item.id)) {
          content.add(item);
        }
      }
      allContent.assignAll(content);
      
      // Filter trending for slider: prefer category content endpoint order if available
      if (categoryContentMap.containsKey('trending') &&
          categoryContentMap['trending']!.isNotEmpty) {
        trendingContent.assignAll(categoryContentMap['trending']!);
      } else {
        trendingContent.assignAll(content
            .where((c) =>
                (c.isTrending || c.category.contains('trending')) &&
                c.isComingSoon == false)
            .toList());
      }

      // Precompute coming soon
      comingSoonContent.assignAll(
          content.where((c) => c.isComingSoon == true).toList());
    } catch (e) {
      // Error handled silently
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await _repository.getCategories();
      fetchedCategories.sort((a, b) => a.priority.compareTo(b.priority));
      categories.assignAll(fetchedCategories);

      // Fetch content for each category using GET /api/categories/:slug/content
      final Map<String, List<ContentModel>> newCategoryMap = {};
      final List<ContentModel> collectedCategoryContent = [];

      await Future.wait(fetchedCategories.map((category) async {
        if (category.slug.isEmpty) return;
        final list = await _repository.getCategoryContentBySlug(category.slug);
        if (list.isNotEmpty) {
          list.sort((a, b) => a.position.compareTo(b.position));
          newCategoryMap[category.slug] = list;
          collectedCategoryContent.addAll(list);
        }
      }));

      categoryContentMap.assignAll(newCategoryMap);

      // Set trendingContent from the position-sorted category list if present
      if (newCategoryMap.containsKey('trending') &&
          newCategoryMap['trending']!.isNotEmpty) {
        trendingContent.assignAll(newCategoryMap['trending']!);
      }

      // Merge items into allContent
      if (collectedCategoryContent.isNotEmpty) {
        final existingIds = allContent.map((e) => e.id).toSet();
        for (final item in collectedCategoryContent) {
          if (!existingIds.contains(item.id)) {
            allContent.add(item);
            existingIds.add(item.id);
          }
        }
      }
    } catch (e) {
      // Error handled silently
    }
  }
}
