import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../Screens/MyOrder/OrderDetailsScreen.dart';
import '../../../Screens/Products/ProductDetailsScreen.dart';
import '../../../config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../model/user_notification_model.dart';
import '../services/user_notification_api.dart';

class UserNotificationScreen extends StatefulWidget {
  const UserNotificationScreen({super.key});

  @override
  State<UserNotificationScreen> createState() =>
      _UserNotificationScreenState();
}

class _UserNotificationScreenState
    extends State<UserNotificationScreen> {

  final UserNotificationApi _api = UserNotificationApi();

  List<UserNotificationModel> notifications = [];

  bool isLoading = true;
  bool _isMarking = false;
//  int unreadCount = 0;
  @override
  void initState() {
    super.initState();
    loadNotifications();

  //  markNotificationsAsRead();
  }

  Future<void> markNotificationsAsRead() async {
    try {

      await ApiClient.put(
        Uri.parse(
          '${ApiConfig.baseUrl}/user/notifications/read',
        ),
      );

    } catch (e) {
      print(e);
    }
  }
  // =====================================================
  // LOAD NOTIFICATIONS
  // =====================================================
  Future<void> loadNotifications() async {

    try {

      setState(() {
        isLoading = true;
      });

      final data = await _api.fetchNotifications();

      setState(() {
        notifications = data;
      });

    } catch (e) {

      debugPrint("NOTIFICATION ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Failed to load notifications",
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // GET ICON BASED ON TYPE
  // =====================================================
  IconData getNotificationIcon(String type) {

    switch (type.toUpperCase()) {

      case "ORDER_PLACED":
        return Icons.shopping_bag_rounded;

      case "ORDER_SHIPPED":
        return Icons.local_shipping_rounded;

      case "ORDER_DELIVERED":
        return Icons.check_circle_rounded;

      case "ORDER_REFUNDED":
        return Icons.currency_rupee_rounded;

      case "REFUND_REJECTED":
        return Icons.cancel_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  // =====================================================
  // GET ICON COLOR
  // =====================================================
  Color getNotificationColor(String type) {

    switch (type.toUpperCase()) {

      case "ORDER_PLACED":
        return Colors.blue;

      case "ORDER_SHIPPED":
        return Colors.orange;

      case "ORDER_DELIVERED":
        return Colors.green;

      case "ORDER_REFUNDED":
        return Colors.purple;

      case "REFUND_REJECTED":
        return Colors.red;

      default:
        return Colors.black87;
    }
  }

  // =====================================================
  // FORMAT DATE
  // =====================================================
  String formatDate(String rawDate) {

    try {

      final date = DateTime.parse(rawDate);

      return DateFormat(
        "dd MMM yyyy • hh:mm a",
      ).format(date);

    } catch (e) {

      return rawDate;
    }
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================
  Widget buildEmptyState() {

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Container(
              width: 110,
              height: 110,

              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.notifications_none_rounded,
                size: 55,
                color: Colors.blue.shade400,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "No Notifications Yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Your latest order updates, refunds,\nshipping alerts and announcements\nwill appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,

        backgroundColor: Colors.white,

        centerTitle: true,

        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),

        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: isLoading

          ? const Center(
        child: CircularProgressIndicator(),
      )

          : notifications.isEmpty

          ? buildEmptyState()

          : RefreshIndicator(

        onRefresh: loadNotifications,

        child: ListView.separated(

          physics:
          const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(16),

          itemCount: notifications.length,

          separatorBuilder: (_, __) =>
          const SizedBox(height: 14),

          itemBuilder: (context, index) {

            final notification =
            notifications[index];

            final iconColor =
            getNotificationColor(
              notification.type,
            );

            return Dismissible(

              key: ValueKey(notification.id),

              direction: DismissDirection.endToStart,

              background: Container(

                alignment: Alignment.centerRight,

                padding: const EdgeInsets.symmetric(horizontal: 24),

                margin: const EdgeInsets.only(bottom: 2),

                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(22),
                ),

                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              confirmDismiss: (_) async {

                return await showDialog(

                  context: context,

                  builder: (_) => AlertDialog(

                    title: const Text("Delete Notification"),

                    content: const Text(
                      "Are you sure you want to delete this notification?",
                    ),

                    actions: [

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: const Text("Cancel"),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },

              onDismissed: (_) async {

                final deletedItem = notification;

                setState(() {
                  notifications.removeAt(index);
                });

                try {

                  await _api.deleteNotification(notification.id);

                } catch (e) {

                  setState(() {
                    notifications.insert(index, deletedItem);
                  });

                  debugPrint(e.toString());
                }
              },

              child: Material(

                color: Colors.transparent,

                child: InkWell(

                  borderRadius: BorderRadius.circular(22),

                    onTap: () async {

                      if (_isMarking) return;

                      _isMarking = true;

                      print("CARD CLICKED");

                      try {
                        if (!notification.isRead) {
                          await _api.markAsRead(notification.id);

                          setState(() {
                            notifications[index] =
                                notification.copyWith(isRead: true);
                          });
                        }
                        // navigate
                    //    handleNotificationTap(notification);
                      } catch (e) {
                        print(e);
                      }

                      _isMarking = false;
                    },

                  child: AnimatedContainer(

                    duration: const Duration(milliseconds: 250),

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(

                      color: notification.isRead
                          ? Colors.white
                          : Colors.blue.shade50,

                      borderRadius: BorderRadius.circular(22),

                      border: Border.all(
                        color: Colors.grey.shade100,
                      ),

                      boxShadow: [

                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        // ICON
                        Container(

                          width: 42,
                          height: 42,

                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Icon(
                            getNotificationIcon(notification.type),
                            color: iconColor,
                            size: 22,
                          ),
                        ),

                        const SizedBox(width: 14),

                        // TEXT
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [

                              Row(
                                children: [

                                  Expanded(
                                    child: Text(

                                      notification.title,

                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: notification.isRead
                                            ? FontWeight.w600
                                            : FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  if (!notification.isRead)
                                    Container(
                                      width: 10,
                                      height: 10,

                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 7),

                              Text(

                                notification.body,

                                style: TextStyle(
                                  fontSize: 13.5,
                                  height: 1.5,
                                  color: Colors.grey.shade700,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(

                                formatDate(notification.createdAt),

                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // void handleNotificationTap(UserNotificationModel notification) {
  //
  //   print("TYPE = ${notification.type}");
  //   print("REF ID = ${notification.refId}");
  //
  //   if (notification.refId == null) {
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Reference ID missing"),
  //       ),
  //     );
  //
  //     return;
  //   }
  //
  //   switch (notification.type.toUpperCase()) {
  //
  //     case "ORDER":
  //
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => OrderDetailsScreen(
  //             orderId: notification.refId!,
  //           ),
  //         ),
  //       );
  //
  //       break;
  //
  //     case "PRODUCT":
  //
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (_) => ProductDetailsScreen(
  //             productId: notification.refId!,
  //           ),
  //         ),
  //       );
  //
  //       break;
  //
  //     case "WALLET":
  //
  //     // Navigator.push(
  //     //   context,
  //     //   MaterialPageRoute(
  //     //     builder: (_) => WalletScreen(),
  //     //   ),
  //     // );
  //
  //       break;
  //
  //     default:
  //
  //       print("No navigation defined for type: ${notification.type}");
  //   }
  // }
}