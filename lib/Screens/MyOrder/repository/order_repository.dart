import 'package:stoxneu/Screens/MyOrder/API/OrderApi.dart';
import '../model/order_model.dart';

class OrderRepository {
  final OrderApiService api;

  OrderRepository(this.api);

  Future<List<Order>> getOrders() => api.fetchOrders();

  Future<void> addOrder(Order order) => api.createOrder(order);

  Future<void> requestRefund(String orderId, String reason,int productId) => api.requestRefund(orderId,reason,productId);
}
