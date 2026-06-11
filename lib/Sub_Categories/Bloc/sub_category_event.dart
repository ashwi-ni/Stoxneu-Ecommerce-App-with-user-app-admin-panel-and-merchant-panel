abstract class SubCategoryEvent {}

class LoadSubCategories extends SubCategoryEvent {
  final int categoryId;

  LoadSubCategories(this.categoryId);
}