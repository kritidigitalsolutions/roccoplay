import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/routes/app_routes.dart';
import '../../data/models/response_model/content_response_model/content_model.dart';
import '../../data/models/response_model/popup_model/app_popup_model.dart';
import '../../data/network/api_network_service.dart';
import '../../data/network/base_api_service.dart';
import '../../data/repositories/popup_repository.dart';
import '../../utils/app_session.dart';
import '../../widgets/app_popup_dialog.dart';
import '../content_controller/content_controller.dart';

class AppPopupController extends GetxController {
  late final PopupRepository _repository;

  var isLoading = false.obs;
  var isActionLoading = false.obs;
  var activePopup = Rxn<AppPopupItemModel>();

  bool _isDialogShowing = false;
  Timer? _autoDismissTimer;

  // 🔒 App session flag: dialog shows only ONCE while app is running
  bool _hasShownInCurrentSession = false;

  @override
  void onInit() {
    super.onInit();
    final apiService = Get.isRegistered<BaseApiService>()
        ? Get.find<BaseApiService>()
        : NetworkApiService();
    _repository = PopupRepository(apiService);
  }

  @override
  void onClose() {
    _autoDismissTimer?.cancel();
    super.onClose();
  }

  /// 📥 Fetch Active App Popup & Display if Available (Only once per app launch session)
  Future<void> fetchActivePopup({bool autoShow = true}) async {
    // 🛑 If popup was already shown during this app session, do not hit/show again until app is re-opened
    if (_hasShownInCurrentSession) {
      debugPrint("ℹ️ [AppPopup] Already shown in this app session. Skipping.");
      return;
    }

    try {
      isLoading.value = true;
      final response = await _repository.getActivePopup();

      if (response != null &&
          response.hasActivePopup &&
          response.popup != null) {
        final popup = response.popup!;

        // 🔍 Check Local Storage: isPopupCompleted(popup.id)?
        if (AppSession.isPopupCompleted(popup.id)) {
          debugPrint(
            "🚫 [AppPopup] Popup ${popup.id} is already completed in local storage. Not showing.",
          );
          activePopup.value = null;
          return;
        }

        activePopup.value = popup;

        if (autoShow) {
          // 🚀 PRECACHE image before opening dialog so it renders INSTANTLY with 0 delay!
          final candidateUrls = AppPopupDialog.getCandidateUrls(popup);
          if (candidateUrls.isNotEmpty && Get.context != null) {
            try {
              final provider = AppPopupDialog.getImageProvider(
                candidateUrls.first,
              );
              await precacheImage(
                provider,
                Get.context!,
              ).timeout(const Duration(milliseconds: 2500));
            } catch (e) {
              debugPrint("⚠️ [AppPopup] Precache error/timeout: $e");
            }
          }

          // ⏱️ Home content pehle show hoga, fir 5 seconds delay ke baad dialog open hoga
          Future.delayed(const Duration(seconds: 5), () {
            if (!_hasShownInCurrentSession &&
                activePopup.value != null &&
                !_isDialogShowing) {
              showPopupDialog();
            }
          });
        }
      } else {
        activePopup.value = null;
      }
    } catch (e) {
      debugPrint("⚠️ fetchActivePopup error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 📲 Display Popup Modal Dialog with 20 Second Auto-Dismiss
  void showPopupDialog() {
    if (_hasShownInCurrentSession ||
        _isDialogShowing ||
        activePopup.value == null) {
      return;
    }
    final popup = activePopup.value!;

    // Check if dialog is already open
    if (Get.isDialogOpen == true) return;

    _isDialogShowing = true;
    _hasShownInCurrentSession = true; // ✅ Mark as shown for this app session

    // ⏱️ Auto-dismiss dialog after 20 seconds if user takes no action
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 20), () {
      if (_isDialogShowing && Get.isDialogOpen == true) {
        debugPrint(
          "⏰ [AppPopupController] Auto-dismissing popup after 20 seconds",
        );
        onDismissClicked();
      }
    });

    Get.dialog(
      AppPopupDialog(popup: popup),
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      transitionDuration: const Duration(milliseconds: 280),
    ).then((_) {
      _isDialogShowing = false;
      _autoDismissTimer?.cancel();
    });
  }

  /// ❌ User taps "Maybe later" or (✕) or 20s timer expires:
  /// [Close Modal Only] - Does NOT save in local storage, will show again on next app launch
  void onDismissClicked([BuildContext? context]) {
    cleanupAfterDismiss();

    // 1. Try closing via local BuildContext first (100% reliable on Web)
    if (context != null) {
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
          return;
        }
      } catch (e) {
        debugPrint("⚠️ [AppPopup] context pop error: $e");
      }
    }

    // 2. Try Get.back() if Get dialog is open
    if (Get.isDialogOpen == true) {
      Get.back();
      return;
    }

