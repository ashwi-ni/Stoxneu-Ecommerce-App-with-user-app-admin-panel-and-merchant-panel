import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Merchant_Orders/repository/MerchantOrderRepository.dart';

import 'MerchantRefundEvent.dart';
import 'MerchantRefundState.dart';

class MerchantRefundBloc extends Bloc<MerchantRefundEvent, MerchantRefundState> {
  final MerchantOrderRepository repository;

  MerchantRefundBloc(this.repository) : super(RefundLoading()) {
    // Load refund requests
    on<LoadRefundRequests>((event, emit) async {
      emit(RefundLoading());
      try {
        final refunds = await repository.getRefundRequests(event.status);
        emit(RefundLoaded(refunds: refunds));
      } catch (e) {
        emit(RefundError("Failed to load refund request: ${e.toString()}"));
      }
    });

    // Approve refund
    on<ApproveRefundRequest>((event, emit) async {
      emit(RefundActionInProgress());
      try {
        final success = await repository.approveRefund(
          event.refundId,
          event.note, // ✅ PASS NOTE
        );
        if (success) {
          emit(RefundActionSuccess("Refund approved"));
          add(LoadRefundRequests("pending")); // reload list
        } else {
          emit(RefundActionFailure("Failed to approve refund"));
        }
      } catch (e) {
        emit(RefundActionFailure("Error: ${e.toString()}"));
      }
    });

    // Reject refund
    on<RejectRefundRequest>((event, emit) async {
      emit(RefundActionInProgress());
      try {
        final success = await repository.rejectRefund(
          event.refundId,
          event.note, // ✅ PASS NOTE
        );
        if (success) {
          emit(RefundActionSuccess("Refund rejected"));
          add(LoadRefundRequests("pending")); // reload list
        } else {
          emit(RefundActionFailure("Failed to reject refund"));
        }
      } catch (e) {
        emit(RefundActionFailure("Error: ${e.toString()}"));
      }
    });
  }
}