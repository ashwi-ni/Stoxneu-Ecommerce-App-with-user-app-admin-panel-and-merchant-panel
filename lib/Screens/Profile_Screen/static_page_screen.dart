import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:flutter_quill/quill_delta.dart';

import '../../features/dashboard/Admin_Panel/cms/Static Pages/Model/static_page_model.dart';
import 'api/static_page_api.dart';

class StaticPageScreen extends StatefulWidget {

  final String slug;

  const StaticPageScreen({
  super.key,
  required this.slug,
  });

  @override
  State<StaticPageScreen> createState() =>
      _StaticPageScreenState();
}

class _StaticPageScreenState
    extends State<StaticPageScreen> {

  final StaticPageApi _api = StaticPageApi();

  bool isLoading = true;

  StaticPageModel? page;

  late QuillController _controller;

  @override
  void initState() {
    super.initState();

    _controller = QuillController.basic();

    loadPage();
  }

  Future<void> loadPage() async {

    try {

      final data =
      await _api.fetchPage(widget.slug);

      Document doc;

      try {

        doc = Document.fromJson(
          jsonDecode(data.content),
        );

      } catch (e) {

        final delta = Delta()
          ..insert(data.content)
          ..insert('\n');

        doc = Document.fromDelta(delta);
      }

      _controller = QuillController(
        document: doc,
        selection:
        const TextSelection.collapsed(offset: 0),
      );

      setState(() {
        page = data;
        isLoading = false;
      });

    } catch (e) {

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(
        title: Text(
          page?.title ?? "Loading...",
        ),
      ),

      body: isLoading

          ? const Center(
        child: CircularProgressIndicator(),
      )

          : Padding(

        padding: const EdgeInsets.all(16),

        child: QuillEditor.basic(
          controller: _controller,
        ),
      ),
    );
  }
}