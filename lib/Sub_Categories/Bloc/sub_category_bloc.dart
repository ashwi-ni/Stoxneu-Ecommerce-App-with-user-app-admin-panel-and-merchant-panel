import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/sub_category_repository.dart';
import 'sub_category_event.dart';
import 'sub_category_state.dart';

class SubCategoryBloc
    extends Bloc<SubCategoryEvent, SubCategoryState> {
  final SubCategoryRepository repository;

  SubCategoryBloc(this.repository) : super(SubCategoryLoading()) {
    on<LoadSubCategories>((event, emit) async {
      emit(SubCategoryLoading());
      try {
        final data =
        await repository.fetchSubCategories(event.categoryId);
        emit(SubCategoryLoaded(data));
      } catch (e) {
        emit(SubCategoryError(e.toString()));
      }
    });
  }
}