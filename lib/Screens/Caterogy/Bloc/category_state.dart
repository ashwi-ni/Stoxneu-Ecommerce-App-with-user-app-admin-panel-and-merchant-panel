import 'package:stoxneu/Screens/Caterogy/model/Category_model.dart';
import 'package:stoxneu/Sub_Categories/model/SubCategoryModel.dart';

abstract class CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final int? selectedCategoryId; // null = "All"
  final List<SubCategoryModel> subCategories; // ALL subcategories
  final List<SubCategoryModel> displayedSubCategories; // filtered

  CategoryLoaded({
    required this.categories,
    required this.selectedCategoryId,
    required this.subCategories,
    required this.displayedSubCategories,
  });

  CategoryLoaded copyWith({
    List<CategoryModel>? categories,
    int? selectedCategoryId,
    List<SubCategoryModel>? subCategories,
    List<SubCategoryModel>? displayedSubCategories,
  }) {
    return CategoryLoaded(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      subCategories: subCategories ?? this.subCategories,
      displayedSubCategories:
      displayedSubCategories ?? this.displayedSubCategories,
    );
  }
}
