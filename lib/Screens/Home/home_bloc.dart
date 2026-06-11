import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_event.dart';
import 'home_state.dart';

import '../Products/product_api.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProductApi api;

  HomeBloc(this.api) : super(HomeLoading()) {
    on<LoadHomeData>(_loadHomeData);
  }

  Future<void> _loadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());

    try {
      // Fetch products from backend
      final banners = await api.fetchBanners();
      final featuredProducts = await api.fetchFeaturedProducts(); // create this API call in ProductApi
      final flashDeals = await api.fetchFlashDeals(); // ✅ new API in ProductApi
      print('Flash Deals fetched: ${flashDeals.length}');



      // Fetch categories from CategoryBloc API
      final categories = await api.fetchCategories(); // create API call in ProductApi for categories

      emit(HomeLoaded(
        banners: banners,
        featured: featuredProducts,
        categories: categories,
        flashDeals: flashDeals,
      ));
    } catch (e) {
      emit(HomeError(message: e.toString()));
    }
  }
}
