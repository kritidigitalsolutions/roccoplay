import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:roccoplay/utils/service/meta_event_service.dart';
import 'package:roccoplay/utils/service/firebase_analytics_service.dart';
import 'package:roccoplay/view_model/auth_controller/auth_controller.dart';
import 'package:roccoplay/view_model/download_controller/download_controller.dart';
import 'package:roccoplay/view_model/primium_controller/premium_controller.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../app/routes/app_routes.dart';
import '../../utils/share_helper.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../view_model/content_controller/content_controller.dart';
import '../../view_model/like_dislike_controller/like_dislike_controller.dart';
import '../../view_model/watchlist_controller/watchlist_controller.dart';
import '../popUp/age_popup.dart';
import '../../view_model/drama_detail_controller/drama_details_controller.dart';
import '../../utils/custom_snackbar.dart';
import '../../widgets/ad_widget/banner_ad_widget.dart';

class DramaDetailsPage extends StatefulWidget {
  final bool isSignedIn;
  final ContentModel content;

  const DramaDetailsPage({
    super.key,
    required this.isSignedIn,
    required this.content,
  });

  @override
  State<DramaDetailsPage> createState() => _DramaDetailsPageState();
}

class _DramaDetailsPageState extends State<DramaDetailsPage> {
  late final DramaDetailsController controller;
  late final AuthController authController;
  late final WatchlistController watchlistController;
  late final ContentController contentController;
  late final PremiumController premiumController;
  late final InteractionController interactionController;
  late final DownloadController downloadController;
  late final List<ContentModel> relatedContent;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<DramaDetailsController>()
        ? Get.find<DramaDetailsController>()
        : Get.put(DramaDetailsController());
    authController = Get.find<AuthController>();
    watchlistController = Get.isRegistered<WatchlistController>()
        ? Get.find<WatchlistController>()
        : Get.put(WatchlistController());
    contentController = Get.find<ContentController>();
    premiumController = Get.find<PremiumController>();
    interactionController = Get.isRegistered<InteractionController>()
        ? Get.find<InteractionController>()
        : Get.put(InteractionController());
    downloadController = Get.isRegistered<DownloadController>()
        ? Get.find<DownloadController>()
        : Get.put(DownloadController());

    // Filter "You May Also Like" once
    relatedContent = contentController.allContent.where((item) {
      return item.id != widget.content.id &&
          item.contentType == widget.content.contentType &&
          item.category.any((cat) => widget.content.category.contains(cat));
    }).toList();

