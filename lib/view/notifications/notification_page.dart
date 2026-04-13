import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/notification_service.dart';
import '../../app/theme/app_colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService.to;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            onPressed: () {
              Get.defaultDialog(
                title: "Clear All",
                middleText: "Are you sure you want to clear all notifications?",
                backgroundColor: AppColors.black,
                titleStyle: const TextStyle(color: Colors.white),
                middleTextStyle: const TextStyle(color: Colors.white70),
                textConfirm: "Clear",
                textCancel: "Cancel",
                confirmTextColor: Colors.white,
                buttonColor: AppColors.buttonColor,
                onConfirm: () {
                  notificationService.clearNotifications();
                  Get.back();
                },
              );
            },
          ),
        ],
      ),
      body: Obx(() {
        if (notificationService.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 80, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  "No notifications yet",
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notificationService.notifications.length,
          itemBuilder: (context, index) {
            final notification = notificationService.notifications[index];
            final DateTime time = DateTime.parse(notification['time']);
            final String formattedTime = DateFormat('dd MMM, hh:mm a').format(time);

            return Dismissible(
              key: Key(notification['time']),
              onDismissed: (direction) {
                notificationService.notifications.removeAt(index);
                // In a real app, update Hive here too
              },
              background: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: notification['isRead']
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: notification['isRead']
                      ? null
                      : Border.all(color: AppColors.buttonColor.withOpacity(0.5), width: 1),
                ),
                child: ListTile(
                  onTap: () {
                    notificationService.markAsRead(index);
                  },
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: notification['isRead']
                        ? Colors.grey.withOpacity(0.2)
                        : AppColors.buttonColor,
                    child: const Icon(Icons.notifications, color: Colors.white),
                  ),
                  title: Text(
                    notification['title'] ?? 'No Title',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['body'] ?? 'No Body',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formattedTime,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
