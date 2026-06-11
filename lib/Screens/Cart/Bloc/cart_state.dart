import 'package:equatable/equatable.dart';
import '../model/cart_item_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;

  CartLoaded({required this.items});

  double get totalPrice => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  @override
  List<Object?> get props => [items];

}


class CartError extends CartState {
  final String message;

  CartError(this.message);

  @override
  List<Object?> get props => [message];
}