    // Refresh subscription status ONCE on page entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authController.isLoggedIn.value) {
        premiumController.fetchAllSubscriptionStatus();
        interactionController.fetchInteractionStatus(widget.content.id);
      }
      // InterstitialAdHelper.loadAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.content;
    final isSignedIn = widget.isSignedIn;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(builder: (context, constraints) {
        bool isWeb = constraints.maxWidth > 800;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔥 Banner Section (Always Full Width)
              /// 🔥 Banner Section (Fixed Height)
              Stack(
                children: [
                  Container(
                    color: Colors.black,
                    height: isWeb ? 550 : 320,
                    width: double.infinity,
                    child: Image.network(
                      content.banner,
                      fit: BoxFit.contain,
                      cacheWidth: isWeb ? 1200 : 700,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        "assets/images/farzi.jpg",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  // Cinematic Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                            Colors.black,
                          ],
                          stops: const [0.0, 0.4, 0.85, 1.0],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: isWeb ? 20 : 40,
                    left: 10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  if (content.trailerUrl != null && content.trailerUrl!.isNotEmpty)
                    Positioned(
                      bottom: 30,
                      right: 20,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          padding: isWeb ? const EdgeInsets.symmetric(horizontal: 24, vertical: 18) : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () async {
                          final bool? isOver18 = await Get.dialog<bool>(
                            const AgeRestrictionPopup(),
                          );
                          if (isOver18 == true) {
                            Get.toNamed(
                              AppRoutes.advancedVideoPlayer,
                              arguments: {
                                'url': content.trailerUrl!,
                                'title': '${content.title} - Trailer',
                                'contentId': '${content.id}_trailer',
                              },
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.play_arrow,
                          color: AppColors.white,
                        ),
                        label: Text(
                          "Watch Trailer",
                          style: TextStyle(color: Colors.white, fontSize: isWeb ? 16 : 14),
                        ),
                      ),
                    ),
                ],
              ),



              /// 📝 Content Section (Centered on Web)
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWeb ? 900 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          content.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWeb ? 32 : 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "${content.releaseYear} • ${content.language} ${content.duration != null ? '• ${content.duration}' : ''}",
                          style: TextStyle(color: Colors.white70, fontSize: isWeb ? 16 : 14),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// 🔐 DYNAMIC WATCH & DOWNLOAD BUTTONS
                      if (content.contentType == "movie")
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Obx(() {
                                  final sub = premiumController.subscriptionData.value;
                                  final bool isPurchased = sub != null && sub['status'] == 'active';
                                  final bool userLoggedIn = authController.isLoggedIn.value;

                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonColor,
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                          ? "Sign In"
                                          : (isPurchased || !content.isPremium
                                              ? "Watch"
                                              : "Subscribe Now"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              if (!isWeb) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Obx(() {
                                    final sub =
                                        premiumController.subscriptionData.value;
                                    final bool isPurchased =
                                        sub != null && sub['status'] == 'active';
                                    final bool userLoggedIn =
                                        authController.isLoggedIn.value;
                                    final bool isAlreadyDownloaded =
                                        downloadController.isDownloaded(
                                          content.id,
                                        );
                                    final bool downloading =
                                        downloadController.isDownloading[
                                          content.id
                                        ] ??
                                        false;

                                    return OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Colors.white54),
                                        minimumSize: const Size(double.infinity, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (!userLoggedIn) {
                                          Get.toNamed(AppRoutes.signIn);
                                        } else if (isPurchased) {
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
                                            FirebaseAnalyticsService.instance
                                                .download(
                                                  contentId: content.id,
                                                  contentName: content.title,
                                                );
                                            downloadController.downloadVideo(content);
                                          }
                                        } else {
                                          _showSubscriptionDialog(context);
                                        }
                                      },
                                      child: downloading
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  height: 18,
                                                  width: 18,
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        downloadController
                                                            .downloadProgress[
                                                          content.id
                                                        ] ??
                                                        0,
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
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
                                          ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          )
                                          : const Text(
                                            "Download",
                                            style: TextStyle(color: Colors.white),
                                          ),
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ),


                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          content.description,
                          style: TextStyle(color: Colors.white70, fontSize: isWeb ? 16 : 14, height: 1.4),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Center(child: const BannerAdWidget()),
                      const SizedBox(height: 15),

                      /// ⭐ Action Buttons Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Obx(
                          () => Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              constraints: BoxConstraints(maxWidth: isWeb ? 500 : double.infinity),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      GestureDetector(
                                        onTap: watchlistController.isLoading.value
                                            ? null
                                            : () => watchlistController.toggleWatchlist(content.id.toString()),
                                        child: watchlistController.isLoading.value
                                            ? const SizedBox(
                                                height: 28,
                                                width: 28,
                                                child: CircularProgressIndicator(color: AppColors.buttonColor, strokeWidth: 2),
                                              )
                                            : Icon(
                                                watchlistController.isInWatchlist(content.id.toString())
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                                color: watchlistController.isInWatchlist(content.id.toString())
                                                    ? AppColors.buttonColor
                                                    : Colors.white,
                                                size: isWeb ? 30 : 26,
                                              ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Watchlist", style: TextStyle(color: Colors.white70, fontSize: isWeb ? 13 : 11)),
                                    ],
                                  ),
                                  _actionButton(
                                    icon: interactionController.isLiked.value ? Icons.thumb_up : Icons.thumb_up_outlined,
                                    label: "Like",
                                    isWeb: isWeb,
                                    onTap: () {
                                      MetaEventService.instance.bookmark(contentId: content.id, contentName: content.title);
                                      FirebaseAnalyticsService.instance.bookmark(contentId: content.id, contentName: content.title);
                                      interactionController.toggleLike(contentId: content.id, contentType: content.contentType);
                                    },
                                  ),
                                  _actionButton(
                                    icon: interactionController.isDisliked.value ? Icons.thumb_down : Icons.thumb_down_outlined,
                                    label: "Dislike",
                                    isWeb: isWeb,
                                    onTap: () => interactionController.toggleDislike(contentId: content.id, contentType: content.contentType),
                                  ),
                                  _actionButton(
                                    icon: Icons.share,
                                    label: "Share",
                                    isWeb: isWeb,
                                    onTap: () {
                                      ShareHelper.shareContent(title: content.title, slug: content.slug, imageUrl: content.poster);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 25),

                      /// 📺 EPISODES SECTION
                      if (content.contentType == "series" && content.seasons != null && content.seasons!.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Episodes",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (content.seasons!.length > 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Obx(
                              () => DropdownButton<int>(
                                value: controller.selectedSeason.value,
                                dropdownColor: Colors.black,
                                underline: Container(height: 1, color: AppColors.buttonColor),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                onChanged: (val) => controller.setSeason(val!),
                                items: List.generate(content.seasons!.length, (index) {
                                  return DropdownMenuItem(
                                    value: index,
                                    child: Text("Season ${content.seasons![index].seasonNumber}"),
                                  );
                                }),
                              ),
                            ),
                          ),

                        const SizedBox(height: 15),

                        Obx(() {
                          final seasonIndex = controller.selectedSeason.value;
                          final season = content.seasons![seasonIndex];
                          final sub = premiumController.subscriptionData.value;
                          final bool isPurchased = sub != null && sub['status'] == 'active';
                          final bool userLoggedIn = authController.isLoggedIn.value;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: season.episodes.length,
                            itemBuilder: (context, index) {
                              final ep = season.episodes[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                                      width: isWeb ? 150 : 100,
                                      height: isWeb ? 90 : 60,
                                      fit: BoxFit.fill,
                                      errorBuilder: (c, e, s) => Image.asset("assets/images/farzi.jpg", width: isWeb ? 150 : 100, height: isWeb ? 90 : 60, fit: BoxFit.fill),
                                    ),
                                  ),
                                  title: Text(ep.title, style: TextStyle(color: Colors.white, fontSize: isWeb ? 16 : 14)),
                                  subtitle: Text(ep.duration ?? "", style: TextStyle(color: Colors.white70, fontSize: isWeb ? 14 : 12)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!isWeb)
                                        Obx(() {
                                          final bool isDownloaded =
                                              downloadController.isDownloaded(ep.id);
                                          final bool downloading =
                                              downloadController.isDownloading[
                                                ep.id
                                              ] ??
                                              false;
                                          final double progress =
                                              downloadController.downloadProgress[
                                                ep.id
                                              ] ??
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
                                                Get.toNamed(AppRoutes.signIn);
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

                      if (content.contentType == "series")
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: BannerAdWidget())),

                      /// 🎭 Cast & Crew
                      if (content.cast != null && content.cast!.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Cast & Crew", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          height: isWeb ? 160 : 140,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: content.cast!.length,
                            padding: const EdgeInsets.only(left: 16),
                            itemBuilder: (context, index) {
                              final actor = content.cast![index];
                              return GestureDetector(
                                onTap: () => Get.toNamed(
                                  AppRoutes.castDetails,
                                  arguments: {'name': actor.name, 'image': actor.image},
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: isWeb ? 90 : 75,
                                        height: isWeb ? 110 : 95,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: (actor.image.isNotEmpty) ? NetworkImage(actor.image) : const AssetImage("assets/images/farzi.jpg") as ImageProvider,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: isWeb ? 90 : 75,
                                        child: Text(actor.name, style: TextStyle(color: Colors.white, fontSize: isWeb ? 12 : 11), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: NativeAdWidget(
                          adType: TemplateType.small,
                          constraints: BoxConstraints(minWidth: constraints.maxWidth, minHeight: 50, maxWidth: constraints.maxWidth, maxHeight: 100),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// ❤️ You May Also Like
                      if (relatedContent.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text("You May Also Like", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: isWeb ? 220 : 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: relatedContent.length,
                            itemBuilder: (context, index) {
                              final item = relatedContent[index];
                              return GestureDetector(
                                onTap: () => Get.toNamed(
                                  AppRoutes.dramaDetails,
                                  arguments: item,
                                  preventDuplicates: false,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      item.poster,
                                      width: isWeb ? 150 : 110,
                                      fit: BoxFit.fill,
                                      cacheWidth: isWeb ? 300 : 220,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Image.asset("assets/images/asur.webp", width: isWeb ? 150 : 110, fit: BoxFit.fill),
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
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required bool isWeb, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: isWeb ? 30 : 24),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.white70, fontSize: isWeb ? 14 : 12)),
        ],
      ),
    );
  }

  void _handlePlayback({required BuildContext context, required String? url, required String title, required String id, required bool isPremium, required bool isPurchased, required bool userLoggedIn}) async {
    if (!userLoggedIn) {
      Get.toNamed(AppRoutes.signIn);
      return;
    }
    if (isPremium && !isPurchased) {
      Get.toNamed(AppRoutes.goPremium);
      return;
    }
    if (url == null || url.isEmpty) {
      CustomSnackbar.show(title: "Error", message: "Video URL not found", isError: true);
      return;
    }
    final bool? proceed = await Get.dialog<bool>(const AgeRestrictionPopup());
    if (proceed == true) {
      MetaEventService.instance.videoPlay(contentId: id, contentName: title);
      FirebaseAnalyticsService.instance.videoPlay(contentId: id, contentName: title);
      Get.toNamed(
        AppRoutes.advancedVideoPlayer,
        arguments: {'url': url, 'title': title, 'contentId': id},
      );
    }
  }

  void _showSubscriptionDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, color: AppColors.buttonColor, size: 60),
                const SizedBox(height: 20),
                const Text("Subscription Required", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                const Text("This content is exclusive to premium members. Upgrade your plan to download and watch offline anytime.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, height: 1.5)),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        onPressed: () => Get.back(),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Get.back();
                          Get.toNamed(AppRoutes.goPremium);
                        },
                        child: const Text(
                          "EXPLORE PLANS",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
