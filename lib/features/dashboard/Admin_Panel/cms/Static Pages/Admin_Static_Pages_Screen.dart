import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import '../../../../../Screens/Products/product_api.dart';

class AdminStaticPagesScreen extends StatefulWidget {
  final String slug;
  const AdminStaticPagesScreen({super.key, required this.slug});

  @override
  State<AdminStaticPagesScreen> createState() => _AdminStaticPagesScreenState();
}

class _AdminStaticPagesScreenState extends State<AdminStaticPagesScreen> {
  late final ProductApi productApi;
  String _selectedTitle = "";
  late QuillController _quillController;

  @override
  void initState() {
    super.initState();
    productApi = ProductApi();

    _quillController = QuillController.basic();
    _loadPageContent();
  }

  @override
  void dispose() {
    _quillController.dispose(); // 🔥 Clean up controller
    super.dispose();
  }

  @override
  void didUpdateWidget(AdminStaticPagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.slug != widget.slug) {
      _loadPageContent();
    }
  }

  Future<void> _loadPageContent() async {
    try {
      final pageData = await productApi.fetchStaticPage(widget.slug);

      if (!mounted) return;

      setState(() {
        _selectedTitle = pageData.title;

        if (pageData.content.isNotEmpty) {
          try {

            final doc = Document.fromJson(jsonDecode(pageData.content));
            _quillController = QuillController(
              document: doc,
              selection: const TextSelection.collapsed(offset: 0),
            );
          } catch (e) {
            final delta = Delta()..insert(pageData.content)..insert('\n');
            _quillController = QuillController(
              document: Document.fromDelta(delta),
              selection: const TextSelection.collapsed(offset: 0),
            );
          }
        } else {
          _quillController.clear();
        }
      });
    } catch (e) {

      if (!mounted) return;
      setState(() {
        _selectedTitle = widget.slug.replaceAll('-', ' ').toUpperCase();
        _quillController.clear();
      });
      debugPrint("API Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Edit: $_selectedTitle",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),


            QuillSimpleToolbar(
              controller: _quillController,
            ),

            const SizedBox(height: 10),


            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: QuillEditor.basic(
                  controller: _quillController,
                ),
              ),
            ),


            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff004182),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                try {
                  // Convert current document state to JSON string
                  final contentJson = jsonEncode(_quillController.document.toDelta().toJson());

                  await productApi.saveStaticPage(
                    slug: widget.slug,
                    title: _selectedTitle,
                    content: contentJson,
                  );

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Changes Saved Successfully!"),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error saving data: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
