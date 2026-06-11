import '../model/order_model.dart';

abstract class OrderState {}

class OrderLoading extends OrderState {}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  OrderLoaded({required this.orders});
}
class OrderError extends OrderState {
  final String message;
  OrderError(this.message);
}