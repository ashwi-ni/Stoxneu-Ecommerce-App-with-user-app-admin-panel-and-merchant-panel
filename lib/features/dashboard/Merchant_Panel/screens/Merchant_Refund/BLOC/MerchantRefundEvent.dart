import 'package:equatable/equatable.dart';

abstract class MerchantRefundEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRefundRequests extends MerchantRefundEvent {
  final String status;

  LoadRefundRequests(this.status);
}

class ApproveRefundRequest extends MerchantRefundEvent {
  final int refundId;
  final String note;

  ApproveRefundRequest(this.refundId, this.note);

  @override
  List<Object?> get props => [refundId, note]; // ✅ ADD NOTE
}

class RejectRefundRequest extends MerchantRefundEvent {
  final int refundId;
  final String note;

  RejectRefundRequest(this.refundId, this.note);

  @override
  List<Object?> get props => [refundId, note]; // ✅ ADD NOTE
}