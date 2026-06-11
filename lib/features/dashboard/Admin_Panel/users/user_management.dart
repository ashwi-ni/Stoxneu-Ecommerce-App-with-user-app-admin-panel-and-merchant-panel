import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // FIX: Removed the "as storage show read" import
import 'package:stoxneu/features/dashboard/Admin_Panel/users/user_detail_screen.dart';
import '../../../../config/api_config.dart';
import '../services/user_management_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserManagementService service = UserManagementService(
      ApiConfig.baseUrl);
  final storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  List<dynamic> allUsers = [];
  List<dynamic> filteredUsers = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      String? token = await storage.read(key: 'jwt');
      if (token != null) {
        final data = await service.getAllUsers(token);
        setState(() {
          allUsers = data;
          filteredUsers = data;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => loading = false);
    }
  }

  // 🔥 NEW: Delete Logic
  Future<void> _handleDelete(int userId) async {
    try {
      String? token = await storage.read(key: 'jwt');
      if (token != null) {
        bool success = await service.deleteUser(token, userId);

        if (success) {
          fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User deleted successfully")),
          );
        } else {
          // 🔥 ADD THIS
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Delete API failed"), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print("Delete Error: $e"); // 🔥 ADD LOG
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delete failed"), backgroundColor: Colors.red),
      );
    }
  }

  // --- Search Logic ---
  void _filterSearch(String query) {
    setState(() {
      filteredUsers = allUsers.where((user) {
        final name = (user['name'] ?? "").toString().toLowerCase();
        final email = (user['email'] ?? "").toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> toggleUserStatus(int userId, int currentStatus) async {
    try {
      String? token = await storage.read(key: 'jwt');
      if (token != null) {
        bool success = await service.toggleBlock(token, userId);
        if (success) {
          fetchUsers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User status updated successfully")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Update failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Customer List",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCustomerTableCard(),
          ],
        ),
      ),
    );
  }
  Widget _buildCustomerTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Customer List (${filteredUsers.length})",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSearch,
                    decoration: InputDecoration(
                      hintText: "Search by Name or Email",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 20,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    columns: const [
                      DataColumn(label: Text("SL")),
                      DataColumn(label: Text("Customer Name")),
                      DataColumn(label: Text("Contact Info")),
                      DataColumn(label: Text("Total Order")),
                      DataColumn(label: Text("Block/Unblock")),
                      DataColumn(label: Text("Action")),
                    ],
                    rows: filteredUsers.asMap().entries.map((entry) {
                      int index = entry.key + 1;
                      var user = entry.value;
                      return DataRow(cells: [
                        DataCell(Text(index.toString())),
                        DataCell(Row(
                          children: [
                            // CircleAvatar(
                            //   radius: 18,
                            //   backgroundImage: NetworkImage(
                            //     "https://ui-avatars.com/api/?name=${user['name'] ?? 'User'}",
                            //   ),
                            // ),
                            // const SizedBox(width: 10),
                            Text(user['name'] ?? "No Name"),
                          ],
                        )),
                        DataCell(Text(user['email'] ?? "N/A")),
                        DataCell(Text(user['total_orders']?.toString() ?? "0")),
                        DataCell(Switch(
                          value: user['is_blocked'] == 1,
                          activeColor: Colors.red,
                          onChanged: (val) => toggleUserStatus(user['id'], user['is_blocked']),
                        )),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomerDetailsScreen(userId: user['id']),
                                  ),
                                );
                              },
                            ),
                            // 🔥 THE DELETE BUTTON (Added this part)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _showDeleteDialog(user['id']),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔥 THE DIALOG FUNCTION (Add this at the bottom of your _UserManagementScreenState class)
  void _showDeleteDialog(int userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete User"),
        content: const Text("Are you sure? This will remove the user permanently."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(userId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }


}
