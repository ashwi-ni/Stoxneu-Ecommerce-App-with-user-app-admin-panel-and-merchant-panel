import '../model/cart_item_model.dart';
import '../service/cart_api_service.dart';

class CartRepository {
  final CartApiService api;

  CartRepository({required this.api});

  Future<List<CartItem>> fetchCart() async => await api.fetchCart();
  Future<void> addToCart(int productId, int quantity) async => await api.addToCart(productId, quantity);
  Future<void> increaseQuantity(int productId) async => await api.updateCartItem(productId, 1);
  Future<void> decreaseQuantity(int productId) async => await api.updateCartItem(productId, -1);
  Future<void> removeItem(int productId) async => await api.deleteFromCart(productId);
  Future<void> clearCart() async => await api.emptyCart();
}