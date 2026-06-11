import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stoxneu/core/themes/app_themes.dart';
import 'package:stoxneu/Screens/Auth/bloc/auth_bloc.dart';
import 'package:stoxneu/Screens/Auth/bloc/auth_event.dart';
import 'package:stoxneu/Screens/Auth/bloc/auth_state.dart';
import 'package:stoxneu/Screens/Auth/repository/auth_repository.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final oldPasswordController = TextEditingController();
  bool _obscureOld = true;
  XFile? _localSelectedImage;

  Future<void> _pickAvatar() async {
    final ImagePicker picker = ImagePicker();
    // Pick an image from gallery
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);

    if (image != null) {
      setState(() {
        _localSelectedImage = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // ONLY trigger the Bloc fetch.
    // The 'listener' in build() will fill the fields once data arrives.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(FetchUserProfile());
    });
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isPanel = screenWidth > 900;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileLoadedState) {
          debugPrint("Data Received: ${state.userData}");
          setState(() {
            _localSelectedImage = null; // Clear the temporary local pick
          });
          // Temporarily force the update to see if it works
          nameController.text = state.userData['name']?.toString() ?? "";
          emailController.text = state.userData['email']?.toString() ?? "";
          phoneController.text = state.userData['phone']?.toString() ?? "";
        }

        // 2. Show success message for Profile or Password updates
        if (state is AuthSuccess) {

          imageCache.clear();
          imageCache.clearLiveImages();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Action Successful!"), backgroundColor: Colors.green),
          );
          // Clear password fields specifically
          oldPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },

      builder: (context, state) {
        if (state is AuthLoading && nameController.text.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(isPanel ? 30 : 16),
            child: Column(
              children: [
                _buildTabNavigation(),
                const SizedBox(height: 20),
                _buildMainProfileCard(isPanel),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Colors.transparent,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppTheme.primaryColor,
        ),
        tabs: const [
          Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Basic Information"))),
          Tab(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("Password"))),
        ],
      ),
    );
  }

  Widget _buildMainProfileCard(bool isPanel) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildBannerSection(),
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.all(32),
            child: SizedBox(
              height: 400, // Adjusted height for dynamic content
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(isPanel),
                  _buildPasswordTab(isPanel),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    final repo = context.watch<AuthRepository>();

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // ... (Your Banner Container)
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: _pickAvatar, // Tap avatar to change it
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child:CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFFD1E4FF),
                  backgroundImage: _localSelectedImage != null
                  // 1. Use FileImage for local file paths
                      ? FileImage(File(_localSelectedImage!.path)) as ImageProvider
                      : (repo.avatar != null && repo.avatar!.isNotEmpty)
                      ? NetworkImage(
                    // 2. Add timestamp to bypass cache and force fresh load
                    "${repo.avatar!.replaceFirst("http://", "https://")}?v=${DateTime.now().millisecondsSinceEpoch}",
                    headers: const {"ngrok-skip-browser-warning": "true"},
                  )
                      : null,
                  // 3. Error/Placeholder handling
                  child: (_localSelectedImage == null && (repo.avatar == null || repo.avatar!.isEmpty))
                      ? const Icon(Icons.person, size: 50, color: Colors.blue)
                      : null,
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(bool isPanel) {
    return Column(
      children: [
        if (isPanel)
          Row(
            children: [
              Expanded(child: _buildTextField("Full Name", nameController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Phone", phoneController)),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField("Email", emailController)),
            ],
          )
        else
          Column(
            children: [
              _buildTextField("Full Name", nameController),
              _buildTextField("Phone", phoneController),
              _buildTextField("Email", emailController),
            ],
          ),
        const Spacer(),
        _buildSaveButton(() {
          if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
            // Dispatch the real update event
            context.read<AuthBloc>().add(UpdateProfileRequested(
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              phone: phoneController.text.trim(),
              avatarXFile: _localSelectedImage,
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Name and Email are required")),
            );
          }
        }),

      ],
    );
  }

  Widget _buildPasswordTab(bool isPanel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Old Password Field (Required for security)
        _buildPasswordField(
            "Current Password",
            oldPasswordController,
            _obscureOld,
                () => setState(() => _obscureOld = !_obscureOld)
        ),

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Trigger Forgot Password Flow (Email OTP)
              context.go('/forgot-password');
            },
            child: const Text("Forgot current password?", style: TextStyle(fontSize: 12, color: Colors.blue)),
          ),
        ),

        const SizedBox(height: 10),

        if (isPanel)
          Row(
            children: [
              Expanded(child: _buildPasswordField("New Password", newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew))),
              const SizedBox(width: 20),
              Expanded(child: _buildPasswordField("Confirm Password", confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm))),
            ],
          )
        else
          Column(
            children: [
              _buildPasswordField("New Password", newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 16),
              _buildPasswordField("Confirm Password", confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ],
          ),

        const Spacer(),

        _buildSaveButton(() {
          if (oldPasswordController.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter current password")));
            return;
          }
          if (newPasswordController.text != confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
            return;
          }

          // Dispatch event with BOTH old and new password
          context.read<AuthBloc>().add(ChangePasswordRequested(
            oldPassword: oldPasswordController.text,
            newPassword: newPasswordController.text,
          ));
        }),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility), onPressed: toggle),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
