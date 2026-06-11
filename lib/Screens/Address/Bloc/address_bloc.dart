import 'package:bloc/bloc.dart';
import '../AddressRepository/address_repository.dart';
import '../model/address_model.dart';
import 'address_event.dart';
import 'address_state.dart';



class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final AddressRepository repo;

  AddressBloc(this.repo) : super(AddressInitial()) {
    on<LoadAddresses>(_onLoad);
    on<AddAddress>(_onAdd);
    on<UpdateAddress>(_onUpdate);
    on<DeleteAddress>(_onDelete);
    on<SelectAddress>(_onSelect);
    add(LoadAddresses());
  }

  Future<void> _onLoad(LoadAddresses event, Emitter<AddressState> emit) async {
    emit(AddressLoading());
    try {
      final addresses = await repo.fetchAddresses();
      emit(AddressLoaded(
        addresses: addresses,
        selected: addresses.isNotEmpty
            ? addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first)
            : null,
      ));
    } catch (e) {
      emit(AddressError("Failed to load addresses: $e"));
    }
  }

  Future<void> _onAdd(AddAddress event, Emitter<AddressState> emit) async {
    final current = state is AddressLoaded
        ? state as AddressLoaded
        : AddressLoaded(addresses: [], selected: null);

    emit(AddressLoading());
    try {
      final newAddr = await repo.addAddress(event.address);
      final updatedList = [...current.addresses, newAddr];

      emit(AddressLoaded(
        addresses: updatedList,
        selected: newAddr,
      ));
    } catch (e) {
      emit(AddressError("Failed to add address: $e"));
    }
  }

  Future<void> _onUpdate(UpdateAddress event, Emitter<AddressState> emit) async {
    final current = state is AddressLoaded
        ? state as AddressLoaded
        : AddressLoaded(addresses: [], selected: null);

    try {
      final updatedAddr = await repo.updateAddress(event.address);
      final updatedList = current.addresses
          .map((a) => a.id == updatedAddr.id ? updatedAddr : a)
          .toList();

      emit(AddressLoaded(
        addresses: updatedList,
        selected: updatedAddr,
      ));
    } catch (e) {
      emit(AddressError("Failed to update address: $e"));
    }
  }

  Future<void> _onDelete(DeleteAddress event, Emitter<AddressState> emit) async {
    if (state is! AddressLoaded) return;

    final current = state as AddressLoaded;

    try {
      await repo.deleteAddress(event.addressId);

      final updatedList =
      current.addresses.where((a) => a.id != event.addressId).toList();

      AddressModel? updatedSelected = current.selected;
      if (updatedSelected?.id == event.addressId) {
        updatedSelected = updatedList.isNotEmpty ? updatedList.first : null;
      }

      emit(AddressLoaded(
        addresses: updatedList,
        selected: updatedSelected,
      ));
    } catch (e) {
      emit(AddressError("Failed to delete address: $e"));
    }
  }

  void _onSelect(SelectAddress event, Emitter<AddressState> emit) {
    if (state is AddressLoaded) {
      final current = state as AddressLoaded;
      emit(AddressLoaded(
        addresses: current.addresses,
        selected: event.address,
      ));
    }
  }
}
