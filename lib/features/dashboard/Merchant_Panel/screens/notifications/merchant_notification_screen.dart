import 'package:flutter/material.dart';
import 'package:stoxneu/features/dashboard/Merchant_Panel/screens/notifications/service/merchant_notification_api.dart';
import '../../../Admin_Panel/notifications/firebase_api.dart';
import '../Merchant_Orders/merchant_order_detail_screen.dart';
import '../Merchant_Payment/payment_screen.dart';
import '../Merchant_Refund/merchant_refund_screen.dart';
import 'model/merchant_notification_model.dart';

class MerchantNotificationScreen extends StatefulWidget {
  const MerchantNotificationScreen({super.key});

  @override
  State<MerchantNotificationScreen> createState() =>
      _MerchantNotificationScreenState();
}

class _MerchantNotificationScreenState
    extends State<MerchantNotificationScreen> {

  final MerchantNotificationApi _api = MerchantNotificationApi();

  List<MerchantNotificationModel> notifications = [];
  bool isLoading = true;
  bool _isMarking = false;
  int unreadCount = 0;
  @override
  void initState() {
    super.initState();
    loadNotifications();
    FirebaseApi.syncDeviceTokenWithIdentity();
  }

  // ========================= LOAD =========================
  Future<void> loadNotifications() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await _api.fetchNotifications();
      final count = await _api.fetchUnreadCount();

      setState(() {
        notifications = data;
        unreadCount = count;
        isLoading = false;
      });

    } catch (e) {

      setState(() {
        isLoading = false;
      });

      debugPrint("ERROR: $e");
    }
  }

  // ========================= ICON =========================
  IconData getIcon(String type) {
    switch (type.toUpperCase()) {
      case "ORDER_PLACED":
        return Icons.shopping_bag_rounded;
      case "ORDER_SHIPPED":
        return Icons.local_shipping_rounded;
      case "ORDER_DELIVERED":
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications;
    }
  }

  // ========================= COLOR =========================
  Color getColor(String type) {
    switch (type.toUpperCase()) {
      case "ORDER_PLACED":
        return Colors.orange;
      case "ORDER_SHIPPED":
        return Colors.blue;
      case "ORDER_DELIVERED":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // ========================= UI =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Merchant Notifications"),
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())

          : notifications.isEmpty
          ? const Center(child: Text("No notifications"))

          : RefreshIndicator(
        onRefresh: loadNotifications,

        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),

          itemBuilder: (context, index) {
            final notification = notifications[index];
            final color = getColor(notification.type);

            return Dismissible(
              key: ValueKey(notification.id),

              direction: DismissDirection.endToStart,

              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),

              onDismissed: (_) async {
                final removed = notification;

                setState(() {
                  notifications.removeAt(index);
                });

                try {
                  await _api.deleteNotification(notification.id);
                } catch (e) {
                  setState(() {
                    notifications.insert(index, removed);
                  });
                }
              },

              child: InkWell(
                onTap: () async {
                  if (_isMarking) return;
                  _isMarking = true;

                  try {
                    if (!notification.isRead) {
                      await _api.markAsRead(notification.id);

                      setState(() {
                        notifications[index] =
                            notification.copyWith(isRead: true);
                      });
                    }
                    unreadCount--;
                    handleNotificationTap(notification);
                  } catch (e) {
                    debugPrint(e.toString());
                  }

                  _isMarking = false;
                },

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? Colors.white
                        : Colors.orange.shade50,

                    borderRadius: BorderRadius.circular(18),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          getIcon(notification.type),
                          color: color,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            Text(
                              notification.body,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.grey.shade700,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              notification.createdAt,
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
            );
          },
        ),
      ),
    );
  }

  void handleNotificationTap(MerchantNotificationModel notification) {
    if (notification.orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No reference found")),
      );
      return;
    }

    switch (notification.type.toUpperCase()) {

      case "ORDER_PLACED":
      case "ORDER_CONFIRMED":
      case "ORDER_SHIPPED":
      case "ORDER_DELIVERED":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantOrderDetailScreen(
              orderId: notification.orderId!,
            ),
          ),
        );
        break;

      case "PAYMENT_RECEIVED":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantPaymentScreen(
              //paymentId: notification.orderId!, // or paymentId field
            ),
          ),
        );
        break;

      case "REFUND_REQUESTED":
      case "REFUND_APPROVED":
      case "REFUND_REJECTED":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MerchantRefundScreen(
              //orderId: notification.orderId!,
            ),
          ),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No screen mapped for ${notification.type}")),
        );
    }
  }
}