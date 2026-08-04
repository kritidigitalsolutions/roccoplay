import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/watchlist_repo.dart';
import '../../utils/custom_snackbar.dart';
import '../auth_controller/auth_controller.dart';

class WatchlistController extends GetxController {
  final WatchlistRepo repo = WatchlistRepo(apiProvider: Get.find<BaseApiService>());

  var isLoading = false.obs;
  var watchlist = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    
    // Auth status check करें
    final authController = Get.find<AuthController>();
    
    // Initial fetch if logged in
    if (authController.isLoggedIn.value) {
      getWatchlist();
    }

    // Login status change को listen करें
    ever(authController.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        getWatchlist();
      } else {
        watchlist.clear();
      }
    });
  }

  /// 📥 GET WATCHLIST
  Future<void> getWatchlist() async {
    try {
      isLoading.value = true;
      final response = await repo.getWatchlist();
      
      if (response != null) {
        // Checking for success true or just presence of data
        final List<dynamic> data = response['data'] ?? [];
        debugPrint("📥 RAW WATCHLIST DATA: $data");
        
        // Filter out content that is not published
        final filteredData = data.where((item) {
          final movie = item['movie'] ?? item['item'];
          if (movie != null && movie is Map<String, dynamic>) {
            return movie['isPublished'] != false;
          } else if (movie != null && movie is String) {
             // If it's just an ID, we assume it's published for now as we can't check without fetching
             return true;
          }
          return true;
        }).map((e) => e as Map<String, dynamic>).toList();
        
        watchlist.assignAll(filteredData);
        print("✅ WATCHLIST FETCHED: ${watchlist.length} items");
      }
    } catch (e) {
      print("❌ Error fetching watchlist: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ CHECK if a content ID is in the watchlist
  bool isInWatchlist(String contentId) {
    return watchlist.any((item) {
      final movie = item['movie'] ?? item['item'];
      if (movie != null && movie is Map) {
        // Checking both _id and id just in case
        final id = movie['_id'] ?? movie['id'];
        return id.toString() == contentId.toString();
      }
      // In some cases movie might be just ID if not populated
      return movie.toString() == contentId.toString();
    });
  }

  /// ➕ ADD TO WATCHLIST
  Future<void> addToWatchlist(String contentId) async {
    try {
      isLoading.value = true;
      final response = await repo.addToWatchlist(contentId);
      
      if (response != null) {
        CustomSnackbar.show(
          title: "Success",
          message: response['message'] ?? "Added to watchlist",
          isSuccess: true,
        );
        // 🔄 Refresh list immediately to keep UI in sync
        await getWatchlist();
      }
    } catch (e) {
      print("❌ Add Watchlist Error: $e");
      // Handle the case where it might already be in watchlist (safety check)
      if (e.toString().contains("Already in watchlist")) {
        await getWatchlist(); // Refresh to sync
        CustomSnackbar.show(
          title: "Info",
          message: "Already in your watchlist",
          isSuccess: true,
        );
      } else {
        CustomSnackbar.show(
          title: "Error",
          message: "Failed to add to watchlist",
          isError: true,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// ❌ REMOVE FROM WATCHLIST
  Future<void> removeFromWatchlist(String watchlistId) async {
    try {
      isLoading.value = true;
      final response = await repo.removeFromWatchlist(watchlistId);

      if (response != null) {
        watchlist.removeWhere((item) => item['_id'] == watchlistId);
        CustomSnackbar.show(
          title: "Removed",
          message: "Removed from watchlist",
        );
      }
    } catch (e) {
      print("❌ Remove Error: $e");
      CustomSnackbar.show(
        title: "Error",
        message: "Failed to remove from watchlist",
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔄 TOGGLE WATCHLIST
  Future<void> toggleWatchlist(String contentId) async {
    if (isInWatchlist(contentId)) {
      try {
        final watchlistItem = watchlist.firstWhere((item) {
          final movie = item['movie'] ?? item['item'];
          if (movie != null && movie is Map) {
            final id = movie['_id'] ?? movie['id'];
            return id.toString() == contentId.toString();
          }
          return movie.toString() == contentId.toString();
        });
        
        final String? watchlistId = watchlistItem['_id'];
        if (watchlistId != null) {
          await removeFromWatchlist(watchlistId);
        }
      } catch (e) {
        print("Error finding item to remove: $e");
        // Fallback: if we can't find it locally but isInWatchlist was true, 
        // it might be a sync issue. Let's refresh.
        await getWatchlist();
      }
    } else {
      await addToWatchlist(contentId);
    }
  }
}
