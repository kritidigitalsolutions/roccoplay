import '../models/response_model/content_response_model/content_model.dart';
import '../models/response_model/category_model/category_model.dart';
import '../network/base_api_service.dart';
import '../../utils/constants.dart';

class ContentRepository {
  final BaseApiService apiProvider;

  ContentRepository(this.apiProvider);

  Future<List<ContentModel>> getAllContent() async {
    try {
      final response = await apiProvider.getApi(AppConstants.getAllContent);
      if (response['success'] == true) {
        List<dynamic> data = response['content'] ?? [];
        return data
            .map((item) => ContentModel.fromJson(item))
            .where((content) => content.isPublished)
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final response = await apiProvider.getApi(AppConstants.getCategories);
      if (response['success'] == true) {
        List<dynamic> data = response['categories'] ?? [];
        return data.map((item) => CategoryModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ContentModel>> getCategoryContentBySlug(String slug) async {
    try {
      final response =
          await apiProvider.getApi(AppConstants.getCategoryContentBySlug(slug));
      if (response['success'] == true) {
        List<dynamic> data = response['content'] ?? [];
        List<ContentModel> list = data
            .map((item) => ContentModel.fromJson(item))
            .where((content) => content.isPublished)
            .toList();
        list.sort((a, b) => a.position.compareTo(b.position));
        return list;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
