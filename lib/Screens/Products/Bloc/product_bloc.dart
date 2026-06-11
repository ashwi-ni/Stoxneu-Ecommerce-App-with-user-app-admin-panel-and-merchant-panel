import 'package:flutter_bloc/flutter_bloc.dart';
import '../product_api.dart';
import 'product_event.dart';
import 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductApi api;

  ProductBloc(this.api) : super(ProductInitial()) {
    on<FetchProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        // Pass subCategoryId if provided, otherwise fetch all
        final products = await api.fetchProducts(subCategoryId: event.subCategoryId);
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });

    // Search products
    on<SearchProducts>((event, emit) async {
      emit(ProductLoading());
      try {
        final products = await api.searchProducts(event.query);
        emit(ProductLoaded(products));
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    });
  }
}