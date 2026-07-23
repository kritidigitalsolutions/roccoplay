import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/watchlist_controller/watchlist_controller.dart';
import '../dramaDetails/dramaDetailsPage.dart';
import '../homePages/mainHomepage.dart';
import '../../view_model/content_controller/content_controller.dart';

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller initialize करें (अगर पहले से नहीं है)
    final WatchlistController controller = Get.put(WatchlistController());
    final AuthController authController = Get.find<AuthController>();
    final ContentController contentController = Get.find<ContentController>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Watchlist",
          style: TextStyle(color: AppColors.white),
        ),
      ),
      body: Obx(() {
        /// 🔄 LOADING
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.pink));
        }

        /// ❌ EMPTY STATE
        if (controller.watchlist.isEmpty) {
          return _emptyState();
        }

        /// ✅ LIST
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: controller.watchlist.length,
          itemBuilder: (context, index) {
            final item = controller.watchlist[index];
            final watchlistId = item['_id'] ?? '';
            final movieData = item['movie'] ?? item['item'];
            final String itemType = (item['itemModel'] ?? '').toString().toLowerCase();

            // UI variables
            String title = "Unknown Title";
            String poster = "";
            String year = "";
            ContentModel? contentItem;

            if (movieData != null) {
              if (movieData is Map<String, dynamic>) {
                // First try to find in allContent to get full model
                final String movieId = movieData['_id'] ?? movieData['id'] ?? '';
                try {
                  contentItem = contentController.allContent.firstWhere((c) => c.id == movieId);
                } catch (e) {
                  // If not found in allContent, create from movieData
                  // Ensure it has a contentType if we know it from itemModel
                  if (movieData['type'] == null && itemType.isNotEmpty) {
                    movieData['type'] = itemType == 'movie' ? 'movie' : 'series';
                  }
                  contentItem = ContentModel.fromJson(movieData);
                }
              } else if (movieData is String) {
                // If movie is just an ID
                try {
                  contentItem = contentController.allContent.firstWhere((c) => c.id == movieData);
                } catch (e) {
                  debugPrint("Could not find movie with id $movieData in allContent");
                }
              }

              if (contentItem != null) {
                title = contentItem.title;
                poster = contentItem.poster;
                year = contentItem.releaseYear != 0 ? contentItem.releaseYear.toString() : "";
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 10, right: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                onTap: () {
                  if (contentItem != null) {
                    Get.to(() => DramaDetailsPage(
                          isSignedIn: authController.isLoggedIn.value,
                          content: contentItem!,
                        ));
                  }
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 2/3,
                    child: poster.isNotEmpty
                        ? Image.network(
                            poster,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.movie, color: Colors.white)),
                          )
                        : const Center(child: Icon(Icons.movie, color: Colors.white)),
                  ),
                ),
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      year.isNotEmpty && year != "0" ? year : "Watchlist Item",
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () {
                    if (watchlistId.isNotEmpty) {
                      controller.removeFromWatchlist(watchlistId);
                    }
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  /// 🔥 EMPTY UI
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade700, width: 2),
              ),
              child: const Icon(Icons.bookmark_border, size: 50, color: AppColors.white),
            ),
            const SizedBox(height: 30),
            const Text(
              "No Watchlist Added Yet",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            const Text(
              "Adding to Watchlist is a great way to make sure you always have something to watch.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Get.offAll(() => const MainHomePage());
                },
                child: const Text(
                  "Start Adding",
                  style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
