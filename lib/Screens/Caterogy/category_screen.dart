import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../Widgets/common_appbar.dart';
import '../Products/product_api.dart';
import '../Products/product_list_screen.dart';
import 'Bloc/CategoryEvent.dart';
import 'Bloc/category_bloc.dart';
import 'Bloc/category_state.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(title: "Categories",
      //  showBack:true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<CategoryBloc>().add(LoadCategories());
        },
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is CategoryLoading) {
              return const CategoryShimmer();
            }

            if (state is CategoryError) {
              return Center(child: Text(state.message));
            }

            if (state is CategoryLoaded) {
              return Row(
                children: [
                  // Left Categories
                  Container(
                    width: 100,
                    color: Colors.grey.shade100,
                    child: ListView.builder(
                      itemCount: state.categories.length + 1, // +1 for "All"
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // "All" category
                          final isSelected = state.selectedCategoryId == null;

                          return InkWell(
                            onTap: () {
                              context
                                  .read<CategoryBloc>()
                                  .add(SelectCategory(null));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              color: isSelected ? Colors.white : Colors.grey.shade100,
                              child: Column(
                                children: [
                                  const CircleAvatar(
                                    radius: 28,
                                    child: Icon(Icons.grid_view, size: 28),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "All",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (isSelected)
                                    Container(
                                      height: 2,
                                      width: 30,
                                      color: Colors.pink,
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        final cat = state.categories[index - 1];
                        final isSelected = cat.id == state.selectedCategoryId;

                        return InkWell(
                          onTap: () {
                            context
                                .read<CategoryBloc>()
                                .add(SelectCategory(cat.id));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            color: isSelected ? Colors.white : Colors.grey.shade100,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: cat.iconUrl.isNotEmpty
                                      ? NetworkImage(cat.iconUrl)
                                      : const AssetImage(
                                      'assets/images/placeholder.png')
                                  as ImageProvider,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (isSelected)
                                  Container(
                                    height: 2,
                                    width: 30,
                                    color: Colors.pink,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Right Subcategories
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.displayedSubCategories.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            final sub = state.displayedSubCategories[index];

                            return InkWell(
                              onTap: () {
                                      Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductListScreen(
                                      subCategoryId: sub.id,
                                      title: sub.name,
                                      api: ProductApi(),


                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: sub.iconUrl.isNotEmpty
                                        ? NetworkImage(sub.iconUrl)
                                        : const AssetImage('assets/images/placeholder.png')
                                    as ImageProvider,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    sub.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          },
                        )

                      ],
                    ),
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}


class CategoryShimmer extends StatelessWidget {
  const CategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // LEFT SHIMMER (categories)
        Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          child: ListView.builder(
            itemCount: 6,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 60,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // RIGHT SHIMMER (subcategories)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: 9,
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (_, __) {
              return Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 50,
                      color: Colors.white,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
