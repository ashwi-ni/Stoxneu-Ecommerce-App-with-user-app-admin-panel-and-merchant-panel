import 'package:bloc/bloc.dart';
import 'package:stoxneu/Widgets/SearchBar/bloc/search_event.dart';
import 'package:stoxneu/Widgets/SearchBar/bloc/search_state.dart';

import '../../../Screens/Products/product_api.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ProductApi api;

  SearchBloc(this.api) : super(SearchInitial()) {
    on<SearchProducts>(_onSearch);
    on<ClearSearch>((event, emit) {
      emit(SearchInitial()); // 👈 GO BACK TO HOME
    });
  }

  Future<void> _onSearch(
      SearchProducts event,
      Emitter<SearchState> emit,
      ) async {
    emit(SearchLoading());
    try {
      final products = await api.searchProducts(event.query);
      emit(SearchLoaded(products));
    } catch (e) {
      emit(SearchError("Search failed"));
    }
  }
}
