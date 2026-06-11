import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';
import 'package:stoxneu/config/api_config.dart';

import '../../../../../core/themes/app_themes.dart';
import 'api/merchant_api.dart';
import 'merchant_model.dart';

class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() =>
      _MerchantProfileScreenState();
}

class _MerchantProfileScreenState
    extends State<MerchantProfileScreen> {

  Merchant? _merchant;

  ImageProvider? _imageProvider;

  Uint8List? _selectedBytes;

  String? _selectedFileName;

  bool _isLoading = true;
  bool _isSaving = false;

  String _cacheKey =
  DateTime.now().millisecondsSinceEpoch.toString();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _emailController =
  TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // =====================================================
  // FETCH PROFILE
  // =====================================================
  Future<void> _fetchData() async {
    try {
      final token =
      await context.read<AuthRepository>().getToken();

      final data =
      await MerchantApi.fetchProfile(token!);

      context.read<AuthRepository>().updateUserProfile(
        name: data.name,
        email: data.email,
        avatar: data.avatar,
      );

      setState(() {
        _merchant = data;

        _nameController.text = data.name;

        _phoneController.text =
            data.phone ?? '';

        _emailController.text =
            data.email ?? '';

        _updateImage();

        _isLoading = false;
      });

    } catch (e) {

      setState(() => _isLoading = false);
    }
  }

  // =====================================================
  // UPDATE IMAGE
  // =====================================================
  void _updateImage() {

    if (_selectedBytes != null) {

      _imageProvider =
          MemoryImage(_selectedBytes!);

    } else if (_merchant?.avatar != null &&
        _merchant!.avatar!.isNotEmpty) {

      final avatar = _merchant!.avatar!;

      final fullUrl = avatar.startsWith("http")
          ? avatar
          : "${ApiConfig.baseUrl}/$avatar";

      _imageProvider =
          NetworkImage("$fullUrl?v=$_cacheKey");

    } else {

      _imageProvider = null;
    }
  }

  // =====================================================
  // PICK IMAGE
  // =====================================================
  Future<void> _pickImage() async {

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );

    if (image != null) {

      final bytes =
      await image.readAsBytes();

      setState(() {

        _selectedBytes = bytes;

        _selectedFileName =
            image.name;

        _updateImage();
      });
    }
  }

  // =====================================================
  // SAVE PROFILE
  // =====================================================
  Future<void> _saveChanges() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {

      final token =
      await context.read<AuthRepository>().getToken();

      final result =
      await MerchantApi.updateProfile(
        token!,
        _merchant!,
        imageBytes: _selectedBytes,
        fileName: _selectedFileName,
      );

      context.read<AuthRepository>().updateUserProfile(
        name: result.name,
        email: result.email,
        avatar: result.avatar,
      );

      setState(() {

        _merchant = result;

        _selectedBytes = null;

        _cacheKey =
            DateTime.now()
                .millisecondsSinceEpoch
                .toString();

        _updateImage();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Profile updated successfully",
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(14),
          ),
        ),
      );

    } finally {

      setState(() => _isSaving = false);
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {

    if (_isLoading) {

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor:
      const Color(0xffF5F7FB),

      body: SingleChildScrollView(

        child: Column(

          children: [

            // =================================================
            // TOP HEADER
            // =================================================
            Container(

              width: double.infinity,

              padding: const EdgeInsets.only(
                top: 70,
                bottom: 35,
              ),

              decoration: const BoxDecoration(

                gradient: LinearGradient(
                  colors: [
                    Color(0xffF59E0B),
                    AppTheme.primaryColor
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),

              child: Column(

                children: [

                  // APPBAR
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),

                    child: Row(

                      children: [

                        InkWell(

                          onTap: () {
                            Navigator.pop(context);
                          },

                          child: Container(

                            width: 42,
                            height: 42,

                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius:
                              BorderRadius.circular(12),
                            ),

                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),

                        const Spacer(),

                        const Text(
                          "Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const Spacer(),

                        const SizedBox(width: 42),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // PROFILE IMAGE
                  Stack(

                    children: [

                      Container(

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),

                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.white,
                          backgroundImage: _imageProvider,

                          child: _imageProvider == null
                              ? Text(
                            _merchant!.name[0]
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 38,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          )
                              : null,
                        ),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,

                        child: InkWell(

                          onTap: _pickImage,

                          child: Container(

                            width: 38,
                            height: 38,

                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                  Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                ),
                              ],
                            ),

                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Text(
                    _merchant!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _merchant!.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // =================================================
            // FORM CARD
            // =================================================
            Transform.translate(

              offset: const Offset(0, -25),

              child: Padding(

                padding:
                const EdgeInsets.symmetric(horizontal: 18),

                child: Container(

                  padding: const EdgeInsets.all(22),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                    BorderRadius.circular(28),

                    boxShadow: [

                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),

                  child: Form(

                    key: _formKey,

                    child: Column(

                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        const Text(
                          "Personal Information",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "Update your merchant profile details",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 28),

                        _buildTextField(
                          "Full Name",
                          _nameController,
                          Icons.person_outline_rounded,
                        ),

                        _buildTextField(
                          "Email Address",
                          _emailController,
                          Icons.email_outlined,
                        ),

                        _buildTextField(
                          "Phone Number",
                          _phoneController,
                          Icons.phone_outlined,
                        ),

                        const SizedBox(height: 28),

                        SizedBox(

                          width: double.infinity,
                          height: 56,

                          child: ElevatedButton(

                            onPressed:
                            _isSaving
                                ? null
                                : _saveChanges,

                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor:
                                AppTheme.primaryColor,

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                            ),

                            child: _isSaving

                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                              CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )

                                : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // TEXT FIELD
  // =====================================================
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      ) {

    return Padding(

      padding: const EdgeInsets.only(bottom: 20),

      child: TextFormField(

        controller: controller,

        decoration: InputDecoration(

          labelText: label,

          prefixIcon: Icon(
            icon,
            color: AppTheme.primaryColor,
          ),

          filled: true,
          fillColor: const Color(0xffF8FAFC),

          contentPadding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.grey.shade200,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xff2563EB),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}