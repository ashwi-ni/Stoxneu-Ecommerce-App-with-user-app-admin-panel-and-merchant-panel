import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stoxneu/Screens/Products/product_api.dart';
import 'package:stoxneu/Screens/Favorite/bloc/fav_bloc.dart';
import 'package:stoxneu/Screens/Favorite/bloc/fav_event.dart';
import '../Favorite/bloc/fav_state.dart';
import 'ProductDetailsScreen.dart';
import 'Bloc/product_bloc.dart';
import 'Bloc/product_event.dart';
import 'Bloc/product_state.dart';
import '../../Widgets/common_appbar.dart';

class ProductListScreen extends StatelessWidget {
  final int subCategoryId;
  final String title;
  final ProductApi api;

  const ProductListScreen({
  super.key,
  required this.subCategoryId,
  required this.title,
  required this.api,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductBloc>(
      create: (_) => ProductBloc(api)..add(FetchProducts(subCategoryId:subCategoryId)),
      child: Scaffold(
        appBar: CommonAppBar(title: title),
        body: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductError) {
              return Center(child: Text(state.message));
            }

            if (state is ProductLoaded) {
              final products = state.products;
              final wishListBloc = context.read<WishListBloc>();

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];

                  // ✅ Check if product is in wishlist
                  final isFav = (wishListBloc.state is WishListLoaded) &&
                      (wishListBloc.state as WishListLoaded)
                          .items
                          .any((p) => p.id == product.id);

                  return Stack(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 IMAGE
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ProductDetailsScreen(product: product),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius:
                                  const BorderRadius.vertical(top: Radius.circular(8)),
                                  child:Image.network(
                                    product.fullImageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    headers: const {
                                      'ngrok-skip-browser-warning': 'true',
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                            // 🔹 NAME
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            // 🔹 DESCRIPTION (ONLY IF AVAILABLE)
                            if (product.description != null &&
                                product.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  product.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),

                            // 🔹 PRICE
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                "₹${product.price.toStringAsFixed(0)}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ❤️ WISHLIST ICON
                      Positioned(
                        top: 8,
                        right: 8,
                        child: BlocBuilder<WishListBloc, WishListState>(
                          builder: (context, favState) {
                            final isFav = favState is WishListLoaded &&
                                favState.items.any((p) => p.id == product.id);

                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                final bloc = context.read<WishListBloc>();
                                isFav
                                    ? bloc.add(RemoveFromWishList(product))
                                    : bloc.add(AddToWishList(product));
                              },
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                  },
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}