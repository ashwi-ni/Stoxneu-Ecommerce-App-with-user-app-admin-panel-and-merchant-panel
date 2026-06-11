import 'package:flutter_bloc/flutter_bloc.dart';
import '../../Products/model/product_model.dart';
import 'fav_event.dart';
import 'fav_state.dart';
import '../service/wishlist_api_service.dart';

class WishListBloc extends Bloc<WishListEvent, WishListState> {
  final WishListApiService api;

  WishListBloc({required this.api}) : super(const WishListLoaded(items: [])) {
    on<LoadWishList>(_onLoadWishList);
    on<AddToWishList>(_onAddToWishList);
    on<RemoveFromWishList>(_onRemoveFromWishList);
  }

  Future<void> _onLoadWishList(
      LoadWishList event, Emitter<WishListState> emit) async {
    emit(WishListLoading());
    try {
      final products = await api.fetchWishlist();
      emit(WishListLoaded(items: products));
    } catch (e) {
      emit(WishListError(message: e.toString()));
    }
  }

  Future<void> _onAddToWishList(
      AddToWishList event, Emitter<WishListState> emit) async {
    final current = (state as WishListLoaded).items;

    if (current.any((p) => p.id == event.product.id)) return;

    // Optimistic UI update
    emit(WishListLoaded(items: [...current, event.product]));

    // API call
    try {
      await api.addToWishlist(event.product);
    } catch (e) {
      // If API fails, rollback
      emit(WishListLoaded(items: current));
    }
  }

  Future<void> _onRemoveFromWishList(
      RemoveFromWishList event, Emitter<WishListState> emit) async {
    final current = (state as WishListLoaded).items;

    emit(WishListLoaded(
      items: current.where((p) => p.id != event.product.id).toList(),
    ));

    try {
      await api.removeFromWishlist(event.product.id);
    } catch (e) {
      // Rollback
      emit(WishListLoaded(items: current));
    }
  }
}