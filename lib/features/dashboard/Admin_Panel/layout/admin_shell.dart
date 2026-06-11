import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../Screens/Auth/bloc/auth_bloc.dart';
import '../../../../Screens/Auth/bloc/auth_event.dart';
import '../../../../Screens/Auth/repository/auth_repository.dart';

class AdminShell extends StatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  bool _isCollapsed = false;
  // 🔥 Track if merchant sub-menu is open
  bool _isMerchantsOpen = false;
  bool _isCategoriesOpen= false;
  bool _isRefundOpen = false;
  bool _isfinanceOpen= false;
  bool _isCMSOpen = false;
  bool _isStaticPagesOpen = false;
  bool _isnotifyOpen = false;
  static const double expandedWidth = 230;
  static const double collapsedWidth = 70;


  String _getTitle(String route) {
    if (route.contains('/admin-dashboard')) return 'Dashboard';
    if (route.contains('/admin-users')) return 'Users Management';
    if (route.contains('/admin-merchants')) return 'Merchants';
    if (route.contains('/admin-products')) return 'Products';
    if (route.contains('/admin-orders')) return 'Orders';
    if (route.contains('/admin-profile')) return 'Profile';
    // Add more logic based on your routes...
    return 'Admin Panel';
  }
  @override
  Widget build(BuildContext context) {
    context.watch<AuthRepository>();
    final currentRoute = GoRouterState.of(context).uri.toString();
    final repo = context.watch<AuthRepository>();
// 2. Get the initial letter (handles empty names safely)
    final String initial = (repo.userName != null && repo.userName!.isNotEmpty)
        ? repo.userName![0].toUpperCase()
        : "A";
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: Row(
        children: [
          /// ================= SIDEBAR =================
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _isCollapsed ? collapsedWidth : expandedWidth,
            color: const Color(0xFF111827),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildLogoHeader(),
                const SizedBox(height: 30),
                Expanded(
                child:SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      _menuItem(Icons.dashboard, "Dashboard", "/admin-dashboard", currentRoute),
                  
                  
                  _menuItem(Icons.people, "Users", "/admin-users", currentRoute),
                  
                  /// 🔥 MERCHANT WITH SUB-MENUS
                  _menuItem(
                    Icons.store,
                    "Merchants",
                    "/admin-merchants",
                    currentRoute,
                    isExpandable: true,
                    isOpen: _isMerchantsOpen,
                    onExpandTap: () => setState(() => _isMerchantsOpen = !_isMerchantsOpen),
                    subItems: [
                      // These routes must match your GoRouter definitions
                      _subMenuItem("Pending KYC", "/admin-merchants/pending", currentRoute),
                      _subMenuItem("Approved KYC", "/admin-merchants/approved", currentRoute),
                      _subMenuItem("Rejected KYC", "/admin-merchants/rejected", currentRoute),
                  
                  
                    ],
                  ),
                  
                  _menuItem(Icons.shopping_bag, "Products", "/admin-products", currentRoute
                  ),
                  
                  _menuItem(Icons.shopping_bag, "Category Setup", "/admin-categories", currentRoute,
                    isExpandable: true,
                    isOpen: _isCategoriesOpen,
                    onExpandTap: () => setState(() => _isCategoriesOpen = !_isCategoriesOpen),
                    subItems: [
                      _subMenuItem("Categories", "/admin-categories", currentRoute),
                      _subMenuItem("Sub Categories", "/admin-subcategories", currentRoute),
                    ],
                  ),
                  
                  _menuItem(Icons.receipt, "Orders", "/admin-orders", currentRoute),
                  _menuItem(
                    Icons.assignment_return, // Better icon for refunds
                    "Refund Request",
                    "/admin-refund",
                    currentRoute,
                    isExpandable: true,
                    isOpen: _isRefundOpen,
                    onExpandTap: () => setState(() => _isRefundOpen = !_isRefundOpen),
                    subItems: [
                      _subMenuItem("Pending", "/admin-refund/pending", currentRoute),
                      _subMenuItem("Approved", "/admin-refund/approved", currentRoute),
                      _subMenuItem("Refunded", "/admin-refund/refunded", currentRoute),
                      _subMenuItem("Rejected", "/admin-refund/rejected", currentRoute),
                    ],
                  ),
                  
                              _menuItem(Icons.account_balance, "Finance", "/admin-finance", currentRoute,
                    isExpandable: true,
                    isOpen: _isfinanceOpen,
                    onExpandTap: () => setState(() => _isfinanceOpen = !_isfinanceOpen),
                    subItems: [
                      _subMenuItem("Commission", "/admin-finance/commission", currentRoute),
                      _subMenuItem("Payouts", "/admin-finance/payouts", currentRoute),
                  
                    ],
                  ),
                  
                  _menuItem(
                    Icons.web,
                    "CMS",
                    "/admin-cms",
                    currentRoute,
                    isExpandable: true,
                    isOpen: _isCMSOpen,
                    onExpandTap: () => setState(() => _isCMSOpen = !_isCMSOpen),
                    subItems: [
                      /// --- Level 2: Banner Setup ---
                      _subMenuItem("Banner Setup", "/admin-cms/banners", currentRoute),
                  
                      /// --- Level 2: Static Pages (Expandable Group) ---
                      _nestedSubGroup(
                        title: "Static Pages",
                        isOpen: _isStaticPagesOpen,
                        onTap: () => setState(() => _isStaticPagesOpen = !_isStaticPagesOpen),
                        children: [
                          _subMenuItem("About Us", "/admin-pages/about-us", currentRoute, isNested: true),
                          _subMenuItem("Privacy Policy", "/admin-pages/privacy-policy", currentRoute, isNested: true),
                          _subMenuItem("Terms & Conditions", "/admin-pages/terms", currentRoute, isNested: true),
                          _subMenuItem("Support", "/admin-pages/support", currentRoute, isNested: true),
                        ],
                      ),
                    ],
                  ),

                      _menuItem(Icons.account_balance, "Notifications", "/admin-notification", currentRoute,
                        isExpandable: true,
                        isOpen: _isnotifyOpen,
                        onExpandTap: () => setState(() => _isnotifyOpen = !_isnotifyOpen),
                        subItems: [
                          _subMenuItem("send notification", "/admin-notification/send", currentRoute),
                        //  _subMenuItem("push notification", "/admin-notification/push", currentRoute),

                        ],
                      ),


                  _menuItem(Icons.report, "Sales Report", "/admin-salesreport", currentRoute),
                      _menuItem(Icons.report, "Commission Report", "/admin-commisionreport", currentRoute),
                      _menuItem(Icons.report, "Tax Report", "/admin-taxreport", currentRoute),
                                ],
                              ),
                ),
                )] ),
    ),
          /// ================= MAIN AREA =================
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Text(
                        _getTitle(currentRoute),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87
                        ),
                      ),
                      const Spacer(),

                      // Notification Icon
                      IconButton(
                        icon: const Icon(Icons.notifications_none_outlined, color: Colors.black54),
                        onPressed: () {
                          // Handle notifications
                        },
                      ),

                      const SizedBox(width: 8),

                      /// Profile Popup Menu (Matching your visual)
    // 1. Get the repository at the top of your build method


    PopupMenuButton<String>(
    offset: const Offset(0, 50),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onSelected: (value) {
    if (value == 'profile') context.go('/admin-profile');
    if (value == 'logout') {
    context.read<AuthBloc>().add(AuthLoggedOut());
    }
    },
    child: CircleAvatar(
    radius: 18,
    backgroundColor: const Color(0xFFD1E4FF),
    // Use the same logic as your profile screen
    backgroundImage: (repo.avatar != null && repo.avatar!.isNotEmpty)
    ? NetworkImage(
    "${repo.avatar!.replaceFirst("http://", "https://")}?v=${DateTime.now().millisecondsSinceEpoch}",
    headers: const {"ngrok-skip-browser-warning": "true"},
    )
        : null,
    // Show the Initial Letter only if there is no image
    child: (repo.avatar == null || repo.avatar!.isEmpty)
    ? Text(
    initial,
    style: const TextStyle(
    color: Color(0xFF0052CC),
    fontWeight: FontWeight.bold,
    fontSize: 14,
    ),
    )
        : null,
    ),
    itemBuilder: (context) => [
    const PopupMenuItem(
    value: 'profile',
    child: Row(
    children: [
    Icon(Icons.person_outline, size: 20),
    SizedBox(width: 12),
    Text("Profile"),
    ],
    ),
    ),
    const PopupMenuItem(
    value: 'logout',
    child: Row(
    children: [
    Icon(Icons.logout, size: 20, color: Colors.red),
    SizedBox(width: 12),
    Text("Logout", style: TextStyle(color: Colors.red)),
    ],
    ),
    ),
    ],
    )
                    ],
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Parent Menu Item with Expansion Logic
  Widget _menuItem(
      IconData icon,
      String title,
      String route,
      String currentRoute, {
        bool isExpandable = false,
        bool isOpen = false,
        VoidCallback? onExpandTap,
        List<Widget>? subItems,
      }) {
    final isActive = currentRoute.startsWith(route.split('/:').first);

    return Column(
      children: [
        InkWell(
          onTap: isExpandable ? onExpandTap : () => context.go(route),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row( // This is line 203 causing the error
              children: [
                Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 20),

                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: isActive ? Colors.blue : Colors.grey,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isExpandable) ...[
                            const SizedBox(width: 4),
                            Icon(
                              isOpen ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Only show sub-items if not collapsed and is open
        if (!_isCollapsed && isExpandable && isOpen && subItems != null)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(children: subItems),
          ),
      ],
    );
  }


  /// Clean Sub-menu Item
  /// Helper for the 2nd level "Static Pages" group
  Widget _nestedSubGroup({required String title, required bool isOpen, required VoidCallback onTap, required List<Widget> children}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 40, right: 8, top: 4, bottom: 4),
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.white54)),
                const Spacer(),
                Icon(isOpen ? Icons.expand_more : Icons.chevron_right, color: Colors.white54, size: 14),
              ],
            ),
          ),
        ),
        if (isOpen) ...children,
      ],
    );
  }

  /// Updated Sub-menu item to support deeper nesting
  Widget _subMenuItem(String title, String route, String currentRoute, {bool isNested = false}) {
    final isActive = currentRoute == route;
    return InkWell(
      onTap: () => context.go(route),
      child: Container(
        // 🔥 If isNested is true, we push it further right (indent: 55)
        margin: EdgeInsets.only(left: isNested ? 55 : 40, right: 8, top: 2, bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: isActive ? Colors.blue : Colors.white38)),
          ],
        ),
      ),
    );
  }


  // Header Logo logic (helper to keep build clean)
  Widget _buildLogoHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),

      child: Row(
        mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
        children: [
          if (!_isCollapsed)
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
            icon: Icon(_isCollapsed ? Icons.arrow_forward_ios : Icons.menu, color: Colors.white, size: 18),
            onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
          ),
        ],
      ),
    );
  }
}
