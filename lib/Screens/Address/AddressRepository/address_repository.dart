import '../AddressService/address_service.dart';
import '../model/address_model.dart';

class AddressRepository {
  final AddressService service;

  AddressRepository({required this.service});

  Future<List<AddressModel>> fetchAddresses() async {
    return await service.fetchAddresses();
  }

  Future<AddressModel> addAddress(AddressModel address) async {
    return await service.addAddress(address);
  }

  Future<AddressModel> updateAddress(AddressModel address) async {
    return await service.updateAddress(address);
  }
  Future<void> deleteAddress(int id) async {
    return await service.deleteAddress(id);
  }

}
