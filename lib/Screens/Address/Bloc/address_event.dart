import '../model/address_model.dart';

abstract class AddressEvent {}

class LoadAddresses extends AddressEvent {

  LoadAddresses();
}

class AddAddress extends AddressEvent {
  final AddressModel address;
  AddAddress(this.address);
}

class UpdateAddress extends AddressEvent {
  final AddressModel address;
  UpdateAddress(this.address);
}

class SelectAddress extends AddressEvent {
  final AddressModel address;
  SelectAddress(this.address);
}
class DeleteAddress extends AddressEvent {
  final int addressId;
  DeleteAddress(this.addressId);
}
