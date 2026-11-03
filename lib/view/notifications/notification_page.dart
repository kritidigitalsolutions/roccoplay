import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/notification_service.dart';
import '../../app/theme/app_colors.dart';
import '../../app/routes/app_routes.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService notificationService = NotificationService.to;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔄 Pagination: Detect bottom scroll to load next page
  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll - currentScroll <= 250) {
        if (notificationService.hasMore &&
            !notificationService.isLoadingMore.value &&
            !notificationService.isLoading.value) {
          notificationService.loadMoreNotifications();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          Obx(
            () => notificationService.notifications.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.white),
                    onPressed: () {
                      _showClearAllDialog(context, notificationService);
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWeb ? 700 : double.infinity,
              ),
              child: RefreshIndicator(
                onRefresh: () =>
                    notificationService.fetchNotifications(refresh: true),
                color: AppColors.buttonColor,
                child: Obx(() {
                  if (notificationService.isLoading.value &&
                      notificationService.notifications.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.buttonColor,
                      ),
                    );
                  }

                  if (notificationService.notifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  final itemCount =
                      notificationService.notifications.length +
                      (notificationService.isLoadingMore.value ? 1 : 0);

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: itemCount,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemBuilder: (context, index) {
                      // Bottom loading indicator when fetching next page
                      if (index == notificationService.notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.buttonColor,
                            ),
                          ),
                        );
                      }

                      final notification =
                          notificationService.notifications[index];
                      return _buildNotificationItem(
                        context,
                        notification,
                        index,
                        notificationService,
                      );
                    },
                  );
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 100,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 20),
          Text(
            "No notifications yet",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getCandidateImages(Map<String, dynamic> notification) {
    final List<String> list = [];
    void add(dynamic val) {
      if (val == null) return;
      final s = val.toString().trim();
      if (s.isEmpty || s == 'null') return;
      final clean = NotificationService.sanitizeImageUrl(s);
      if (clean.isNotEmpty &&
          !clean.contains('google.com/search') &&
          !list.contains(clean)) {
        list.add(clean);
      }
    }

    add(notification['imageUrl']);
    if (notification['content'] is Map) {
      add(notification['content']['banner']);
      add(notification['content']['poster']);
    }
    add(notification['banner']);
    add(notification['poster']);
    return list;
  }

  Widget _buildCascadingThumbnail(List<String> urls, int idx, bool isRead) {
    if (idx >= urls.length) {
      return CircleAvatar(
        backgroundColor: isRead
            ? Colors.grey.withOpacity(0.2)
            : AppColors.buttonColor,
        child: const Icon(Icons.notifications, color: Colors.white, size: 20),
      );
    }

    final url = urls[idx];
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildCascadingThumbnail(urls, idx + 1, isRead);
        },
      ),
    );
  }

  Widget _buildCascadingBanner(List<String> urls, int idx) {
    if (idx >= urls.length) return const SizedBox.shrink();

    final url = urls[idx];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return _buildCascadingBanner(urls, idx + 1);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
    NotificationService service,
  ) {
    DateTime time;
    try {
      time = DateTime.parse(notification['time']);
    } catch (_) {
      time = DateTime.now();
    }
    final String formattedTime = DateFormat('dd MMM, hh:mm a').format(time);
    final bool isRead = notification['isRead'] ?? false;
    final List<String> candidateImages = _getCandidateImages(notification);

    return GestureDetector(
      onTap: () {
        service.markAsRead(index);
        _showNotificationDetail(
          context,
          notification,
          index,
          service,
          candidateImages,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: isRead
              ? null
              : Border.all(
                  color: AppColors.buttonColor.withOpacity(0.3),
                  width: 1,
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Thumbnail with cascading image fallback
            _buildCascadingThumbnail(candidateImages, 0, isRead),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showDeleteDialog(context, index, service);
                        },
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? notification['body'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetail(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
    NotificationService service,
    List<String> candidateImages,
  ) {
    final bool isContent =
        notification['content'] != null ||
        (notification['attachmentType'] != null &&
            notification['attachmentType'].toString().toLowerCase() ==
                'content');
    final bool isSubscription =
        notification['subscriptionPlan'] != null ||
        (notification['attachmentType'] != null &&
            notification['attachmentType'].toString().toLowerCase() ==
                'subscription');

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notification Detail",
                    style: TextStyle(
                      color: AppColors.buttonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 🖼️ Image Preview with cascading fallback
              if (candidateImages.isNotEmpty) ...[
                _buildCascadingBanner(candidateImages, 0),
                const SizedBox(height: 14),
              ],

              Text(
                notification['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notification['message'] ?? notification['body'] ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),

              // Action Buttons
              if (isContent) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text(
                    "Watch Now",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    service.handleSystemNotificationTap(notification);
                  },
                ),
                const SizedBox(height: 10),
              ] else if (isSubscription) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text(
                    "View Plans",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    Get.toNamed(AppRoutes.goPremium);
                  },
                ),
                const SizedBox(height: 10),
              ],

              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showClearAllDialog(BuildContext context, NotificationService service) {
    Get.defaultDialog(
      title: "Clear All",
      middleText: "Are you sure you want to clear all notifications?",
      backgroundColor: Colors.grey[900],
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: "Clear",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.buttonColor,
      onConfirm: () {
        service.clearNotifications();
        Get.back();
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    int index,
    NotificationService service,
  ) {
    Get.defaultDialog(
      title: "Delete Notification",
      middleText: "Are you sure you want to delete this notification?",
      backgroundColor: Colors.grey[900],
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      cancel: TextButton(
        onPressed: () {
          Get.back();
        },
        style: TextButton.styleFrom(backgroundColor: Colors.grey[700]),
        child: const Text("Cancel", style: TextStyle(color: Colors.white)),
      ),
      textConfirm: "Delete",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.buttonColor,
      onConfirm: () {
        service.deleteSingleNotification(index);
        Get.back();
      },
    );
  }
}
