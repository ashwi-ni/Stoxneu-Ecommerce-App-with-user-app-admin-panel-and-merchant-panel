import 'package:stoxneu/Screens/Products/model/product_model.dart';

abstract class SearchState {}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Product> products;
  SearchLoaded(this.products);
}

class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}
