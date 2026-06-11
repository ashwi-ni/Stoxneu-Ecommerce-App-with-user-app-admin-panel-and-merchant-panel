import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:provider/provider.dart';
import 'Screens/Address/AddressRepository/address_repository.dart';
import 'Screens/Address/AddressService/address_service.dart';
import 'Screens/Address/Bloc/address_bloc.dart';
import 'Screens/Auth/services/auth_service.dart';
import 'Screens/Auth/bloc/auth_bloc.dart';
import 'Screens/Auth/repository/auth_repository.dart';
import 'Screens/Cart/Bloc/cart_bloc.dart';
import 'Screens/Cart/Bloc/cart_event.dart';
import 'Screens/Cart/repository/cart_repository.dart';
import 'Screens/Cart/service/cart_api_service.dart';
import 'Screens/Caterogy/Bloc/category_bloc.dart';
import 'Screens/Caterogy/Bloc/CategoryEvent.dart';
import 'Screens/Favorite/bloc/fav_bloc.dart';
import 'Screens/Favorite/bloc/fav_event.dart';
import 'Screens/Favorite/service/wishlist_api_service.dart';
import 'Screens/MyOrder/API/OrderApi.dart';
import 'Screens/MyOrder/bloc/order_bloc.dart';
import 'Screens/MyOrder/bloc/order_event.dart';
import 'Screens/MyOrder/repository/order_repository.dart';
import 'Screens/Products/Bloc/product_bloc.dart';
import 'Screens/Products/product_api.dart';
import 'Widgets/SearchBar/bloc/search_bloc.dart';
import 'core/network/MyHttpOverrides.dart';
import 'core/router/app_router.dart';
import 'core/themes/app_themes.dart';
import 'features/dashboard/Admin_Panel/notifications/firebase_api.dart';
import 'features/dashboard/Merchant_Panel/ApiService/merchant_order_api_service.dart';
import 'features/dashboard/Merchant_Panel/screens/Merchant_Orders/bloc/MerchantOrderEvent.dart';
import 'features/dashboard/Merchant_Panel/screens/Merchant_Orders/bloc/merchantorder_bloc.dart';
import 'features/dashboard/Merchant_Panel/screens/Merchant_Orders/repository/MerchantOrderRepository.dart';
import 'features/dashboard/Merchant_Panel/screens/Merchant_Refund/BLOC/MerchantRefundBloc.dart';
import 'features/dashboard/Merchant_Panel/screens/Merchant_Refund/BLOC/MerchantRefundEvent.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Notifications via our new API class
  await FirebaseApi().initNotifications();

  HttpOverrides.global = MyHttpOverrides(); // ⚡ Add this before runApp

  final authRepository = AuthRepository(api: AuthApiService());
  await authRepository.autoLogin();

  runApp(MyApp(authRepository: authRepository));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {

    final wishlistApiService =
    WishListApiService(authRepository: authRepository);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authRepository),
        Provider<ProductApi>(create: (_) => ProductApi()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(context.read<AuthRepository>()),
          ),

          BlocProvider(
            create: (_) {
              final cartApiService =
              CartApiService(authRepository: authRepository);
              final cartRepository =
              CartRepository(api: cartApiService);

              return CartBloc(repository: cartRepository)
                ..add(LoadCartFromApi());
            },
          ),

          BlocProvider(
            create: (_) =>
            WishListBloc(api: wishlistApiService)
              ..add(LoadWishList()),
          ),

          BlocProvider(
            create: (_) =>
            CategoryBloc()..add(LoadCategories()),
          ),

          BlocProvider(
            create: (context) =>
                ProductBloc(context.read<ProductApi>()),
          ),

          BlocProvider(
            create: (_) {
              final service = AddressService();
              final repo = AddressRepository(service: service);
              return AddressBloc(repo);
            },
          ),

          BlocProvider(
            create: (_) => MerchantOrderBloc(
              MerchantOrderRepository(
                MerchantOrderApiService(authRepository: authRepository),
              ),
            )..add(LoadMerchantOrders()),
          ),


          BlocProvider(
            create: (_) => MerchantRefundBloc(
              MerchantOrderRepository(
                MerchantOrderApiService(authRepository: authRepository),
              ),
            )..add(LoadRefundRequests("pending")), // ✅ REQUIRED
          ),

          BlocProvider(
            create: (_) => OrderBloc(
              OrderRepository(
                OrderApiService(authRepository: authRepository),
              ),
            )..add(LoadOrders()),
          ),

          BlocProvider(
            create: (context) =>
                SearchBloc(context.read<ProductApi>()),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: AppRouter.createRouter(authRepository),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate, // Important for Quill v10
          ],
          supportedLocales: const [
            Locale('en', 'US'),
          ],
        ),
      ),
    );
  }
}