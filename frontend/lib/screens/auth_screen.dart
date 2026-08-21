import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLoginMode = true;
  bool isLoading = false;
  String? errorText;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> handleAuth() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (isLoginMode) {
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          errorText = "Please fill in all fields.";
          isLoading = false;
        });
        return;
      }

      ApiService.isGuestTestingMode = false;
      final success = await ApiService.login(email, password);
      if (success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppShell()),
          );
        }
      } else {
        setState(() {
          errorText = "Invalid login credentials.";
          isLoading = false;
        });
      }
    } else {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        setState(() {
          errorText = "Please fill in all fields.";
          isLoading = false;
        });
        return;
      }
      if (password.length < 8) {
        setState(() {
          errorText = "Password must be at least 8 characters.";
          isLoading = false;
        });
        return;
      }

      ApiService.isGuestTestingMode = false;
      final success = await ApiService.register(username, email, password);
      if (success) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AppShell()),
          );
        }
      } else {
        setState(() {
          errorText = "Registration failed. Username or email may already exist.";
          isLoading = false;
        });
      }
    }
  }

  void continueAsGuest() {
    ApiService.isGuestTestingMode = true;
    ApiService.userToken = null;
    ApiService.userId = 1;
    ApiService.userName = "Guest User";
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.lavender,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.purple,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              // App Title
              const Text(
                'DevPulse AI',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Adaptive Training Platform',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 32),
              // Auth Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode Toggle (Login / Sign Up tabs)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              isLoginMode = true;
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: isLoginMode
                                        ? AppColors.purple
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isLoginMode
                                      ? AppColors.text
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              isLoginMode = false;
                              errorText = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: !isLoginMode
                                        ? AppColors.purple
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Sign Up',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: !isLoginMode
                                      ? AppColors.text
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Username input (Sign-Up only)
                    if (!isLoginMode) ...[
                      const Text(
                        'USERNAME',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. janesmith',
                          hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                          filled: true,
                          fillColor: AppColors.page,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(fontSize: 12, color: AppColors.text),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Email or Login input
                    Text(
                      isLoginMode ? 'USERNAME OR EMAIL' : 'EMAIL ADDRESS',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: isLoginMode ? 'username or email' : 'name@example.com',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.page,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 12, color: AppColors.text),
                    ),
                    const SizedBox(height: 16),
                    // Password input
                    const Text(
                      'PASSWORD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.page,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(fontSize: 12, color: AppColors.text),
                    ),
                    const SizedBox(height: 16),
                    // Error message
                    if (errorText != null) ...[
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Action button
                    SizedBox(
                      height: 44,
                      child: PrimaryButton(
                        text: isLoading
                            ? 'Processing...'
                            : (isLoginMode ? 'Login' : 'Create Account'),
                        onPressed: isLoading ? null : handleAuth,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Guest Bypass
              TextButton(
                onPressed: continueAsGuest,
                child: const Text(
                  'Continue as Guest (No login required)',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
