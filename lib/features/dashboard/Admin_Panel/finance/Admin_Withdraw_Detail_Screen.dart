// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//
// class AdminWithdrawDetailScreen extends StatefulWidget {
//   final int payoutId;
//   const AdminWithdrawDetailScreen({super.key, required this.payoutId});
//
//   @override
//   State<AdminWithdrawDetailScreen> createState() => _AdminWithdrawDetailScreenState();
// }
//
// class _AdminWithdrawDetailScreenState extends State<AdminWithdrawDetailScreen> {
//   final storage = const FlutterSecureStorage();
//   Map<String, dynamic>? data;
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchDetails();
//   }
//
//   // ✅ FETCH DETAILS (FIXED)
//   Future<void> fetchDetails() async {
//     try {
//       final token = await storage.read(key: 'jwt');
//
//       // ✅ CORRECT
//       final String fullUrl = "https://ngrok-free.dev{widget.payoutId}";
//
//
//       debugPrint("Calling URL: $fullUrl");
//
//       final response = await http.get(
//         Uri.parse(fullUrl),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'ngrok-skip-browser-warning': 'true',
//         },
//       );
//
//       debugPrint("Status: ${response.statusCode}");
//       debugPrint("Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final result = jsonDecode(response.body); // ✅ FIXED (object)
//
//         setState(() {
//           data = result;
//           isLoading = false;
//         });
//       } else if (response.statusCode == 404) {
//         debugPrint("❌ Data not found in DB");
//         setState(() {
//           data = null;
//           isLoading = false;
//         });
//       } else {
//         debugPrint("❌ Unexpected error: ${response.statusCode}");
//         setState(() => isLoading = false);
//       }
//     } catch (e) {
//       debugPrint("❌ Fetch Error: $e");
//       setState(() => isLoading = false);
//     }
//   }
//
//   // ✅ UPDATE STATUS (FIX YOUR ENDPOINT HERE)
//   Future<void> _updateStatus(String status, String note) async {
//     try {
//       final token = await storage.read(key: 'jwt');
//
//       final response = await http.post(
//         Uri.parse("https://convertibly-slavish-geoffrey.ngrok-free.dev"), // 🔥 change if needed
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'ngrok-skip-browser-warning': 'true',
//         },
//         body: jsonEncode({
//           'payout_id': widget.payoutId,
//           'merchant_id': data!['merchant_id'],
//           'amount': data!['amount'],
//           'status': status,
//           'note': note
//         }),
//       );
//
//       debugPrint("Update Status Code: ${response.statusCode}");
//       debugPrint("Update Body: ${response.body}");
//
//       if (response.statusCode == 200) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Payout successfully $status")),
//         );
//       }
//     } catch (e) {
//       debugPrint("❌ Update Error: $e");
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Scaffold(
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }
//
//     if (data == null) {
//       return const Scaffold(
//         body: Center(child: Text("Request not found")),
//       );
//     }
//
//     return Scaffold(
//       backgroundColor: const Color(0xffF3F5F9),
//       appBar: AppBar(
//         title: const Text("Withdraw",
//             style: TextStyle(fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(25),
//         child: Column(
//           children: [
//             _buildTopSummaryCard(),
//             const SizedBox(height: 25),
//
//             Row(
//               children: [
//                 Expanded(
//                   child: _infoCard("Bank Info", [
//                     "Holder: ${data!['account_holder'] ?? 'N/A'}",
//                     "Account: ${data!['account_number'] ?? 'N/A'}",
//                     "IFSC: ${data!['ifsc_code'] ?? 'N/A'}",
//                   ]),
//                 ),
//                 const SizedBox(width: 20),
//                 Expanded(
//                   child: _infoCard("Shop Info", [
//                     "Shop: ${data!['shop_name'] ?? 'N/A'}",
//                     "Phone: ${data!['shop_phone'] ?? 'N/A'}",
//                     "Address: ${data!['shop_address'] ?? 'N/A'}",
//                   ]),
//                 ),
//                 const SizedBox(width: 20),
//                 Expanded(
//                   child: _infoCard("Vendor Info", [
//                     "Name: ${data!['vendor_name'] ?? 'N/A'}",
//                     "Email: ${data!['vendor_email'] ?? 'N/A'}",
//                   ]),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTopSummaryCard() {
//     String date = "N/A";
//     if (data!['requested_at'] != null) {
//       date = DateFormat('yyyy-MM-dd HH:mm:ss')
//           .format(DateTime.parse(data!['requested_at']));
//     }
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10)),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text("₹${data!['amount']}",
//                   style: const TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold)),
//               Text(date),
//             ],
//           ),
//           ElevatedButton(
//             onPressed: _showStatusDialog,
//             child: const Text("Proceed"),
//           )
//         ],
//       ),
//     );
//   }
//
//   Widget _infoCard(String title, List<String> lines) {
//     return Container(
//       height: 180,
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(10)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title,
//               style: const TextStyle(fontWeight: FontWeight.bold)),
//           const Divider(),
//           ...lines.map((e) => Text(e)).toList(),
//         ],
//       ),
//     );
//   }
//
//   void _showStatusDialog() {
//     String selectedStatus = 'approved';
//     final noteController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Process Request"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             DropdownButtonFormField(
//               value: selectedStatus,
//               items: const [
//                 DropdownMenuItem(value: 'approved', child: Text("Approve")),
//                 DropdownMenuItem(value: 'rejected', child: Text("Reject")),
//               ],
//               onChanged: (v) => selectedStatus = v!,
//             ),
//             const SizedBox(height: 10),
//             TextField(controller: noteController),
//           ],
//         ),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _updateStatus(selectedStatus, noteController.text);
//             },
//             child: const Text("Submit"),
//           )
//         ],
//       ),
//     );
//   }
// }