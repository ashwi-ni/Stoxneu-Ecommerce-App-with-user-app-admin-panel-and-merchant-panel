import '../model/SubCategoryModel.dart';

abstract class SubCategoryState {}

class SubCategoryLoading extends SubCategoryState {}

class SubCategoryLoaded extends SubCategoryState {
  final List<SubCategoryModel> subCategories;

  SubCategoryLoaded(this.subCategories);
}

class SubCategoryError extends SubCategoryState {
  final String message;

  SubCategoryError(this.message);
}