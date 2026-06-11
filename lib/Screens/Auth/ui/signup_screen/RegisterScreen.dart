import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/themes/app_themes.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../repository/auth_repository.dart';
import '../../../../core/constants/user_role.dart';

// Extension for capitalization logic used in your snippet
extension StringExtension on String {
  String capitalize() => "${this[0].toUpperCase()}${substring(1)}";
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole selectedRole = UserRole.user;

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isPanel = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(authRepository),
        child: isPanel ? _buildSplitScreenPanel(context) : _buildMobileUI(context),
      ),
    );
  }

  Widget _buildSplitScreenPanel(BuildContext context) {
    return Row(
      children: [
        // LEFT SIDE - Same as Login for brand consistency
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF111827),
            child: Stack(
              children: [
                Positioned(
                  top: 50,
                  left: 60,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 80,
                        child: Image.asset("assets/images/brandlogo.png", fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 80),
                      const Text("Join Our Platform", style: TextStyle(fontSize: 52, color: Colors.white)),
                      Text("Start Growing...", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: SizedBox(
                    height: 500,
                    child: Image.asset("assets/images/logincart.png", fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ),
        // RIGHT SIDE - Form
        Expanded(
          flex: 4,
          child: Center(child: SingleChildScrollView(child: _buildRegisterCard(context, true))),
        ),
      ],
    );
  }

  Widget _buildMobileUI(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: _buildRegisterCard(context, false),
    );
  }

  Widget _buildRegisterCard(BuildContext context, bool isPanel) {
    return Card(
      elevation: isPanel ? 10 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(maxWidth: isPanel ? 500 : double.infinity),
        padding: const EdgeInsets.all(32),
        child: BlocConsumer<AuthBloc, AuthState>(
          // Update the listener inside your BlocConsumer
          listener: (context, state) {
            if (state is RegistrationSuccess) {
              // This will now show!
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account Created! Please Login."),
                  backgroundColor: Colors.green,
                ),
              );

              emailController.clear();
              passwordController.clear();
              confirmPasswordController.clear();

              // Manual navigation to login
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) context.go('/login');
              });
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },




          builder: (context, state) {
            return Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create Account", style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),

                  // Email Field
                  _buildInputField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email,
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Email is required";
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildInputField(
                    controller: passwordController,
                    label: "Password",
                    icon: Icons.lock,
                    isObscure: _obscurePassword,
                    toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                    validator: (value) => (value == null || value.length < 6) ? "Password must be 6+ chars" : null,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  _buildInputField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    icon: Icons.lock,
                    isObscure: _obscureConfirmPassword,
                    toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    validator: (value) => value != passwordController.text ? "Passwords do not match" : null,
                  ),
                  const SizedBox(height: 16),

                  // Role Selector
                  // inside _buildRegisterCard builder
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "Join as",
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedRole = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: state is AuthLoading ? null : _handleRegister,
                      child: state is AuthLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Sign Up", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text("Already have an account? Log In", style: TextStyle(color: Colors.black54)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: toggleObscure != null
            ? IconButton(icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility), onPressed: toggleObscure)
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
    );
  }
  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      // Dispatching the event
      context.read<AuthBloc>().add(
        EmailRegisterEvent(
          emailController.text.trim(),
          passwordController.text.trim(),
          selectedRole,
        ),
      );
    }
  }


}


