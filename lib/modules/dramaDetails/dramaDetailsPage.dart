import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/modules/auth/signInPage.dart';
import 'package:roccoplay/modules/videoPlayer/video_player.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../view_model/watchlist_controller/watchlist_controller.dart';
import '../popUp/age_popup.dart';
import 'cast_crewPage.dart';
import '../premium/goPremium.dart';
import '../../view_model/drama_detail_controller/drama_details_controller.dart';

class DramaDetailsPage extends StatelessWidget {
  final bool isSignedIn;
  final ContentModel content;

  const DramaDetailsPage({super.key, required this.isSignedIn, required this.content});

  @override
  Widget build(BuildContext context) {
    final DramaDetailsController controller = Get.put(DramaDetailsController());
    final WatchlistController watchlistController = Get.find<WatchlistController>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 Top Banner Image
            Stack(
              children: [
                Image.network(
                  content.banner,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    "assets/images/farzi.jpg",
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// 🔙 Back Button
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ),

                /// 🎬 Watch Trailer Button (Right Bottom)
                if (content.trailerUrl != null && content.trailerUrl!.isNotEmpty)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      final bool? isOver18 = await Get.dialog<bool>(
                        const AgeRestrictionPopup(),
                      );

                      if (isOver18 == true) {
                        Get.to(() => AdvancedVideoPlayer(
                              url: content.trailerUrl!,
                              title: '${content.title} - Trailer',
                            ));
                      }
                    },
                    icon: const Icon(Icons.play_arrow, color: AppColors.white),
                    label: const Text(
                      "Watch Trailer",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            /// 🎬 Series Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                content.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 6),

            /// 📅 Date • Language • Duration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "${content.releaseYear} • ${content.language} ${content.duration != null ? '• ${content.duration}' : ''}",
                style: const TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔐 Subscribe / Sign In Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (isSignedIn) {
                    if (content.isPremium) {
                      Get.to(() => const GoPremiumPage());
                    } else if (content.videoUrl != null) {
                       Get.to(() => AdvancedVideoPlayer(
                              url: content.videoUrl!,
                              title: content.title,
                            ));
                    }
                  } else {
                    Get.to(() => const SignInPage());
                  }
                },
                child: Text(
                  isSignedIn 
                    ? (content.isPremium ? "Subscribe to Watch" : "Watch Now") 
                    : "Sign In to Watch",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ⬇ Download Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _showSubscriptionDialog(context);
                },
                child: const Text(
                  "Download",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 📝 Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                content.description,
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 20),

            /// ⭐ Action Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {

                          watchlistController.toggleWatchlist(content.id.toString());
                        },
                        child: Obx(() => Icon(
                          watchlistController.isInWatchlist.value
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                          color: Colors.white,
                          size: 30,
                        )),
                      ),
                      const SizedBox(height: 5),
                      const Text("Watchlist", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                  // Obx(() => _actionButton(
                  //   icon: watchlistController.isInWatchlist.value
                  //       ? Icons.bookmark
                  //       : Icons.bookmark_border,
                  //   label: "Watchlist",
                  //   onTap: () =>
                  //       watchlistController.toggleWatchlist(content.id),
                  // )
                  // ),

                  _actionButton(
                    icon: controller.isLiked.value ? Icons.thumb_up : Icons.thumb_up_outlined,
                    label: "Like",
                    onTap: controller.toggleLike,
                  ),

                  _actionButton(
                    icon: controller.isDisliked.value
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    label: "Dislike",
                    onTap: controller.toggleDislike,
                  ),

                  _actionButton(
                    icon: Icons.share,
                    label: "Share",
                    onTap: () {
                      Share.share(
                        "Check out ${content.title} on RoccoPlay App 🎬🔥",
                      );
                    },
                  ),
                ],
              )),
            ),

            const SizedBox(height: 25),

            /// 🎭 Cast & Crew
            if (content.cast != null && content.cast!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Cast & Crew",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: content.cast!.length,
                  itemBuilder: (context, index) {
                    final actor = content.cast![index];
                    return GestureDetector(
                      onTap: () {
                        Get.to(() => CastDetailsPage(
                              castName: actor.name,
                              castImage: actor.image,
                            ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: (actor.image.isNotEmpty) 
                                    ? NetworkImage(actor.image) 
                                    : const AssetImage("assets/images/farzi.jpg") as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 25),

            /// ❤️ You May Also Like
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "You May Also Like",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        "assets/images/asur.webp",
                        width: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showSubscriptionDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Subscription Required",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "You need a subscription to download this video.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Get.back(),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                      ),
                      onPressed: () {
                        Get.back();
                        Get.to(() => const GoPremiumPage());
                      },
                      child: const Text(
                        "Explore Plan",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}