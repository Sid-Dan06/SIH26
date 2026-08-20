import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'progress_bar.dart';

class PathModule extends StatelessWidget {
  final bool completed;
  final bool current;
  final String title;
  final String subtitle;
  final double progress;
  final String status;
  final IconData icon;

  const PathModule({
    super.key,
    this.completed = false,
    this.current = false,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = completed
        ? AppColors.greenBg
        : current
            ? AppColors.lavender
            : Colors.white;

    final iconColor = completed
        ? AppColors.green
        : current
            ? AppColors.purple
            : AppColors.muted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: current ? const Color(0xFFD6D0FF) : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                    if (completed)
                      const Icon(Icons.check_circle,
                          size: 15, color: AppColors.green),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 8.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 9),
                ProgressBar(value: progress, height: 5),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 8,
                        color: iconColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
