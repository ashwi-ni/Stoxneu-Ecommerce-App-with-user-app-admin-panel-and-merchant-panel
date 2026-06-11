import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import '../../Sub_Categories/SubCategoryScreen.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';

import '../Cart/Bloc/cart_bloc.dart';
import '../Cart/Bloc/cart_state.dart';
import '../Cart/CartScreen.dart';
import '../Caterogy/Bloc/CategoryEvent.dart';
import '../Caterogy/Bloc/category_bloc.dart';
import '../Caterogy/Bloc/category_state.dart';
import '../Favorite/bloc/fav_bloc.dart';
import '../Favorite/bloc/fav_state.dart';
import '../Favorite/favorite_screen.dart';
import '../Products/ProductDetailsScreen.dart';
import '../Products/model/BannerModel.dart';
import '../Products/model/product_model.dart';
import '../Products/product_api.dart';
import '../notifications/screens/user_notification_screen.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  int unreadCount = 0;
  bool _popupShown = false;

  @override

  @override
  void initState() {
    super.initState();

    fetchUnreadCount();
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  void _showPopupBanner(List<BannerModel> popupBanners) {
    if (popupBanners.isEmpty || !mounted) return;

    final banner = popupBanners.first;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Image.network(banner.fullImageUrl),
      ),
    );
  }


  Future<void> fetchUnreadCount() async {

    try {

      final response = await ApiClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/user/notifications/unread-count',
        ),
      );

      final data = jsonDecode(response.body);

      setState(() {
        unreadCount = data['count'] ?? 0;
      });

      print("BADGE COUNT => $unreadCount");

    } catch (e) {

      print(e);
    }
  }

  void _handleBannerTap(BuildContext context, String link) {
    final uri = Uri.parse(link);

    // PRODUCT DETAILS
    if (link.contains("/product-details")) {
      final productId = uri.queryParameters['id'];

      if (productId != null) {

        final homeState = context.read<HomeBloc>().state;

        if (homeState is HomeLoaded) {

          final allProducts = [
            ...homeState.featured,
            ...homeState.flashDeals,
          ];

          final product = allProducts.firstWhere(
                (p) => p.id == int.parse(productId),
            orElse: () => allProducts.first,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        }
      }
    }

    // CATEGORY PRODUCTS
    else if (link.contains("/products")) {
      final subCategoryId = uri.queryParameters['subCategoryId'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SubCategoryScreen(
            categoryId: int.parse(subCategoryId ?? "0"),
            categoryName: "Products",
          ),
        ),
      );
    }
  }
  Widget _buildSearchBar() {
    return Container(
      color: Colors.black, // black AppBar background
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              searchQuery = value.toLowerCase();
            });
          },
          decoration: const InputDecoration(
            hintText: 'Search products...',
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return BlocProvider(
      create: (_) => HomeBloc(ProductApi())..add(LoadHomeData()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                child: Image.asset(
                  'assets/images/brandlogo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            BlocBuilder<WishListBloc, WishListState>(
              builder: (context, state) {
                return IconButton(
                  icon: const Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WishListScreen()),
                    );
                  },
                );
              },
            ),
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                int count = 0;
                if (state is CartLoaded) count = state.items.length;
                print("UNREAD COUNT => $unreadCount");
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CartScreen()),
                        );
                      },
                    ),
                    if (count > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            count.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            SizedBox(
              width: 40,

              child: Stack(

                clipBehavior: Clip.none,

                children: [

                  IconButton(
                    icon: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                    ),

                    onPressed: () async {

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const UserNotificationScreen(),
                        ),
                      );

                      fetchUnreadCount();
                    },
                  ),

                  if (unreadCount > 0)

                    Positioned(

                      right: 2,
                      top: 2,

                      child: Container(

                        padding: const EdgeInsets.all(4),

                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),

                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),

                        child: Text(

                          unreadCount > 9
                              ? "9+"
                              : unreadCount.toString(),

                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),

                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            )
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<HomeBloc>().add(LoadHomeData());
                },
                child: BlocBuilder<HomeBloc, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) return const HomeShimmer();
                    if (state is HomeError) return Center(child: Text(state.message));

                    if (state is HomeLoaded) {
                      final allProducts = [...state.featured, ...state.flashDeals];
                      final filteredProducts = allProducts
                          .where((p) => p.name.toLowerCase().contains(searchQuery))
                          .toList();

                      if (searchQuery.isNotEmpty) {
                        if (filteredProducts.isEmpty) {
                          return const Center(child: Text("No products found"));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            return _buildProductTile(filteredProducts[index]);
                          },
                        );
                      }
                      final publishedBanners = state.banners
                          .where((b) => b.isPublished == true)
                          .toList();

                      final mainBanners = publishedBanners
                          .where((b) => b.type == "Main Section Banner")
                          .toList();

                      final popupBanners = publishedBanners
                          .where((b) => b.type == "Popup Banner")
                          .toList();

                      final footerBanners = publishedBanners
                          .where((b) => b.type == "Footer Banner")
                          .toList();

                      if (!_popupShown && popupBanners.isNotEmpty) {
                        _popupShown = true;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Future.delayed(
                            const Duration(seconds: 2),
                                () {
                              if (mounted) {
                                _showPopupBanner(popupBanners);
                              }
                            },
                          );
                        });
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Banners


                      CarouselSlider(
                        items: mainBanners.map((b) {
                          return GestureDetector(
                            onTap: () {
                              _handleBannerTap(context, b.link);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                b.fullImageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                        options: CarouselOptions(
                          height: 180,
                          autoPlay: true,
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                        ),
                      ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: const Text(
                                'Categories',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: BlocBuilder<CategoryBloc, CategoryState>(
                                builder: (context, catState) {

                                  if (catState is CategoryLoaded) {

                                    final visibleCategories = catState.categories
                                        .where((c) => c.homeStatus)
                                        .toList();

                                    if (visibleCategories.isEmpty) {
                                      return const Center(
                                        child: Text("No categories available"),
                                      );
                                    }
                                    print(visibleCategories.length);
                                    print(catState.categories.map((e) => e.homeStatus).toList());
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: visibleCategories.length,
                                      itemBuilder: (_, index) {

                                        final cat = visibleCategories[index];

                                        final isSelected =
                                            cat.id == catState.selectedCategoryId;

                                        return InkWell(
                                          onTap: () {

                                            context
                                                .read<CategoryBloc>()
                                                .add(SelectCategory(cat.id));

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => SubCategoryScreen(
                                                  categoryId: cat.id,
                                                  categoryName: cat.name,
                                                ),
                                              ),
                                            );
                                          },

                                          child: Container(
                                            width: 80,
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            padding: const EdgeInsets.all(8),

                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.yellow
                                                  : Colors.grey.shade100,

                                              borderRadius: BorderRadius.circular(10),
                                            ),

                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [

                                                CircleAvatar(
                                                  radius: 24,
                                                  backgroundImage:
                                                  NetworkImage(cat.iconUrl),
                                                ),

                                                const SizedBox(height: 6),

                                                Text(
                                                  cat.name,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Flash Deals
                            if (state.flashDeals.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Text(
                                  'Flash Deals',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (state.flashDeals.isNotEmpty)
                              Container(
                                color: Colors.grey.withOpacity(0.2),
                                child: SizedBox(
                                  height:190,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: state.flashDeals.length,
                                    itemBuilder: (_, i) => _buildProductCard(state.flashDeals[i]),
                                  ),
                                ),
                              ),
                           const SizedBox(height: 10),
                            if (footerBanners.isNotEmpty)
                              Column(
                                children: footerBanners.map((b) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: GestureDetector(
                                      onTap: () => _handleBannerTap(context, b.link),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          b.fullImageUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                            const SizedBox(height: 15),
                            // Featured
                            if (state.featured.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: const Text(
                                  'Featured Products',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            if (state.featured.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: state.featured.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2, // 2 products per row
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                    childAspectRatio: 1,
                                  ),
                                  itemBuilder: (_, i) {
                                    return _buildProductCard(state.featured[i]);
                                  },
                                ),
                              ),
                            const SizedBox(height: 10),

                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailsScreen(product: product),
            ),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.fullImageUrl,
            width: 60,
            height: 60,
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
        title: Text(product.name),
        subtitle: Text(
          '₹${product.currentPrice.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailsScreen(product: product)),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.fullImageUrl,
                width: 120,
                height: 120,
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
            const SizedBox(height: 5),
            SizedBox(
              width: 120,
              child: Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Text(
              '₹${product.currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}



class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // 🔹 Banner shimmer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 Section title shimmer
          _titleShimmer(),

          // 🔹 Horizontal product shimmer
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => _productCardShimmer(),
            ),
          ),

          const SizedBox(height: 10),

          _titleShimmer(),

          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (_, __) => _productCardShimmer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 20,
          width: 150,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _productCardShimmer() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          children: [
            Container(
              height: 120,
              width: 120,
              color: Colors.grey.shade800,
            ),
            const SizedBox(height: 8),
            Container(height: 12, width: 100, color: Colors.grey.shade800),
            const SizedBox(height: 6),
            Container(height: 12, width: 60, color: Colors.grey.shade800),
          ],
        ),
      ),
    );
  }
}