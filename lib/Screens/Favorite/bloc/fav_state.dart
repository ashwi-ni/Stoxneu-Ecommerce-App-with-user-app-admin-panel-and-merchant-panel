import 'package:equatable/equatable.dart';
import '../../Products/model/product_model.dart';

abstract class WishListState extends Equatable {
  const WishListState();

  @override
  List<Object?> get props => [];
}

class WishListLoading extends WishListState {}

class WishListError extends WishListState {
  final String message;
  const WishListError({required this.message});

  @override
  List<Object?> get props => [message];
}

class WishListLoaded extends WishListState {
  final List<Product> items;
  const WishListLoaded({this.items = const []});

  @override
  List<Object?> get props => [items];
}