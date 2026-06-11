import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../repository/cart_repository.dart';
import '../model/cart_item_model.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository repository;

  CartBloc({required this.repository}) : super(CartInitial()) {
    on<LoadCartFromApi>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<IncreaseQuantity>(_onIncreaseQuantity);
    on<DecreaseQuantity>(_onDecreaseQuantity);
    on<RemoveFromCart>(_onRemoveItem);
    on<ClearCart>(_onClearCart);
    on<BuyNowItemEvent>(_onBuyNowItem);
  }

  Future<void> _onLoadCart(LoadCartFromApi event, Emitter<CartState> emit) async {
    emit(CartLoading());
    try {
      final items = await repository.fetchCart();
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    try {
      await repository.addToCart(event.product.id, event.quantity);
      add(LoadCartFromApi());
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onIncreaseQuantity(IncreaseQuantity event, Emitter<CartState> emit) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;
    final updatedItems = current.items.map((item) {
      if (item.product.id == event.item.product.id) return item.copyWith(quantity: item.quantity + 1);
      return item;
    }).toList();

    emit(CartLoaded(items: updatedItems));
    try {
      await repository.increaseQuantity(event.item.product.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onDecreaseQuantity(DecreaseQuantity event, Emitter<CartState> emit) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;
    final updatedItems = current.items.map((item) {
      if (item.product.id == event.item.product.id && item.quantity > 1) return item.copyWith(quantity: item.quantity - 1);
      return item;
    }).toList();

    emit(CartLoaded(items: updatedItems));
    try {
      await repository.decreaseQuantity(event.item.product.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onRemoveItem(RemoveFromCart event, Emitter<CartState> emit) async {
    if (state is! CartLoaded) return;
    final current = state as CartLoaded;
    final updatedItems = current.items.where((item) => item.product.id != event.item.product.id).toList();

    emit(CartLoaded(items: updatedItems));
    try {
      await repository.removeItem(event.item.product.id);
    } catch (_) {
      emit(current);
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    try {
      await repository.clearCart();
      emit(CartLoaded(items: []));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> _onBuyNowItem(BuyNowItemEvent event, Emitter<CartState> emit) async {
    emit(CartLoaded(items: [CartItem(product: event.product, quantity: event.quantity)]));
  }
}