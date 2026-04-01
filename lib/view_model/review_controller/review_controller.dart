import 'package:get/get.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/review_repo.dart';

class ReviewController extends GetxController {
  final ReviewRepo repo =
  ReviewRepo(api: Get.find<BaseApiService>());

  /// ⭐ States
  var rating = 0.obs;
  var comment = ''.obs;
  var isLoading = false.obs; // ✅ ADD THIS

  /// ⭐ Update Rating
  void updateRating(int value) {
    rating.value = value;
  }

  /// ✍️ Update Comment
  void updateComment(String value) {
    comment.value = value;
  }

  /// 🚀 Submit Review
  Future<void> submitReview() async {
    if (rating.value == 0) {
      Get.snackbar("Error", "Please select rating");
      return;
    }

    try {
      isLoading.value = true; // ✅ USE HERE

      final response = await repo.submitRating(
        rating: rating.value,
        review: comment.value,
      );

      if (response['success'] == true) {
        Get.snackbar("Success", response['message']);

        /// Reset
        rating.value = 0;
        comment.value = "";

        Get.back();
      } else {
        Get.snackbar("Error", "Something went wrong");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false; // ✅ STOP LOADER
    }
  }
}
