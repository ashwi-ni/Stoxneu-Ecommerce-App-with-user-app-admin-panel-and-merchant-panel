import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stoxneu/features/dashboard/Admin_Panel/refund_request/Admin_Refund_Request_Screen.dart';

import '../../Screens/Auth/repository/auth_repository.dart';
import '../../Screens/Auth/ui/forgotpassword_screen/forgotpassword.dart';
import '../../Screens/Auth/ui/login/LoginScreen.dart';
import '../../Screens/Auth/ui/signup_screen/RegisterScreen.dart';
import '../../Screens/BottomNav_Screen/mainscreen.dart';
import '../../Screens/Products/model/product_model.dart';
import '../../Screens/Splash_screen/splashscreen.dart';
import '../../Screens/onBoarding/onboard_screen.dart';

import '../../features/dashboard/Admin_Panel/cms/Static Pages/Admin_Static_Pages_Screen.dart';
import '../../features/dashboard/Admin_Panel/cms/banner setup/Banner_Management_Screen.dart';
import '../../features/dashboard/Admin_Panel/dashboard/admin_dashboard.dart';
import '../../features/dashboard/Admin_Panel/layout/admin_shell.dart';
import '../../features/dashboard/Admin_Panel/finance/Admin_Payout_Approval_Screen.dart';
import '../../features/dashboard/Admin_Panel/merchants/merchant_KycList_Screen.dart';
import '../../features/dashboard/Admin_Panel/finance/merchant_commission_screen.dart';
import '../../features/dashboard/Admin_Panel/notifications/Admin_Notification_Screen.dart';
import '../../features/dashboard/Admin_Panel/orders/admin_order_screen.dart';
import '../../features/dashboard/Admin_Panel/products/Admin_Category_Screen.dart';
import '../../features/dashboard/Admin_Panel/products/Admin_Product_Approval_Screen.dart';
import '../../features/dashboard/Admin_Panel/products/Admin_SubCategory_Screen.dart';
import '../../features/dashboard/Admin_Panel/profile/Admin_Profile_Screen.dart';
import '../../features/dashboard/Admin_Panel/reports/Admin_Commission_Report.dart';
import '../../features/dashboard/Admin_Panel/reports/Admin_Tax_Report.dart';
import '../../features/dashboard/Admin_Panel/reports/Sales_Report_Screen.dart';
import '../../features/dashboard/Admin_Panel/users/user_management.dart';
import '../../features/dashboard/Merchant_Panel/screens/MerchantProducts/MerchantProduct_detailScreen.dart';
import '../../features/dashboard/Merchant_Panel/screens/MerchantProducts/Merchantproduct_list_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/MerchantProducts/add_product_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/MerchantProducts/edit_product_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Coupons/merchant_coupon_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Onboarding/kyc_pending_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Onboarding/kyc_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Onboarding/shop_setup_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Orders/order_management_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Payment/payment_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Profile/merchant_profile_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Refund/merchant_refund_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Sale/merchant_sale_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_ShopSetting/shop_settings_screen.dart';
import '../../features/dashboard/Merchant_Panel/screens/Merchant_Subscription/SubscriptionScreen.dart';
import '../../features/dashboard/Merchant_Panel/screens/merchant_dashboard.dart';
import '../../features/dashboard/Merchant_Panel/widgets/merchant_layout.dart';
import '../constants/user_role.dart';

// Helper Wrapper for Merchant Routes
class MerchantRouteWrapper extends StatelessWidget {
  final Widget child;
  final String token;
  const MerchantRouteWrapper({super.key, required this.child, required this.token});

  @override
  Widget build(BuildContext context) => child;
}

