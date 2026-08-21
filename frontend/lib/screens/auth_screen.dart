import 'package:flutter/material.dart';
import 'login_screen.dart';

// Backward compatibility export / redirect
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen();
  }
}
