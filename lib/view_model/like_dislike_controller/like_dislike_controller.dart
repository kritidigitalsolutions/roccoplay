import 'package:get/get.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/like_dislike_repo.dart';

class InteractionController extends GetxController {
  final InteractionRepository _repo = InteractionRepository(Get.find<BaseApiService>());

  var isLiked = false.obs;
  var isDisliked = false.obs;
  var isLoading = false.obs;

  /// 📊 Fetch Interaction Status (Like/Dislike)
  Future<void> fetchInteractionStatus(String contentId) async {
    try {
      final response = await _repo.getInteractionStats(contentId);
      if (response != null && response['userInteraction'] != null) {
        final interaction = response['userInteraction'].toString().toLowerCase();
        isLiked.value = interaction == 'like';
        isDisliked.value = interaction == 'dislike';
      } else {
        isLiked.value = false;
        isDisliked.value = false;
      }
    } catch (e) {
      // Error handled silently
    }
  }

  /// 👍 Toggle LIKE
  Future<void> toggleLike({
    required String contentId,
    required String contentType,
  }) async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final response = await _repo.toggleInteraction(
        contentId: contentId,
        contentType: contentType,
        type: "like",
      );

      // Check message directly as 'success' might not be in response
      if (response != null && response["message"] != null) {
        final message = response["message"].toString().toLowerCase();

        if (message.contains("removed")) {
          isLiked.value = false;
        } else if (message.contains("added")) {
          isLiked.value = true;
          isDisliked.value = false;
        }
      }
    } catch (e) {
      // Error handled silently
    } finally {
      isLoading.value = false;
    }
  }

  /// 👎 Toggle DISLIKE
  Future<void> toggleDislike({
    required String contentId,
    required String contentType,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;
    try {
      final response = await _repo.toggleInteraction(
        contentId: contentId,
        contentType: contentType,
        type: "dislike",
      );

      if (response != null && response["message"] != null) {
        final message = response["message"].toString().toLowerCase();

        if (message.contains("removed")) {
          isDisliked.value = false;
        } else if (message.contains("added")) {
          isDisliked.value = true;
          isLiked.value = false;
        }
      }
    } catch (e) {
      // Error handled silently
    } finally {
      isLoading.value = false;
    }
  }
}
