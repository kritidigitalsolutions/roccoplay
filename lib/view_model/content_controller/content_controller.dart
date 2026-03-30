import 'package:get/get.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../data/repositories/content_repository.dart';
import '../../data/network/api_network_service.dart';

class ContentController extends GetxController {
  final ContentRepository _repository = ContentRepository(NetworkApiService());

  var isLoading = true.obs;
  var allContent = <ContentModel>[].obs;
  var trendingContent = <ContentModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchContent();
  }

  Future<void> fetchContent() async {
    try {
      isLoading.value = true;
      final content = await _repository.getAllContent();
      allContent.assignAll(content);
      
      // Filter trending for slider
      trendingContent.assignAll(content.where((c) => c.category.contains('trending')).toList());
      
    } catch (e) {
      print("Error in ContentController: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
