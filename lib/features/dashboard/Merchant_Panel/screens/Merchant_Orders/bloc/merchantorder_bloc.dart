import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stoxneu/Screens/MyOrder/bloc/order_event.dart';
import 'package:stoxneu/Screens/MyOrder/bloc/order_state.dart';
import 'package:stoxneu/Screens/MyOrder/repository/order_repository.dart';


import 'package:flutter_bloc/flutter_bloc.dart';

import '../repository/MerchantOrderRepository.dart';
import 'MerchantOrderEvent.dart';
import 'MerchantOrderState.dart';


class MerchantOrderBloc extends Bloc<MerchantOrderEvent, MerchantOrderState> {
  final MerchantOrderRepository repository;

  MerchantOrderBloc(this.repository) : super(MerchantOrderLoading()) {
    on<LoadMerchantOrders>((event, emit) async {
      emit(MerchantOrderLoading());
      try {
        final orders = await repository.getOrders();
        emit(MerchantOrderLoaded(orders: orders));
      } catch (e) {
        emit(MerchantOrderError("Failed to load merchant orders"));
      }
    });

    on<ConfirmMerchantOrder>((event, emit) async {
      try {
        await repository.confirmOrder(event.orderId);
        add(LoadMerchantOrders()); // refresh list
      } catch (e) {
        emit(MerchantOrderError("Confirm order failed"));
      }
    });

    on<CancelMerchantOrder>((event, emit) async {
      try {
        await repository.cancelOrder(event.orderId);
        add(LoadMerchantOrders());
      } catch (e) {
        emit(MerchantOrderError("Cancel order failed"));
      }
    });

    on<MarkMerchantOrderShipped>((event, emit) async {
      try {
        await repository.markShipped(event.orderId);
        add(LoadMerchantOrders());
      } catch (e) {
        emit(MerchantOrderError("Mark shipped failed"));
      }
    }
    );

    on<MarkMerchantOrderDelivered>((event, emit) async {
      try {
        await repository.markDelivered(event.orderId);
        add(LoadMerchantOrders());
      } catch (e) {
        emit(MerchantOrderError("Mark delivered failed"));
      }
    }
    );

    ///refund request///
// MerchantOrderBloc.dart
    on<InitiateRefundRequest>((event, emit) async {
      emit(RefundRequestInProgress());
      final success = await repository.initiateRefund(event.orderId);
      if (success) {
        emit(RefundRequestSuccess("Refund request initiated successfully"));
        add(LoadMerchantOrders());
      } else {
        emit(RefundRequestFailure("Failed to initiate refund"));
      }
    });


  }
}