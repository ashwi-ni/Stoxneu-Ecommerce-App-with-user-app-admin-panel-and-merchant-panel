import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:stoxneu/Screens/Caterogy/model/Category_model.dart';
import 'package:stoxneu/Sub_Categories/model/SubCategoryModel.dart';

import '../../../config/api_config.dart';
import 'CategoryEvent.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryLoading()) {
    on<LoadCategories>(_loadCategories);
    on<SelectCategory>(_selectCategory);
  }

  Future<void> _loadCategories(
      LoadCategories event, Emitter<CategoryState> emit) async {
    emit(CategoryLoading());

    try {
      // 1️⃣ Fetch categories
      final resCat =
      await http.get(Uri.parse('${ApiConfig.baseUrl}/categories'));

      if (resCat.statusCode != 200) {
        emit(CategoryError("Failed to load categories"));
        return;
      }

      final List categoriesJson = json.decode(resCat.body);
      final categories =
      categoriesJson.map((e) => CategoryModel.fromJson(e)).toList();

      if (categories.isEmpty) {
        emit(CategoryError("No categories found"));
        return;
      }

      // 2️⃣ Fetch ALL subcategories & inject categoryId manually
      List<SubCategoryModel> allSubCategories = [];

      for (var cat in categories) {

        final resSub = await http.get(
          Uri.parse(
              '${ApiConfig.baseUrl}/categories/${cat.id}/subcategories'),
        );

        if (resSub.statusCode == 200) {
          final List subJson = json.decode(resSub.body);

          allSubCategories.addAll(
            subJson
                .map((e) => SubCategoryModel.fromJson(e))
                .toList(),
          );
        }
      }
      // ✅✅ ADD THIS DEBUG CHECK RIGHT HERE
      for (var sub in allSubCategories) {
        print(
          'SubID=${sub.id}, '
              'categoryId(from API)=${sub.categoryId}',
        );
      }
      // ✅✅ END DEBUG CHECK

      // 3️⃣ Emit initial state ("All" selected)
      emit(CategoryLoaded(
        categories: categories,
        selectedCategoryId: null,
        subCategories: allSubCategories,
        displayedSubCategories: allSubCategories,
      ));
    } catch (e) {
      emit(CategoryError("Failed to load categories: $e"));
    }
  }

  void _selectCategory(
      SelectCategory event, Emitter<CategoryState> emit) {
    if (state is CategoryLoaded) {
      final current = state as CategoryLoaded;

      List<SubCategoryModel> filtered;

      if (event.categoryId == null) {
        // ✅ All
        filtered = current.subCategories;
      } else {
        // ✅ Filter by category
        filtered = current.subCategories
            .where((sub) => sub.categoryId == event.categoryId)
            .toList();
      }

      emit(current.copyWith(
        selectedCategoryId: event.categoryId,
        displayedSubCategories: filtered,
      ));
    }
  }
}
