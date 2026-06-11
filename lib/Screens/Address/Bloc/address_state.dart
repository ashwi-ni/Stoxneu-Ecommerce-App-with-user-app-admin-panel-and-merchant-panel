import '../model/address_model.dart';

abstract class AddressState {}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<AddressModel> addresses;
  final AddressModel? selected;

  AddressLoaded({
    required this.addresses,
    this.selected,
  });
}

class AddressError extends AddressState {
  final String message;
  AddressError(this.message);
}
