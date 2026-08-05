import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import 'package:roccoplay/view_model/auth_controller/auth_controller.dart';
import 'package:roccoplay/view_model/download_controller/download_controller.dart';
import 'package:roccoplay/view_model/primium_controller/premium_controller.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';
import '../../utils/share_helper.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../view_model/content_controller/content_controller.dart';
import '../../view_model/like_dislike_controller/like_dislike_controller.dart';
import '../../view_model/watchlist_controller/watchlist_controller.dart';
import '../auth/signInPage.dart';
import '../popUp/age_popup.dart';
import '../videoPlayer/video_player.dart';
import 'cast_crewPage.dart';
import '../premium/goPremium.dart';
import '../../view_model/drama_detail_controller/drama_details_controller.dart';
import '../../utils/custom_snackbar.dart';
import '../../widgets/ad_widget/banner_ad_widget.dart';
import '../../widgets/ad_widget/interstitial_ad_helper.dart';

class DramaDetailsPage extends StatelessWidget {
  final bool isSignedIn;
  final ContentModel content;

  const DramaDetailsPage({
    super.key,
    required this.isSignedIn,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final DramaDetailsController controller = Get.put(DramaDetailsController());
    final AuthController authController = Get.find<AuthController>();
    final WatchlistController watchlistController = Get.put(
      WatchlistController(),
    );
    final ContentController contentController = Get.find<ContentController>();
    final PremiumController premiumController = Get.put(PremiumController());
    final InteractionController interactionController = Get.put(
      InteractionController(),
    );
    final DownloadController downloadController = Get.put(DownloadController());

    // Refresh subscription status on page entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.isLoggedIn.value) {
        premiumController.fetchSubscriptionStatus();
      }
      // 🔥 Series/Movie details open pe Interstitial (preload sirf)
      InterstitialAdHelper.loadAd();
    });

    // Filter "You May Also Like"
    final List<ContentModel> relatedContent = contentController.allContent
        .where((item) {
          return item.id != content.id &&
              item.contentType == content.contentType &&
              item.category.any((cat) => content.category.contains(cat));
        })
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 Banner Section
            Stack(
              children: [
                Image.network(
                  content.banner,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    "assets/images/farzi.jpg",
                    height: 300,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      // 🔥 Back jaate waqt Interstitial Ad
                      InterstitialAdHelper.showAd(onAdClosed: () => Get.back());
                    },
                  ),
                ),
                if (content.trailerUrl != null &&
                    content.trailerUrl!.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () async {
                        final bool? isOver18 = await Get.dialog<bool>(
                          AgeRestrictionPopup(),
                        );
                        if (isOver18 == true) {
                          Get.to(
                            () => AdvancedVideoPlayer(
                              url: content.trailerUrl!,
                              title: '${content.title} - Trailer',
                              contentId: '${content.id}_trailer',
                            ),
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.play_arrow,
                        color: AppColors.white,
                      ),
                      label: const Text(
                        "Watch Trailer",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 15),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "${content.releaseYear} • ${content.language} ${content.duration != null ? '• ${content.duration}' : ''}",
                style: const TextStyle(color: AppColors.white, fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔐 DYNAMIC WATCH BUTTON
            if (content.contentType == "movie")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final sub = premiumController.subscriptionData.value;
                  final bool isPurchased =
                      sub != null && sub['status'] == 'active';
                  final bool userLoggedIn = authController.isLoggedIn.value;

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () => _handlePlayback(
                      context: context,
                      url: content.videoUrl,
                      title: content.title,
                      id: content.id,
                      isPremium: content.isPremium,
                      isPurchased: isPurchased,
                      userLoggedIn: userLoggedIn,
                    ),
                    child: Text(
                      !userLoggedIn
                          ? "Sign In to Watch"
                          : (isPurchased || !content.isPremium
                                ? "Watch Movie"
                                : "Subscribe to Watch"),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }),
              ),

            const SizedBox(height: 12),

            /// ⬇ DYNAMIC DOWNLOAD BUTTON (Logic Fixed)
            if (content.contentType == "movie")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() {
                  final sub = premiumController.subscriptionData.value;
                  final bool isPurchased =
                      sub != null && sub['status'] == 'active';
                  final bool userLoggedIn = authController.isLoggedIn.value;
                  final bool isAlreadyDownloaded = downloadController
                      .isDownloaded(content.id);
                  final bool downloading =
                      downloadController.isDownloading[content.id] ?? false;

                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      if (!userLoggedIn) {
                        Get.to(() => const SignInPage());
                      } else if (isPurchased) {
                        // ✅ Direct download if plan is purchased
                        if (isAlreadyDownloaded) {
                          CustomSnackbar.show(
                            title: "Info",
                            message: "Already downloaded",
                          );
                        } else {
                          MetaEventService.instance.download(
                            contentId: content.id,
                            contentName: content.title,
                          );
                          FirebaseAnalyticsService.instance.download(
                            contentId: content.id,
                            contentName: content.title,
                          );
                          downloadController.downloadVideo(content);
                        }
                      } else {
                        // ❌ Show popup only if plan is NOT purchased
                        _showSubscriptionDialog(context);
                      }
                    },
                    child: downloading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  value:
                                      downloadController
                                          .downloadProgress[content.id] ??
                                      0,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${((downloadController.downloadProgress[content.id] ?? 0) * 100).toInt()}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : isAlreadyDownloaded
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                "Downloaded",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          )
                        : const Text(
                            "Download",
                            style: TextStyle(color: Colors.white),
                          ),
                  );
                }),
              ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                content.description,
                style: const TextStyle(color: Colors.white70),
              ),
            ),

            const SizedBox(height: 15),

            /// 📲 Banner Ad after description
            Center(child: const BannerAdWidget()),

            const SizedBox(height: 20),

            /// ⭐ Action Buttons Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        GestureDetector(
                          onTap: watchlistController.isLoading.value
                              ? null
                              : () => watchlistController.toggleWatchlist(
                                  content.id.toString(),
                                ),
                          child: watchlistController.isLoading.value
                              ? const SizedBox(
                                  height: 30,
                                  width: 30,
                                  child: CircularProgressIndicator(
                                    color: AppColors.buttonColor,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  watchlistController.isInWatchlist(
                                        content.id.toString(),
                                      )
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  color:
                                      watchlistController.isInWatchlist(
                                        content.id.toString(),
                                      )
                                      ? AppColors.buttonColor
                                      : Colors.white,
                                  size: 30,
                                ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Watchlist",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),

                    _actionButton(
                      icon: interactionController.isLiked.value
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      label: "Like",
                      onTap: () {
                        MetaEventService.instance.bookmark(
                          contentId: content.id,
                          contentName: content.title,
                        );
                        FirebaseAnalyticsService.instance.bookmark(
                          contentId: content.id,
                          contentName: content.title,
                        );
                        interactionController.toggleLike(
                          contentId: content.id,
                          contentType: content.contentType,
                        );
                      },
                    ),

                    _actionButton(
                      icon: interactionController.isDisliked.value
                          ? Icons.thumb_down
                          : Icons.thumb_down_outlined,
                      label: "Dislike",
                      onTap: () => interactionController.toggleDislike(
                        contentId: content.id,
                        contentType: content.contentType,
                      ),
                    ),

                    _actionButton(
                      icon: Icons.share,
                      label: "Share",
                      onTap: () {
                        ShareHelper.shareContent(
                          title: content.title,
                          slug: content.slug,
                          imageUrl: content.poster,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// 📺 EPISODES SECTION
            if (content.contentType == "series" &&
                content.seasons != null &&
                content.seasons!.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Episodes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              /// Season Selector
              if (content.seasons!.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Obx(
                    () => DropdownButton<int>(
                      value: controller.selectedSeason.value,
                      dropdownColor: Colors.black,
                      underline: Container(
                        height: 1,
                        color: AppColors.buttonColor,
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      onChanged: (val) => controller.setSeason(val!),
                      items: List.generate(content.seasons!.length, (index) {
                        return DropdownMenuItem(
                          value: index,
                          child: Text(
                            "Season ${content.seasons![index].seasonNumber}",
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              const SizedBox(height: 15),

              /// Episodes List
              Obx(() {
                final seasonIndex = controller.selectedSeason.value;
                final season = content.seasons![seasonIndex];
                final sub = premiumController.subscriptionData.value;
                final bool isPurchased =
                    sub != null && sub['status'] == 'active';
                final bool userLoggedIn = authController.isLoggedIn.value;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: season.episodes.length,
                  itemBuilder: (context, index) {
                    final ep = season.episodes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: ListTile(
                        onTap: () => _handlePlayback(
                          context: context,
                          url: ep.videoUrl,
                          title: ep.title,
                          id: ep.id,
                          isPremium: content.isPremium,
                          isPurchased: isPurchased,
                          userLoggedIn: userLoggedIn,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            ep.thumbnail,
                            width: 100,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Image.asset(
                              "assets/images/farzi.jpg",
                              width: 100,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(
                          ep.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          ep.duration ?? "",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// ⬇ EPISODE DOWNLOAD
                            Obx(() {
                              final bool isDownloaded = downloadController
                                  .isDownloaded(ep.id);
                              final bool downloading =
                                  downloadController.isDownloading[ep.id] ??
                                  false;
                              final double progress =
                                  downloadController.downloadProgress[ep.id] ??
                                  0;

                              if (downloading) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: 25,
                                        width: 25,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          color: AppColors.buttonColor,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      Text(
                                        "${(progress * 100).toInt()}%",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (isDownloaded) {
                                return const Padding(
                                  padding: EdgeInsets.only(right: 10),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24,
                                  ),
                                );
                              }

                              return IconButton(
                                icon: const Icon(
                                  Icons.download_for_offline_outlined,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  if (!userLoggedIn) {
                                    Get.to(() => const SignInPage());
                                  } else if (isPurchased ||
                                      !content.isPremium) {
                                    downloadController.downloadEpisode(
                                      content,
                                      ep,
                                    );
                                  } else {
                                    _showSubscriptionDialog(context);
                                  }
                                },
                              );
                            }),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.play_circle_fill,
                              color: AppColors.buttonColor,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],

            const SizedBox(height: 25),

            /// 📲 Banner Ad after episodes
            if (content.contentType == "series")
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: BannerAdWidget()),
              ),

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
                        Get.to(
                          () => CastDetailsPage(
                            castName: actor.name,
                            castImage: actor.image,
                          ),
                        );
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
                                      : const AssetImage(
                                              "assets/images/farzi.jpg",
                                            )
                                            as ImageProvider,
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

            /// 🔥 Native Ad before Related Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NativeAdWidget(
                adType: TemplateType.small,
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                  minHeight: 50,
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: 100,
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// ❤️ You May Also Like
            if (relatedContent.isNotEmpty) ...[
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
                  itemCount: relatedContent.length,
                  itemBuilder: (context, index) {
                    final item = relatedContent[index];
                    return GestureDetector(
                      onTap: () {
                        Get.to(
                          () => DramaDetailsPage(
                            isSignedIn: authController.isLoggedIn.value,
                            content: item,
                          ),
                          preventDuplicates: false,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            item.poster,
                            width: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  "assets/images/asur.webp",
                                  width: 110,
                                  fit: BoxFit.cover,
                                ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

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

  /// 🎬 Handle Playback Logic
  void _handlePlayback({
    required BuildContext context,
    required String? url,
    required String title,
    required String id,
    required bool isPremium,
    required bool isPurchased,
    required bool userLoggedIn,
  }) async {
    if (!userLoggedIn) {
      Get.to(() => const SignInPage());
      return;
    }

    if (isPremium && !isPurchased) {
      Get.to(() => const GoPremiumPage());
      return;
    }

    if (url == null || url.isEmpty) {
      CustomSnackbar.show(
        title: "Error",
        message: "Video URL not found",
        isError: true,
      );
      return;
    }

    // Show Age Restriction Popup instead of Pre-play
    final bool? proceed = await Get.dialog<bool>(AgeRestrictionPopup());

    if (proceed == true) {
      MetaEventService.instance.videoPlay(contentId: id, contentName: title);
      FirebaseAnalyticsService.instance.videoPlay(
        contentId: id,
        contentName: title,
      );
      Get.to(() => AdvancedVideoPlayer(url: url, title: title, contentId: id));
    }
  }

  void _showSubscriptionDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
