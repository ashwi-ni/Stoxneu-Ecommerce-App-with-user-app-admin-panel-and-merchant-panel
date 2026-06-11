import 'package:equatable/equatable.dart';
import '../../Products/model/product_model.dart';

abstract class WishListEvent extends Equatable {
  const WishListEvent();
  @override
  List<Object?> get props => [];
}

class LoadWishList extends WishListEvent {}

class AddToWishList extends WishListEvent {
  final Product product;
  const AddToWishList(this.product);

  @override
  List<Object?> get props => [product];
}

class RemoveFromWishList extends WishListEvent {
  final Product product;
  const RemoveFromWishList(this.product);

  @override
  List<Object?> get props => [product];
}
