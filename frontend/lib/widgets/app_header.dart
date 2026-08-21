import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showLogo;

  const AppHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLogo) ...[
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: AppColors.purple, size: 17),
                    SizedBox(width: 6),
                    Text(
                      'DevPulse AI',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