class AppRouter {
  static GoRouter createRouter(AuthRepository authRepository) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authRepository,
      redirect: (context, state) {
        final loggedIn = authRepository.isLoggedIn;
        final role = authRepository.currentRole;
        final location = state.matchedLocation;
        print("------------------------------------------------------------");
        print("ROUTER RUNNING -> Path: ${state.matchedLocation}");
        print("SHOP: ${authRepository.hasShop} | KYC: ${authRepository.kycStatus} | SUB: ${authRepository.subscriptionStatus}");
        print("------------------------------------------------------------");

        // 1. Handle Unauthenticated Users
        if (!loggedIn) {
          if (location == '/login' || location == '/register' || location == '/forgot-password') {
            return null;
          }
          return '/login';
        }

        // 2. Handle Merchant Flow
        if (role == UserRole.merchant) {
          // Wait for auth data to load fully
          if (authRepository.currentRole == UserRole.merchant) {
            // Wait for auth data to load fully
            if (authRepository.hasShop == null || authRepository.kycStatus == null) {
              return null; // Show core loading layout
            }

            // 1. SHOP CHECK
            if (authRepository.hasShop == false && location != '/shop-setup') {
              return '/shop-setup';
            }

            // 2. KYC FLOW
            if (authRepository.kycStatus == 'not_submitted' && location != '/kyc') {
              return '/kyc';
            }
            if (authRepository.kycStatus == 'pending' && location != '/kyc-pending') {
              return '/kyc-pending';
            }
            if (authRepository.kycStatus == 'rejected' && location != '/kyc') {
              return '/kyc';
            }

            // 3. SUBSCRIPTION FLOW (Only checked if KYC is approved)
            if (authRepository.kycStatus == 'approved') {
              final sub = authRepository.subscriptionStatus;

              // 🧠 SAFETY BYPASS: If sub is active, trial, OR the user is navigating anywhere
              // inside the merchant application space (paths starting with /merchant-), let them stay!
              if (sub == 'active' || sub == 'trial' || location.startsWith('/merchant-')) {
                if (location == '/' ||
                    location == '/login' ||
                    location == '/shop-setup' ||
                    location == '/kyc' ||
                    location == '/kyc-pending' ||
                    location == '/subscription') {
                  return '/merchant-dashboard';
                }
                return null; // Allow them to remain on their clicked sub-page safely
              }

              // Force subscription page only if they are clearly un-subscribed and outside merchant paths
              if (sub == 'none' || sub == 'expired' || sub == null) {
                if (location != '/subscription') {
                  return '/subscription';
                }
                return null;
              }
            }
          }
        }

        // 3. Handle Regular User Flow
        if (role == UserRole.user && (location == '/' || location == '/login')) {
          return '/main';
        }

        // 4. Handle Admin Flow
        if (role == UserRole.admin && (location == '/' || location == '/login')) {
          return '/admin-dashboard';
        }

        return null;
      },
      routes: <RouteBase>[
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnBoardScreen()),
        GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
        GoRoute(path: '/main', builder: (_, __) => MainScreen()),

        GoRoute(
          path: '/merchant-editproduct', // 👈 This must match the context.push string
          builder: (context, state) {
            final product = state.extra as Product;
            return EditProductScreen(token: authRepository.token ?? '', product: product);
          },
        ),

        // ---------------- MERCHANT PANEL (Shell) ----------------
        ShellRoute(
          builder: (context, state, child) {
            final token = authRepository.token ?? '';
            return MerchantLayout(
              child: MerchantRouteWrapper(child: child, token: token),
            );
          },
          routes: [
            GoRoute(path: '/merchant-dashboard', builder: (_, __) => MerchantDashboardScreen()),
            GoRoute(path: '/merchant-products', builder: (_, __) => const MerchantProductsScreen()),
            GoRoute(path: '/add-product', builder: (_, __) => AddProductScreen(token: authRepository.token ?? '')),
            GoRoute(path: '/merchant-orders', builder: (_, __) => const MerchantOrderListScreen()),
            GoRoute(path: '/merchant-refunds', builder: (_, __) => const MerchantRefundScreen()),
            GoRoute(path: '/merchant-coupons', builder: (_, __) => const MerchantCouponScreen()),
            GoRoute(path: '/merchant-profile', builder: (_, __) => MerchantProfileScreen()),
            GoRoute(path: '/merchant-payments', builder: (_, __) => MerchantPaymentScreen()),
            GoRoute(path: '/merchant-shop', builder: (_, __) => ShopSettingsScreen()),
            GoRoute(
              path: '/merchant-sale/:type',
              builder: (context, state) {
                final typeParam = state.pathParameters['type'];
                final String displayTitle = typeParam == 'flash' ? 'Flash Deal' : 'Clearance Sale';
                return MerchantSaleScreen(saleType: displayTitle);
              },
            ),


            GoRoute(
              path: '/merchant-productdetail',
              builder: (context, state) {
                final product = state.extra as Product;
                return MerchantProductDetailScreen(product: product);
              },
            ),
          ],
        ),

