import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final double value;
  final double height;

  const ProgressBar({
    super.key,
    required this.value,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: const Color(0xFFE7E6F0),
        valueColor: const AlwaysStoppedAnimation(AppColors.purple),
      ),
    );
  }
}
