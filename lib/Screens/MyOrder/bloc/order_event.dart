import '../model/order_model.dart';

abstract class OrderEvent {}

class LoadOrders extends OrderEvent {}

class AddOrder extends OrderEvent {
  final Order order;
  AddOrder(this.order);
}
class RequestRefund extends OrderEvent {
  final String orderId;
  final String reason;
  final int productId;// Add this
  RequestRefund(this.orderId, {required this.reason, required this.productId});
}
