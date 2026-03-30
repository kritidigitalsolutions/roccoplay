import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../../data/models/response_model/watchlist_response/watchlist_response.dart';
import '../../data/providers/api_provider.dart';
import '../../data/repositories/watchlist_repo.dart';

class WatchlistController extends GetxController {
  final WatchlistRepo repo = WatchlistRepo(apiProvider: ApiProvider());

  var isInWatchlist = false.obs;
  var isLoading = false.obs;

  /// ➕ Add to Watchlist
  Future<void> addToWatchlist(String movieId) async {
    try {
      isLoading.value = true;

      final WatchlistResponseModel? response =
      await repo.addToWatchlist(movieId);

      if (response != null) {
        isInWatchlist.value = !isInWatchlist.value;

        Get.snackbar(
          "Success",
          response.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to add to watchlist",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔄 Toggle Watchlist
  Future<void> toggleWatchlist(String movieId) async {
    try {
      final storage = GetStorage();
      String? token = storage.read('token');

      /// 🔐 Login check
      if (token == null || token.isEmpty) {
        Get.snackbar("Login Required", "Please login first");
        return;
      }

      if (isInWatchlist.value) {
        isInWatchlist.value = false;

        Get.snackbar(
          "Removed",
          "Removed from watchlist",
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        await addToWatchlist(movieId);
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
