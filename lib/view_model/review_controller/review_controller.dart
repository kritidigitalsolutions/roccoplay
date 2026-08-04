import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/review_repo.dart';
import '../../utils/custom_snackbar.dart';

class ReviewController extends GetxController {
  final ReviewRepo repo =
  ReviewRepo(api: Get.find<BaseApiService>());

  /// ⭐ States
  var rating = 0.obs;
  var isLoading = false.obs;
  final commentController = TextEditingController();

  /// ⭐ Update Rating
  void updateRating(int value) {
    rating.value = value;
  }

  /// 🚀 Submit Review
  Future<void> submitReview() async {
    if (rating.value == 0) {
      CustomSnackbar.show(title: "Error", message: "Please select rating", isError: true);
      return;
    }

    try {
      isLoading.value = true;

      final response = await repo.submitRating(
        rating: rating.value,
        review: commentController.text.trim(),
      );

      if (response != null && (response['success'] == true || response['status'] == 'success')) {
        CustomSnackbar.show(
          title: "Success", 
          message: response['message'] ?? "Thank you for your review!", 
          isSuccess: true
        );

        /// Reset fields
        rating.value = 0;
        commentController.clear();
      } else {
        CustomSnackbar.show(
          title: "Error", 
          message: response?['message'] ?? "Something went wrong", 
          isError: true
        );
      }
    } catch (e) {
      CustomSnackbar.show(title: "Error", message: e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