        // Merchant Onboarding (Outside Shell)
        GoRoute(path: '/shop-setup', builder: (_, __) => const ShopSetupScreen()),
        GoRoute(path: '/kyc', builder: (_, __) => const KycScreen()),
        GoRoute(path: '/kyc-pending', builder: (_, __) => const KycPendingScreen()),
        GoRoute(path: '/subscription', builder: (_, __) => const SubscriptionScreen()),
        // ---------------- ADMIN PANEL (Shell) ----------------
        ShellRoute(
          builder: (context, state, child) {
            return AdminShell(child: child);
          },
          routes: [
            GoRoute(path: '/admin-dashboard', builder: (_, __) => const AdminDashboard()),
            GoRoute(path: '/admin-users', builder: (_, __) => const UserManagementScreen()),

            // Merchant Sub-menu Routes
            GoRoute(
              path: '/admin-merchants/:status',
              builder: (context, state) {
                final status = state.pathParameters['status'] ?? 'pending';

                return AdminKycListScreen(status: status);
              },
            ),

            GoRoute(path: '/admin-finance/commission', builder: (_, __) => const AdminCommissionScreen()),
            GoRoute(path: '/admin-finance/payouts', builder: (_, __) => const AdminPayoutApprovalScreen()),

            // Product Sub-menu Routes
            GoRoute(path: '/admin-products', builder: (_, __) => const AdminProductApprovalScreen()),
            GoRoute(path: '/admin-categories', builder: (_, __) => const AdminCategoryScreen()),
            GoRoute(path: '/admin-subcategories', builder: (_, __) => const AdminSubCategoryScreen()),

            // Other Admin Routes
            GoRoute(path: '/admin-orders', builder: (_, __) => AdminOrderScreen()),
            GoRoute(
              path: '/admin-refund/:status', // :status acts as a variable
              builder: (context, state) {
                // Extract the status from the URL
                final status = state.pathParameters['status'] ?? 'pending';
                return AdminRefundRequestScreen(status: status);
              },
            ),

            // 1. Banner Route (Already in your list)
            GoRoute(
              path: '/admin-cms/banners',
              builder: (_, __) => const BannerManagementScreen(),
            ),

// 2. Static Pages Route with Slug parameter
            GoRoute(
              path: '/admin-pages/:slug', // :slug will be 'about-us', 'privacy-policy', etc.
              builder: (context, state) {
                final slug = state.pathParameters['slug'] ?? 'about-us';

                // Pass the slug to your screen so it knows which content to fetch
                return AdminStaticPagesScreen(slug: slug);
              },
            ),

            GoRoute(
              path: '/admin-salesreport',
              builder: (_, __) => const SalesReportScreen(),
            ),
            GoRoute(
              path: '/admin-commisionreport',
              builder: (_, __) => const AdminCommissionReport(),
            ),
            GoRoute(
              path: '/admin-taxreport',
              builder: (_, __) => const AdminIncomeTaxReport(),
            ),

            GoRoute(
              path: '/admin-profile',
              builder: (_, __) => const AdminProfileScreen(),
            ),
            GoRoute(
              path: '/admin-notification/send',
              builder: (_, __) => const AdminNotificationScreen(),
            ),
            GoRoute(
              path: '/admin-notification/push',
              builder: (_, __) => const AdminNotificationScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
