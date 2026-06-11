import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stoxneu/Sub_Categories/repository/sub_category_repository.dart';
import '../../../Widgets/common_appbar.dart';
import '../Screens/Products/product_api.dart';
import '../Screens/Products/product_list_screen.dart';
import 'Bloc/sub_category_bloc.dart';
import 'Bloc/sub_category_event.dart';
import 'Bloc/sub_category_state.dart';


class SubCategoryScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;

  const SubCategoryScreen({
  super.key,
  required this.categoryId,
  required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SubCategoryBloc(SubCategoryRepository())
        ..add(LoadSubCategories(categoryId)),
      child: Scaffold(
        appBar: CommonAppBar(
          title: categoryName,
          showBack: true,
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context
                .read<SubCategoryBloc>()
                .add(LoadSubCategories(categoryId));
          },
          child: BlocBuilder<SubCategoryBloc, SubCategoryState>(
            builder: (context, state) {
              if (state is SubCategoryLoading) {
                return const SubCategoryShimmer();
              }
          
              if (state is SubCategoryError) {
                return Center(child: Text(state.message));
              }
          
              if (state is SubCategoryLoaded) {
                if (state.subCategories.isEmpty) {
                  return const Center(child: Text('No subcategories'));
                }
          
                return ListView.builder(
                  itemCount: state.subCategories.length,
                  itemBuilder: (context, index) {
                    final sub = state.subCategories[index];
          
                    return ListTile(
                      title: Text(sub.name),
                      trailing: const Icon(Icons.arrow_forward_ios),
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
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

class SubCategoryShimmer extends StatelessWidget {
  const SubCategoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Row(
            children: [
              Container(
                height: 20,
                width: 150,
                color: Colors.white,
              ),
              const Spacer(),
              Container(
                height: 20,
                width: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}