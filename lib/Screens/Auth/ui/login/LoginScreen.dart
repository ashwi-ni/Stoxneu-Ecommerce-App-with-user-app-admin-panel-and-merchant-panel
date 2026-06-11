import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:country_picker/country_picker.dart';
import '../../../../core/themes/app_themes.dart';
import '../../../../features/dashboard/Admin_Panel/notifications/firebase_api.dart';
import '../../bloc/auth_bloc.dart';
import '../../bloc/auth_event.dart';
import '../../bloc/auth_state.dart';
import '../../repository/auth_repository.dart';
import '../../../../core/constants/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: "99164956670-hsmc5qf6attmfcie6lqi418cro9jc5j6.apps.googleusercontent.com",
  );

  bool isEmail = false;
  bool otpSent = false;
  bool _isGoogleLoading = false;

  Country selectedCountry = Country(
    phoneCode: "91", countryCode: "IN", e164Sc: 0, geographic: true, level: 1,
    name: "India", example: "8976541235", displayName: "India", displayNameNoCountryCode: "India", e164Key: "",
  );

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isPanel = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(authRepository),
        child: isPanel ? _buildSplitScreenPanel(context) : _buildMobileUserAppUI(context),
      ),
    );
  }

  Widget _buildSplitScreenPanel(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      child: Row(
        children: [

          // LEFT SIDE
          Expanded(
            flex: 6,
            child: Container(
              color:Color(0xFF111827),
              child: Stack(
                children: [

                  // TOP LEFT CONTENT (LOGO + TEXT)
                  Positioned(
                    top: 50,
                    right: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        SizedBox(
                          height: 80,
                          child: Image.asset(
                            "assets/images/brandlogo.png",
                            fit: BoxFit.contain,
                          ),
                        ),

                        const SizedBox(height: 80),

                        Text(
                          "Make Your Business",
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Profitable...",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color:AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 50),

                        // FEATURES ROW
                        Row(
                          children: const [
                            _FeatureItem(
                              icon: Icons.category,
                              text: "Wide Range\nof Products",
                            ),
                            SizedBox(width: 25),
                            _FeatureItem(
                              icon: Icons.lock,
                              text: "Secure\nTransactions",
                            ),
                            SizedBox(width: 25),
                            _FeatureItem(
                              icon: Icons.trending_up,
                              text: "Grow Your\nBusiness",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // BOTTOM RIGHT IMAGE
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: SizedBox(
                      height: 500,
                      child: Image.asset(
                        "assets/images/logincart.png",
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RIGHT SIDE (LOGIN)
          Expanded(
            flex: 4,
            child: Container(
              height: double.infinity,
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  child: _buildLoginCard(context, true),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileUserAppUI(BuildContext context) {
    return Container(
      width: double.infinity,
      // Use minHeight to ensure it covers the screen but allows scrolling
      constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
      color: Colors.white,
      child: SingleChildScrollView(
        // Add padding to keep content away from the status bar
        padding: const EdgeInsets.only(top: 60, bottom: 20),
        child: _buildLoginCard(context, false),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, bool isPanel) {
    final theme = Theme.of(context);

    // Define the core form content
    Widget loginContent = Container(
      constraints: BoxConstraints(
        maxWidth: isPanel ? 500 : double.infinity,
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 32,
          vertical: isPanel ? 40 : 0 // Add vertical padding inside the card for Panel
      ),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) async {
          // 1. Handle Successful Authentication
          if (state is AuthSuccess) {
            print("Authentication verified successfully. User ID: ${state.userId}, Role: ${state.role}");

            // 🔴 TRIGGER PUSH TOKEN SYNC IMMEDIATELY
            // This runs in the background using your newly validated session headers
            FirebaseApi.syncDeviceTokenWithIdentity();

            // Handle your app navigation based on your UserRole enum
            if (state.role == UserRole.admin) {
              context.go('/admin-dashboard');
            }
            else if (state.role == UserRole.merchant) {
              await context.read<AuthRepository>().loadMerchantStatus();
              await context.read<AuthRepository>().loadSubscriptionStatus();
              context.go('/');
            }
            else {
              context.go('/user-home');
            }
          }

          // 2. Handle Authentication Errors (Fixed from AuthFailure -> AuthError)
          else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message), // Fixed from state.error -> state.message
                backgroundColor: Colors.red,
              ),
            );
          }
        },

        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                otpSent ? "Enter OTP" : "Sign in",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Welcome back continue sign in!",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 30),
              _buildChoiceChips(),
              const SizedBox(height: 25),
              if (!otpSent && !isEmail) _buildPhoneInput(theme),
              if (!otpSent && isEmail) _buildEmailInput(theme),
              if (otpSent) _buildOtpInput(),
              const SizedBox(height: 30),
              _buildPrimaryButton(context, state),
              const SizedBox(height: 20),
              _buildGoogleButton(context, theme),
              const SizedBox(height: 25),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    // Apply Card ONLY for Panel
    return Center(
      child: isPanel
          ? Card(
        elevation: 10,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: loginContent,
      )
          : loginContent, // Flat for Mobile
    );
  }


  Widget _buildChoiceChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("Phone"), selected: !isEmail,
          onSelected: (_) => setState(() { isEmail = false; otpSent = false; }),
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text("Email"), selected: isEmail,
          onSelected: (_) => setState(() { isEmail = true; otpSent = false; }),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(ThemeData theme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => showCountryPicker(context: context, onSelect: (c) => setState(() => selectedCountry = c)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(14)),
            child: Text("+${selectedCountry.phoneCode}"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: "Phone Number",
              filled: true,
              fillColor:
              theme.inputDecorationTheme.fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),


    ],
    );
  }

  Widget _buildEmailInput(ThemeData theme) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return TextField(
      controller: otpController,
      decoration: InputDecoration(
        labelText: "OTP",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, AuthState state) {
    if (state is AuthLoading) return const Center(child: CircularProgressIndicator());
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
        onPressed: () {
          if (!otpSent && !isEmail) {
            context.read<AuthBloc>().add(SendOtpEvent('+${selectedCountry.phoneCode}${phoneController.text.trim()}'));
          } else if (isEmail) {
            context.read<AuthBloc>().add(EmailLoginEvent(emailController.text.trim(), passwordController.text.trim()));
          } else {
            context.read<AuthBloc>().add(VerifyOtpEvent('+${selectedCountry.phoneCode}${phoneController.text.trim()}', otpController.text.trim()));
          }
        },
        child: Text(otpSent ? "Verify OTP" : "Continue", style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context, ThemeData theme) {
    if (_isGoogleLoading) return const Center(child: CircularProgressIndicator());
    return ElevatedButton(
      onPressed: () async {
        setState(() => _isGoogleLoading = true);
        final googleUser = await _googleSignIn.signIn();
        if (!mounted) return;
        if (googleUser == null) {
          setState(() => _isGoogleLoading = false);
          return;
        }
        final googleAuth = await googleUser.authentication;
        final googleToken = googleAuth.idToken;
        if (googleToken != null) {
          context
              .read<AuthBloc>()
              .add(GoogleLoginEvent(googleToken));
        }
        if (mounted) setState(() => _isGoogleLoading = false);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.grey),
        ),
        minimumSize: const Size(double.infinity, 55),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/google.png",
              height: 20, width: 20),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              "Sign in with Google",
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? "),
        TextButton(onPressed: () => context.go('/register'), child: const Text("Sign Up")),
      ],
    );
  }
}
// FEATURE WIDGET
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}