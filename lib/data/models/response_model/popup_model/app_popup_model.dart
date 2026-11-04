import 'dart:convert';

class AppPopupResponseModel {
  final bool success;
  final bool hasActivePopup;
  final AppPopupItemModel? popup;
  final List<AppPopupItemModel> popups;

  AppPopupResponseModel({
    required this.success,
    required this.hasActivePopup,
    this.popup,
    this.popups = const [],
  });

  factory AppPopupResponseModel.fromJson(Map<String, dynamic> json) {
    AppPopupItemModel? singlePopup;
    if (json['popup'] != null) {
      if (json['popup'] is Map<String, dynamic>) {
        singlePopup = AppPopupItemModel.fromJson(json['popup']);
      } else if (json['popup'] is Map) {
        singlePopup = AppPopupItemModel.fromJson(
          Map<String, dynamic>.from(json['popup']),
        );
      } else if (json['popup'] is String && (json['popup'] as String).trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(json['popup']);
          if (decoded is Map) {
            singlePopup = AppPopupItemModel.fromJson(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {}
      }
    }

    final List<AppPopupItemModel> list = [];
    if (json['popups'] != null && json['popups'] is List) {
      for (final item in json['popups']) {
        if (item is Map<String, dynamic>) {
          list.add(AppPopupItemModel.fromJson(item));
        } else if (item is Map) {
          list.add(AppPopupItemModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Fallback: If single popup is null but popups list has items
    if (singlePopup == null && list.isNotEmpty) {
      singlePopup = list.first;
    }

    final bool hasActive =
        json['hasActivePopup'] == true || (singlePopup != null);

    return AppPopupResponseModel(
      success: json['success'] == true,
      hasActivePopup: hasActive,
      popup: singlePopup,
      popups: list,
    );
  }
}

class AppPopupItemModel {
  final String id;
  final String description;
  final String imageUrl;
  final String contentType;
  final String contentId;
  final PopupContentInfo? content;
  final String actionButtonText;
  final String actionUrl;
  final int priority;
  final String? createdAt;

  AppPopupItemModel({
    required this.id,
    required this.description,
    required this.imageUrl,
    required this.contentType,
    required this.contentId,
    this.content,
    required this.actionButtonText,
    required this.actionUrl,
    required this.priority,
    this.createdAt,
  });

  factory AppPopupItemModel.fromJson(Map<String, dynamic> json) {
    PopupContentInfo? contentInfo;
    dynamic rawContent = json['content'];
    if (rawContent is String && rawContent.trim().isNotEmpty) {
      try {
        rawContent = jsonDecode(rawContent);
      } catch (_) {}
    }
    if (rawContent != null && rawContent is Map<String, dynamic>) {
      contentInfo = PopupContentInfo.fromJson(rawContent);
    } else if (rawContent != null && rawContent is Map) {
      contentInfo = PopupContentInfo.fromJson(
        Map<String, dynamic>.from(rawContent),
      );
    }

    // Extract image with extensive fallbacks
    final String parsedImageUrl = (json['imageUrl'] ??
            json['image_url'] ??
            json['image'] ??
            json['banner'] ??
            json['poster'] ??
            json['popupImage'] ??
            contentInfo?.banner ??
            contentInfo?.poster ??
            '')
        .toString()
        .trim();

    return AppPopupItemModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: parsedImageUrl,
      contentType: (json['contentType'] ?? json['type'] ?? 'movie').toString(),
      contentId: (json['contentId'] ?? contentInfo?.id ?? '').toString(),
      content: contentInfo,
      actionButtonText: (json['actionButtonText'] ?? 'Watch Now').toString(),
      actionUrl: (json['actionUrl'] ?? json['action_url'] ?? '').toString(),
      priority: json['priority'] is int
          ? json['priority']
          : int.tryParse(json['priority']?.toString() ?? '1') ?? 1,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'imageUrl': imageUrl,
      'contentType': contentType,
      'contentId': contentId,
      'content': content?.toJson(),
      'actionButtonText': actionButtonText,
      'actionUrl': actionUrl,
      'priority': priority,
      'createdAt': createdAt,
    };
  }
}

class PopupContentInfo {
  final String id;
  final String title;
  final String contentType;
  final String poster;
  final String banner;

  PopupContentInfo({
    required this.id,
    required this.title,
    required this.contentType,
    required this.poster,
    required this.banner,
  });

  factory PopupContentInfo.fromJson(Map<String, dynamic> json) {
    final posterUrl = (json['poster'] ??
            json['imageUrl'] ??
            json['image_url'] ??
            json['image'] ??
            '')
        .toString()
        .trim();
    final bannerUrl = (json['banner'] ??
            json['imageUrl'] ??
            json['image_url'] ??
            json['image'] ??
            posterUrl)
        .toString()
        .trim();

    return PopupContentInfo(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      contentType: (json['contentType'] ?? json['type'] ?? 'movie').toString(),
      poster: posterUrl,
      banner: bannerUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'contentType': contentType,
      'poster': poster,
      'banner': banner,
    };
  }
}

