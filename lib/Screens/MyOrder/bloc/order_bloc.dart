import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stoxneu/Screens/MyOrder/repository/order_repository.dart';
import 'order_event.dart';
import 'order_state.dart';
class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final OrderRepository repository;

  OrderBloc(this.repository) : super(OrderLoading()) {

    /// 🔄 LOAD ORDERS FROM API
    on<LoadOrders>((event, emit) async {
      emit(OrderLoading());
      try {
        final orders = await repository.getOrders();
        emit(OrderLoaded(orders: orders));
      } catch (e) {
        print("❌ LOAD ORDERS ERROR: $e"); // 👈 ADD THIS
        emit(OrderError("Failed to load orders"));
      }
    });


    /// ➕ ADD ORDER TO BACKEND
    on<AddOrder>((event, emit) async {
      if (state is OrderLoading) return; // 🔒 prevent duplicate call

      emit(OrderLoading());

      try {
        await repository.addOrder(event.order);
        final orders = await repository.getOrders();
        emit(OrderLoaded(orders: orders));
      } catch (e) {
        emit(OrderError("Order placement failed"));
      }
    });


    /// 💸 REQUEST REFUND
    on<RequestRefund>((event, emit) async {
      try {
        await repository.requestRefund(event.orderId,event.reason, event.productId);

        final orders = await repository.getOrders();
        emit(OrderLoaded(orders: orders));
      } catch (e) {
        emit(OrderError("Refund request failed"));
      }
    }
    );
  }
}

