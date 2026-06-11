import 'package:equatable/equatable.dart';
import '../../../model/refund_model.dart';

abstract class MerchantRefundState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RefundLoading extends MerchantRefundState {}

class RefundLoaded extends MerchantRefundState {
  final List<RefundRequest> refunds;
  RefundLoaded({required this.refunds});

  @override
  List<Object?> get props => [refunds];
}

class RefundError extends MerchantRefundState {
  final String message;
  RefundError(this.message);

  @override
  List<Object?> get props => [message];
}

class RefundActionInProgress extends MerchantRefundState {}
class RefundActionSuccess extends MerchantRefundState {
  final String message;
  RefundActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
class RefundActionFailure extends MerchantRefundState {
  final String message;
  RefundActionFailure(this.message);

  @override
  List<Object?> get props => [message];
}