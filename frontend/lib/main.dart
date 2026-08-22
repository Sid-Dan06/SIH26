import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/terminal_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'widgets/app_bottom_nav.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }
  runApp(const AdaptiveIntelligenceApp());
}

class AdaptiveIntelligenceApp extends StatelessWidget {
  const AdaptiveIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DevPulse AI',
      theme: AppTheme.lightTheme,
      scrollBehavior: const AppScrollBehavior(),
      home: AuthService.isAuthenticated ? const AppShell() : const LoginScreen(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final screens = const [
    HomeScreen(),
    TerminalScreen(),
    QuizScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: screens[index]),
      bottomNavigationBar: AppBottomNav(
        index: index,
        onChanged: (value) => setState(() => index = value),
      ),
    );
  }
}