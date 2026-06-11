
abstract class MerchantOrderEvent {}

/// Load all merchant orders
class LoadMerchantOrders extends MerchantOrderEvent {}

/// Confirm an order
class ConfirmMerchantOrder extends MerchantOrderEvent {
  final String orderId;
  ConfirmMerchantOrder(this.orderId);
}

/// Cancel an order
class CancelMerchantOrder extends MerchantOrderEvent {
  final String orderId;
  CancelMerchantOrder(this.orderId);
}
/// Mark an order as shipped
class MarkMerchantOrderShipped extends MerchantOrderEvent {
  final String orderId;
  MarkMerchantOrderShipped(this.orderId);
}
/// Mark an order as delivered
class MarkMerchantOrderDelivered extends MerchantOrderEvent {
  final String orderId;
  MarkMerchantOrderDelivered(this.orderId);
}
class InitiateRefundRequest extends MerchantOrderEvent {
  final int orderId;
  InitiateRefundRequest(this.orderId);
}


