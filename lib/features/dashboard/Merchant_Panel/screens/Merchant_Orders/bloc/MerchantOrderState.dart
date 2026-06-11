

import 'package:stoxneu/Screens/MyOrder/model/order_model.dart';


abstract class MerchantOrderState {}

/// Loading state
class MerchantOrderLoading extends MerchantOrderState {}

/// Loaded state with a list of orders
class MerchantOrderLoaded extends MerchantOrderState {
  final List<Order> orders;
  MerchantOrderLoaded({required this.orders});
}

/// Error state
class MerchantOrderError extends MerchantOrderState {
  final String message;
  MerchantOrderError(this.message);
}
// MerchantOrderState.dart
class RefundRequestInProgress extends MerchantOrderState {}
class RefundRequestSuccess extends MerchantOrderState {
  final String message;
  RefundRequestSuccess(this.message);
}
class RefundRequestFailure extends MerchantOrderState {
  final String message;
  RefundRequestFailure(this.message);
}

