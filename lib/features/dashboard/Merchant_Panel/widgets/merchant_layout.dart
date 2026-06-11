import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../Screens/Auth/repository/auth_repository.dart';
import '../../../../config/api_config.dart';
import '../screens/notifications/merchant_notification_screen.dart';
import '../screens/notifications/service/merchant_notification_api.dart';

class MerchantLayout extends StatefulWidget {
  final Widget child;

  const MerchantLayout({super.key, required this.child});

  @override
  State<MerchantLayout> createState() => _MerchantLayoutState();
}

class _MerchantLayoutState extends State<MerchantLayout> {
  bool _isSidebarCollapsed = false;
  static const double _sidebarWidth = 230;
  static const double _collapsedWidth = 70;

  /// ✅ Page Title
  String getTitle(String route) {
    if (route.contains("dashboard")) return "Dashboard";
    if (route.contains("products")) return "Products";
    if (route.contains("orders")) return "Orders";
    if (route.contains("refunds")) return "Refunds";
    if (route.contains("coupons")) return "Coupons";
    if (route.contains("sale")) return "Sales";
    if (route.contains("payments")) return "Payments";
    return "";
  }

  /// ✅ Get Initial Letter
  String getInitial(String name) {
    if (name.isEmpty) return "?";
    return name.trim()[0].toUpperCase();
  }

  /// ✅ Avatar Widget
  Widget _buildAvatar({
    required double radius,
    required String userName,
    String? avatarUrl,
  }) {
    String? fullUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (avatarUrl.startsWith('http')) {
        fullUrl = avatarUrl;
      } else {
        fullUrl =
        "${ApiConfig.baseUrl}/$avatarUrl";
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade100,
      child: ClipOval(
        child: (fullUrl != null)
            ? Image.network(
          "$fullUrl?v=${DateTime.now().millisecondsSinceEpoch}",
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Text(getInitial(userName)));
          },
        )
            : Center(child: Text(getInitial(userName))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthRepository>();
    final userName = auth.userName ?? "User";
    final email = auth.email;
    final avatarUrl = auth.avatar;

    final currentRoute = GoRouterState.of(context).uri.toString();

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: Row(
        children: [
          /// 🔲 SIDEBAR
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isSidebarCollapsed ? 60 : 200,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: _isSidebarCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (!_isSidebarCollapsed)
                      Flexible(
                        child: SizedBox(
                          width: 150,
                          child: Image.asset(
                            'assets/images/brandlogo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        _isSidebarCollapsed ? Icons.arrow_forward_ios : Icons.menu,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSidebarCollapsed = !_isSidebarCollapsed;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                _menuItem(
                    context, Icons.dashboard, "Overview", "/merchant-dashboard", currentRoute),
                _menuItem(
                    context, Icons.inventory, "Products", "/merchant-products", currentRoute),
                _menuItem(
                    context, Icons.shopping_cart, "Orders", "/merchant-orders", currentRoute),
                _menuItem(
                    context, Icons.restore, "Refund", "/merchant-refunds", currentRoute),
                _menuItem(
                    context, Icons.receipt, "Coupons", "/merchant-coupons", currentRoute),
                _menuItem(
                    context, Icons.local_offer, "Offers & Sales", "/merchant-sale/clearance", currentRoute),
                _menuItem(
                    context, Icons.payment, "Payment", "/merchant-payments", currentRoute),
                _menuItem(
                    context, Icons.shop, "Shop Setting", "/merchant-shop", currentRoute),
                const Spacer(),
              ],
            ),
          ),

          /// 🟦 MAIN AREA
          Expanded(
            child: Column(
              children: [

                /// 🔝 TOP BAR
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  color: Colors.white,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [

                      /// 📌 TITLE
                      Text(
                        getTitle(currentRoute),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      /// 👉 RIGHT SIDE
                      Row(
                        children: [

                          /// 🔔 NOTIFICATION BADGE
                          FutureBuilder<int>(

                            future: MerchantNotificationApi()
                                .fetchUnreadCount(),

                            builder: (context, snapshot) {

                              final unreadCount =
                                  snapshot.data ?? 0;

                              return Stack(
                                clipBehavior: Clip.none,

                                children: [

                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none,
                                      size: 26,
                                    ),

                                    onPressed: () async {

                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const MerchantNotificationScreen(),
                                        ),
                                      );

                                      setState(() {});
                                    },
                                  ),
                                  /// 🔴 BADGE
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 3,
                                      top: 3,

                                      child: Container(

                                        padding:
                                        const EdgeInsets.all(5),

                                        decoration:
                                        const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),

                                        constraints:
                                        const BoxConstraints(
                                          minWidth: 18,
                                          minHeight: 18,
                                        ),

                                        child: Text(

                                          unreadCount > 99
                                              ? "99+"
                                              : unreadCount.toString(),

                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),

                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(width: 15),

                          /// 👤 PROFILE MENU
                          PopupMenuButton<String>(

                            onSelected: (value) async {

                              if (value == "logout") {

                                await context
                                    .read<AuthRepository>()
                                    .logout();

                                context.go("/login");

                              } else if (value == "settings") {

                                context.go("/merchant-profile");
                              }
                            },

                            itemBuilder: (context) => [

                              PopupMenuItem(
                                enabled: false,

                                child: Row(
                                  children: [

                                    _buildAvatar(
                                      radius: 20,
                                      userName: userName,
                                      avatarUrl: avatarUrl,
                                    ),

                                    const SizedBox(width: 10),

                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,

                                      children: [

                                        Text(
                                          userName,

                                          style: const TextStyle(
                                            fontWeight:
                                            FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),

                                        if (email != null &&
                                            email.isNotEmpty)

                                          Text(
                                            email,

                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    )
                                  ],
                                ),
                              ),

                              const PopupMenuDivider(),

                              const PopupMenuItem(
                                value: "settings",

                                child: ListTile(
                                  leading: Icon(
                                    Icons.settings_outlined,
                                    size: 20,
                                  ),

                                  title: Text("Settings"),

                                  dense: true,
                                ),
                              ),

                              const PopupMenuItem(
                                value: "logout",

                                child: ListTile(
                                  leading: Icon(
                                    Icons.logout,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),

                                  title: Text(
                                    "Logout",

                                    style: TextStyle(
                                      color: Colors.redAccent,
                                    ),
                                  ),

                                  dense: true,
                                ),
                              ),
                            ],

                            child: _buildAvatar(
                              radius: 18,
                              userName: userName,
                              avatarUrl: avatarUrl,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 🔹 PAGE CONTENT
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ SIDEBAR MENU ITEM
  Widget _menuItem(BuildContext context, IconData icon, String title,
      String route, String currentRoute) {
    final isActive = route.contains("merchant-sale")
        ? currentRoute.contains("merchant-sale")
        : currentRoute == route;

    return ListTile(
      leading: SizedBox(
        width: 40, // fixed width for your icon
        child: Icon(icon, color: Colors.white),
      ),
      title: _isSidebarCollapsed ? null : Text(title, style: const TextStyle(color: Colors.white)),
      tileColor: isActive ? Colors.blue : Colors.transparent,
      onTap: () => context.go(route),
      horizontalTitleGap: _isSidebarCollapsed ? 0 : 16,
      minLeadingWidth: 0,
    );
  }
}