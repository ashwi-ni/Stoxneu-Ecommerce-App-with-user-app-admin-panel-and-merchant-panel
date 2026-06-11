abstract class CategoryEvent {}

class LoadCategories extends CategoryEvent {}

class SelectCategory extends CategoryEvent {
  final int? categoryId;
  SelectCategory(this.categoryId);
}
