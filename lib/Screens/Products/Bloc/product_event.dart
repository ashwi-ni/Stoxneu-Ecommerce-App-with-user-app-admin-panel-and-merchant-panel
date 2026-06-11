import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Fetch products with optional subCategoryId
class FetchProducts extends ProductEvent {
  final int? subCategoryId; // optional
  FetchProducts({this.subCategoryId});


  @override
  List<Object?> get props => [subCategoryId];
}

// Search products
class SearchProducts extends ProductEvent {
  final String query;
  SearchProducts(this.query);

  @override
  List<Object?> get props => [query];
}