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
    fetchContent();
    fetchCategories();
  }

  Future<void> fetchContent() async {
    try {
      isLoading.value = true;
      final content = await _repository.getAllContent();
      allContent.assignAll(content);
      
      // Filter trending for slider
      trendingContent.assignAll(content.where((c) => (c.isTrending || c.category.contains('trending')) && c.isComingSoon == false).toList());
      
      // Precompute coming soon
      comingSoonContent.assignAll(content.where((c) => c.isComingSoon == true).toList());

      // Rebuild category content map
      _rebuildCategoryContentMap();
      
    } catch (e) {
      // Error handled silently
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await _repository.getCategories();
      categories.assignAll(fetchedCategories);
      categories.sort((a, b) => a.priority.compareTo(b.priority));

      // Rebuild category content map when categories change
      _rebuildCategoryContentMap();
    } catch (e) {
      // Error handled silently
    }
  }

  /// Precompute category → content list mapping (called after content or categories update)
  void _rebuildCategoryContentMap() {
    if (allContent.isEmpty || categories.isEmpty) return;
    final map = <String, List<ContentModel>>{};
    for (final category in categories) {
      if (category.slug == 'trending') continue;
      final items = allContent
          .where((c) => c.category.contains(category.slug) && c.isComingSoon == false)
          .toList();
      if (items.isNotEmpty) {
        map[category.slug] = items;
      }
    }
    categoryContentMap.value = map;
  }
}
