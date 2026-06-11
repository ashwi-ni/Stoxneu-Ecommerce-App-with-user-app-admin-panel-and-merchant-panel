import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../config/api_config.dart';
import '../../../../core/network/api_client.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  String _targetGroup = 'All Users';

  List<dynamic> _users = [];
  List<dynamic> _notifications = [];

  String? _selectedUserId;
  bool _isLoadingUsers = false;

  File? _selectedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchNotifications();
  }

  // ---------------- USERS ----------------
  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);

    try {
      final response = await ApiClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/admin/users',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _users = jsonDecode(response.body);
        });
      }
    } catch (e) {
      _showSnackBar("Error fetching users", Colors.red);
    }

    setState(() => _isLoadingUsers = false);
  }

  // ---------------- NOTIFICATIONS HISTORY ----------------
  Future<void> _fetchNotifications() async {
    try {
      final response = await ApiClient.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/admin/notifications',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
        });
      }
    } catch (e) {
      _showSnackBar("Error loading notifications", Colors.red);
    }
  }

  // ---------------- IMAGE PICKER ----------------
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImage = bytes; // Triggers UI redraw for Web
        });
      } else {
        setState(() {
          _selectedImage = File(picked.path); // Triggers UI redraw for Android
        });
      }
    }
  }


  // ---------------- SEND NOTIFICATION ----------------
  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.orange);
      return;
    }

    if (_targetGroup == "Specific User" && _selectedUserId == null) {
      _showSnackBar("Please select a user", Colors.orange);
      return;
    }

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse(
          "${ApiConfig.baseUrl}/admin/send-notification",
        ),
      );

      final token = await ApiClient.getToken();

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['title'] = _titleController.text;
      request.fields['body'] = _messageController.text;
      request.fields['target'] = _targetGroup;

      if (_targetGroup == "Specific User") {
        request.fields['userId'] = _selectedUserId!;
      }

      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImage!,
            filename: 'notification.jpg',
          ),
        );
      }

      else if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar("Notification Sent!", Colors.green);

        setState(() {
          _titleController.clear();
          _messageController.clear();
          _selectedUserId = null;
          _selectedImage = null;
          _webImage = null;
        });

        _fetchNotifications();
      } else {
        _showSnackBar("Failed to send", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9F9FB),
      appBar: AppBar(
        title: const Text("Send Notification"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- TARGET GROUP ----------------
              const Text(
                "Select Target Group",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _targetGroup,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  'All Users',
                  'All Merchants',
                  'Specific User'
                ].map((e) {
                  return DropdownMenuItem(value: e, child: Text(e));
                }).toList(),
                onChanged: (val) {
                  setState(() => _targetGroup = val!);
                },
              ),

              // ---------------- USER SELECT ----------------
              if (_targetGroup == "Specific User") ...[
                const SizedBox(height: 20),
                const Text(
                  "Select User",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                _isLoadingUsers
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                  value: _selectedUserId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _users.map<DropdownMenuItem<String>>((user) {
                    return DropdownMenuItem(
                      value: user['id'].toString(),
                      child: Text(user['name'] ?? "Unknown"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedUserId = val);
                  },
                ),
              ],

              const SizedBox(height: 20),

              // ---------------- TITLE ----------------
              const Text(
                "Notification Title",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "e.g. New Offer!",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- MESSAGE ----------------
              const Text(
                "Message",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Enter message...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ---------------- IMAGE PICKER ----------------
              Row(
                children: [
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image_outlined, size: 20),
                      label: const Text(
                        "Add Image",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff004182),
                        side: const BorderSide(
                          color: Color(0xff004182),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith(
                              (states) {
                            if (states.contains(MaterialState.hovered)) {
                              return const Color(0xff004182).withOpacity(0.06);
                            }
                            if (states.contains(MaterialState.pressed)) {
                              return const Color(0xff004182).withOpacity(0.12);
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),
                  _buildImagePreview(),

                  if (_selectedImage != null || _webImage != null)
                    Stack(
                      children: [

                        // WEB IMAGE
                        if (kIsWeb && _webImage != null)
                          Image.memory(
                            _webImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),

                        // MOBILE IMAGE
                        if (!kIsWeb && _selectedImage != null)
                          Image.file(
                            _selectedImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),

                        Positioned(
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImage = null;
                                _webImage = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 30),

              // ---------------- SEND BUTTON ----------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff004182),
                  ),
                  onPressed: _sendNotification,
                  child: const Text(
                    "Push Notification",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ---------------- TABLE ----------------
              const Text(
                "Sent Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: 30,
                        columns: const [
                          DataColumn(label: Text("Image")),
                          DataColumn(label: Text("Title")),
                          DataColumn(label: Text("Message")),
                          DataColumn(label: Text("Target")),
                          DataColumn(label: Text("Date")),
                          DataColumn(label: Text("Action")),
                        ],
                        rows: _notifications.map((n) {
                          return DataRow(
                            cells: [
                              DataCell(
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: (n['imageUrl'] != null &&
                                      n['imageUrl'].toString().isNotEmpty)
                                      ? Image.network(
                                    fixImage(n['imageUrl']),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    headers: const {
                                      'ngrok-skip-browser-warning': 'true',
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image);
                                    },
                                  )
                                      : const Icon(Icons.image_not_supported),
                                ),
                              ),
                              DataCell(Text(n['title'] ?? "")),
                              DataCell(Text(n['body'] ?? "")),
                              DataCell(Text(n['target'] ?? "")),
                              DataCell(
                                Text(
                                  n['createdAt'] != null
                                      ? n['createdAt'].toString().split('T')[0]
                                      : "",
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    final id = int.parse(n['id'].toString());
                                    _deleteNotification(id);
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildImagePreview() {
    bool hasImage = (kIsWeb && _webImage != null) || (!kIsWeb && _selectedImage != null);

    if (!hasImage) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        height: 160,
        width: 160,
        child: Stack(
          clipBehavior: Clip.none, // Prevents layout overlapping elements
          children: [
            // Main Preview Box
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: kIsWeb
                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                      : Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              ),
            ),

            // Isolated Delete Button
            Positioned(
              top: -5,
              right: -5,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _webImage = null;
                    _selectedImage = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNotification(int id) async {
    try {
      final response = await ApiClient.delete(
        Uri.parse(
          '${ApiConfig.baseUrl}/admin/notifications/$id',
        ),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Deleted successfully", Colors.green);
        _fetchNotifications();
      } else {
        _showSnackBar("Delete failed", Colors.red);
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    }
  }
  String fixImage(String? url) {
    if (url == null || url.isEmpty) return '';

    String fixed = url.replaceFirst("http://", "https://");

    return fixed;
  }
}