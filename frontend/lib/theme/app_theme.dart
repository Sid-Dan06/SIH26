import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF11113D);
  static const purple = Color(0xFF4937E8);
  static const purple2 = Color(0xFF6B55FF);
  static const lavender = Color(0xFFF0EEFF);
  static const page = Color(0xFFF7F7FB);
  static const text = Color(0xFF20203D);
  static const muted = Color(0xFF777791);
  static const green = Color(0xFF16A86B);
  static const greenBg = Color(0xFFDDF8EB);
  static const yellow = Color(0xFFFFB72B);
  static const yellowBg = Color(0xFFFFF2CF);
  static const red = Color(0xFFE95B67);
  static const border = Color(0xFFE5E5EF);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.page,
      fontFamily: 'Arial',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        brightness: Brightness.light,
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // Removes the Material 3 stretch overscroll effect across all platforms
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Provides smooth natural scrolling without visual stretching/distortions
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
