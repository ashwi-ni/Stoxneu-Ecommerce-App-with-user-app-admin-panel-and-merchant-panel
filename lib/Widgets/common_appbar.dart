import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Screens/Cart/Bloc/cart_bloc.dart';
import '../Screens/Cart/Bloc/cart_state.dart';
import '../Screens/Cart/CartScreen.dart';
import '../Screens/Favorite/bloc/fav_bloc.dart';
import '../Screens/Favorite/bloc/fav_state.dart';
import '../Screens/Favorite/favorite_screen.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;

  const CommonAppBar({
  super.key,
  required this.title,
  this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 1,
      title: Text(title),
      leading: showBack
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      )
          : null,
      actions: [
        /// ❤️ Wishlist
        BlocBuilder<WishListBloc, WishListState>(
          builder: (context, state) {
            if (state is WishListLoaded) {
            }

            return IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WishListScreen()),
                );
              },
            );
          },
        ),

        /// 🛒 Cart
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            int count = 0;
            if (state is CartLoaded) count = state.items.length;

            return Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}