    // 3. Fallback to Get.context root navigator
    if (Get.context != null) {
      try {
        if (Navigator.of(Get.context!, rootNavigator: true).canPop()) {
          Navigator.of(Get.context!, rootNavigator: true).pop();
        }
      } catch (e) {
        debugPrint("⚠️ [AppPopup] Get.context pop error: $e");
      }
    }
  }

  /// 🧹 Clean up timers and state when dialog is dismissed
  void cleanupAfterDismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _isDialogShowing = false;
    activePopup.value = null;
  }

  /// 🎬 User taps Action Button ("Watch Now"):
  /// 1. Save in Local Storage: popup_completed_<id> = true
  /// 2. Call POST /:id/action-completed with user token
  /// 3. Navigate to popup.actionUrl / content details page
  Future<void> onWatchNowClicked(BuildContext context) async {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;

    final popup = activePopup.value;
    if (popup == null) return;

    try {
      isActionLoading.value = true;

      // 1. Save in Local Storage: popup_completed_<id> = true
      await AppSession.setPopupCompleted(popup.id);
      debugPrint(
        "💾 [AppPopup] Marked popup_completed_${popup.id} = true in local storage",
      );

      // 2. Call POST /:id/action-completed API with user token
      final token = AppSession.getToken();
      _repository
          .markActionCompleted(popup.id, token: token)
          .catchError((_) => false);

      // 3. Dismiss popup dialog
      cleanupAfterDismiss();
      try {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        } else if (Get.isDialogOpen == true) {
          Get.back();
        }
      } catch (_) {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
      }
      _isDialogShowing = false;

      // 3. Initialize content controller & load content if needed
      ContentController contentController;
      if (Get.isRegistered<ContentController>()) {
        contentController = Get.find<ContentController>();
      } else {
        contentController = Get.put(ContentController(), permanent: true);
      }

      if (contentController.allContent.isEmpty) {
        try {
          await contentController.fetchContent();
        } catch (e) {
          debugPrint("⚠️ Content init error: $e");
        }
      }

      // 4. Find matched content
      ContentModel? matchedContent;

      // Search by ID
      if (popup.contentId.isNotEmpty) {
        matchedContent = contentController.allContent.firstWhereOrNull(
          (c) => c.id == popup.contentId,
        );
      }

      // Search by slug from actionUrl (e.g. /movie/bablusha -> bablusha)
      if (matchedContent == null && popup.actionUrl.isNotEmpty) {
        final slug =
            popup.actionUrl.split('/').where((s) => s.isNotEmpty).lastOrNull ??
            '';
        if (slug.isNotEmpty) {
          matchedContent = contentController.allContent.firstWhereOrNull(
            (c) => c.slug.toLowerCase() == slug.toLowerCase(),
          );
        }
      }

      // Search by title
      if (matchedContent == null &&
          popup.content != null &&
          popup.content!.title.isNotEmpty) {
        final title = popup.content!.title.trim().toLowerCase();
        matchedContent = contentController.allContent.firstWhereOrNull(
          (c) =>
              c.title.trim().toLowerCase() == title ||
              c.title.trim().toLowerCase().contains(title),
        );
      }

      // Search across categories map
      if (matchedContent == null) {
        for (final list in contentController.categoryContentMap.values) {
          if (popup.contentId.isNotEmpty) {
            matchedContent = list.firstWhereOrNull(
              (c) => c.id == popup.contentId,
            );
            if (matchedContent != null) break;
          }
        }
      }

      // 5. Fallback ContentModel if not in cache so details page still opens cleanly
      final fallbackSlug = popup.actionUrl.isNotEmpty
          ? popup.actionUrl.split('/').where((s) => s.isNotEmpty).lastOrNull ??
                'movie'
          : 'movie';

      final poster = popup.content?.poster.isNotEmpty == true
          ? popup.content!.poster
          : popup.imageUrl;
      final banner = popup.content?.banner.isNotEmpty == true
          ? popup.content!.banner
          : (popup.imageUrl.isNotEmpty ? popup.imageUrl : poster);

      final targetContent =
          matchedContent ??
          ContentModel(
            id: popup.contentId.isNotEmpty ? popup.contentId : popup.id,
            title: popup.content?.title.isNotEmpty == true
                ? popup.content!.title
                : 'Featured Content',
            description: popup.description,
            genre: [],
            releaseYear: DateTime.now().year,
            duration: '',
            language: '',
            poster: poster,
            banner: banner,
            videoUrl: '',
            trailerUrl: '',
            isPremium: false,
            rating: 0.0,
            cast: [],
            category: ['series', 'drama', popup.contentType],
            slug: fallbackSlug,
            contentType: popup.contentType,
            seasons: [],
          );

      // 6. Navigate to DramaDetailsPage
      Get.toNamed(
        AppRoutes.dramaDetails,
        arguments: targetContent,
        preventDuplicates: false,
      );
    } catch (e) {
      debugPrint("⚠️ onWatchNowClicked error: $e");
    } finally {
      isActionLoading.value = false;
      activePopup.value = null;
    }
  }
}
