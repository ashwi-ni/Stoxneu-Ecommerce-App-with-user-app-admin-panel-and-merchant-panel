import 'package:equatable/equatable.dart';
import '../model/cart_item_model.dart';
import '../../Products/model/product_model.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

// Load cart from API
class LoadCartFromApi extends CartEvent {}

// Add product to cart
class AddToCart extends CartEvent {
  final Product product;
  final int quantity;

  const AddToCart(this.product, {this.quantity = 1});

  @override
  List<Object?> get props => [product, quantity];
}

// Increase quantity of a CartItem
class IncreaseQuantity extends CartEvent {
  final CartItem item;

  const IncreaseQuantity(this.item);

  @override
  List<Object?> get props => [item];
}

// Decrease quantity of a CartItem
class DecreaseQuantity extends CartEvent {
  final CartItem item;

  const DecreaseQuantity(this.item);

  @override
  List<Object?> get props => [item];
}

// Remove CartItem
class RemoveFromCart extends CartEvent {
  final CartItem item;

  const RemoveFromCart(this.item);

  @override
  List<Object?> get props => [item];
}

// Clear the entire cart
class ClearCart extends CartEvent {}

class BuyNowItemEvent extends CartEvent {
  final Product product;
  final int quantity;

  BuyNowItemEvent({required this.product, this.quantity = 1});
}