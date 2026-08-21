import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/skills_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/path_screen.dart';
import 'screens/dashboard_screen.dart';
import 'widgets/app_bottom_nav.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AdaptiveIntelligenceApp());
}

class AdaptiveIntelligenceApp extends StatelessWidget {
  const AdaptiveIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Adaptive Intelligence',
      theme: AppTheme.lightTheme,
      home: const AppShell(),
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
    SkillsScreen(),
    QuizScreen(),
    PathScreen(),
    DashboardScreen(),
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
