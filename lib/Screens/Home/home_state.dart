import 'package:equatable/equatable.dart';
import '../Caterogy/model/Category_model.dart';
import '../Products/model/BannerModel.dart';
import '../Products/model/product_model.dart';


abstract class HomeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<BannerModel> banners;
  final List<Product> featured;
  final List<CategoryModel> categories;
  final List<Product> flashDeals;


  HomeLoaded({required this.banners, required this.featured, required this.categories, required this.flashDeals, });

  @override
  List<Object?> get props => [banners, featured, categories,flashDeals];
}

class HomeError extends HomeState {
  final String message;
  HomeError({required this.message});

  @override
  List<Object?> get props => [message];
}
