import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io' if (dart.library.html) 'package:roccoplay/utils/io_stub.dart' as io;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:roccoplay/view_model/download_controller/download_controller.dart';
import 'package:roccoplay/widgets/ad_widget/native_ad_widget.dart';

import '../../app/routes/app_routes.dart';
import '../../view_model/auth_controller/auth_controller.dart';
import '../../view_model/home_controller/home_controller.dart';
import '../../utils/custom_snackbar.dart';
import '../../widgets/ad_widget/banner_ad_widget.dart';
import '../../app/theme/app_colors.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HomeController homeController = Get.find<HomeController>();
    final DownloadController downloadController = Get.put(DownloadController());

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWeb = constraints.maxWidth > 800;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 850 : double.infinity),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    /// 🔹 TOP COMPACT HEADER (Consistent with Search Screen)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: "Down",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: "loads",
                              style: TextStyle(
                                color: AppColors.buttonColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    /// 🔹 CONTENT AREA (Empty state or Download list)
                    Expanded(
                      child: Obx(() {
                        /// 🔐 NOT LOGGED IN
                        if (!authController.isLoggedIn.value) {
          return _buildEmptyState(
            context: context,
            title: "Sign In to View Downloads",
            subtitle: "Sign in to access your downloaded movies and shows to watch offline anytime.",
            buttonText: "Sign In",
            onTap: () => Get.toNamed(AppRoutes.signIn),
          );
        }

        /// 📭 EMPTY DOWNLOADS
        if (downloadController.downloadedContent.isEmpty) {
          return _buildEmptyState(
            context: context,
            title: "No Downloads Yet",
            subtitle: "Download your favourite movies and shows to watch offline anytime.",
            buttonText: "Explore",
            onTap: () => homeController.selectedIndex.value = 0,
          );
        }

        /// 📥 DOWNLOAD LIST
        return Column(
          children: [
            /// 📲 Banner Ad at top of downloads
            const BannerAdWidget(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 110),
                itemCount: downloadController.downloadedContent.length,
                itemBuilder: (context, index) {
                  final item = downloadController.downloadedContent[index];
                  final localPath = downloadController.getLocalPath(item.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),

                      /// 🎬 OPEN DETAILS PAGE
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.dramaDetails,
                          arguments: item,
                        );
                      },

                      /// 🎞 POSTER
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.poster,
                          width: 55,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.movie,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),

                      /// 📄 TITLE + DETAILS
                      title: Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${item.releaseYear} • ${item.language}",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),

                      /// 🎯 ACTION BUTTONS
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// ▶ PLAY OFFLINE
                          IconButton(
                            icon: const Icon(
                              Icons.play_circle_fill,
                              color: Colors.green,
                              size: 28,
                            ),
                            onPressed: () {
                              if (!kIsWeb &&
                                  localPath != null &&
                                  (io.File(localPath) as dynamic).existsSync()) {
                                Get.toNamed(
                                  AppRoutes.advancedVideoPlayer,
                                  arguments: {
                                    'url': localPath,
                                    'title': item.title,
                                    'contentId': item.id,
                                  },
                                );
                              } else {
                                CustomSnackbar.show(
                                  title: "Error",
                                  message: kIsWeb
                                      ? "Offline play is not supported on web."
                                      : "File not found. Please download again.",
                                  isError: true,
                                );
                              }
                            },
                          ),

                          /// 🗑 DELETE
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              Get.defaultDialog(
                                title: "Delete Download",
                                middleText:
                                    "Are you sure you want to delete this download?",
                                textConfirm: "Delete",
                                textCancel: "Cancel",
                                confirmTextColor: Colors.white,
                                buttonColor: Colors.red,
                                onConfirm: () {
                                  downloadController.removeDownload(item.id);
                                  Get.back();
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🔄 REDESIGNED CENTERED EMPTY / LOGIN STATE
  Widget _buildEmptyState({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWeb = constraints.maxWidth > 800;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: isWeb ? 40 : 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 12),

                  /// 🔹 CENTERED EMPTY STATE BLOCK
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 1. Subtle Circular Illustration Container with Pink Glow
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF16161F),
                            border: Border.all(
                              color: AppColors.buttonColor.withOpacity(0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.buttonColor.withOpacity(0.12),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.download_for_offline_outlined,
                              size: 48,
                              color: AppColors.buttonColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// 2. Prominent Title
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        /// 3. Comfortable Description / Subtitle
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 14,
                              height: 1.45,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        /// 4. Explore Button (Positioned directly below description)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonColor,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.buttonColor.withOpacity(0.35),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: onTap,
                          child: Text(
                            buttonText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔹 BOTTOM AD AREA (Separated cleanly from empty state)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isWeb ? 500 : double.infinity,
                          ),
                          child: NativeAdWidget(
                            adType: TemplateType.small,
                            constraints: BoxConstraints(
                              minWidth: 320,
                              minHeight: 90,
                              maxWidth: isWeb ? 500 : double.infinity,
                              maxHeight: 120,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100), // Clearance for floating CustomBottomNavbar
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
