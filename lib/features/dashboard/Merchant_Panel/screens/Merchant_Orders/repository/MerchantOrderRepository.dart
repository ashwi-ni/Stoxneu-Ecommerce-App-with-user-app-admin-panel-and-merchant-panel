
import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';
import 'package:stoxneu/features/dashboard/Merchant_Panel/ApiService/merchant_order_api_service.dart';
import 'package:stoxneu/features/dashboard/Merchant_Panel/model/refund_model.dart';

class MerchantOrderRepository {
  final MerchantOrderApiService api;

  MerchantOrderRepository(this.api);

  Future<List<Order>> getOrders() => api.fetchMerchantOrders();

  Future<void> confirmOrder(String orderId) => api.confirmOrder(orderId);
  Future<void> cancelOrder(String orderId) => api.cancelOrder(orderId);
  Future<void> markDelivered(String orderId) => api.markDelivered(orderId);
  Future<void> markShipped(String orderId) => api.markShipped(orderId);
  // ------------------ Initiate Refund ------------------
  Future<bool> initiateRefund(int orderId ) async {
    try {
      // Call the MySQL return API
      final response = await api.initiateRefund(orderId );

      // Returns true if API succeeded
      return response;
    } catch (e) {
      print("Error initiating refund: $e");
      return false;
    }
  }
  // 🔹 Refund methods
  Future<List<RefundRequest>> getRefundRequests(String status) =>
      api.fetchRefundRequests(status);
  Future<bool> approveRefund(int refundId, String note) => api.approveRefund(refundId,note);
  Future<bool> rejectRefund(int refundId, String note) => api.rejectRefund(refundId,note);
}