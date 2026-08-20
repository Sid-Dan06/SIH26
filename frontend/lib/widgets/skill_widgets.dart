import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'progress_bar.dart';

class SkillRow extends StatelessWidget {
  final String name;
  final double value;
  final String score;

  const SkillRow({
    super.key,
    required this.name,
    required this.value,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(child: ProgressBar(value: value)),
          const SizedBox(width: 9),
          SizedBox(
            width: 29,
            child: Text(
              score,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String text;

  const InsightCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.text),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 3),
                Text(text,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.text,
                      height: 1.35,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendationTile extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const RecommendationTile({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.lavender,
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.purple,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.muted,
                    )),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppColors.purple),
        ],
      ),
    );
  }
}
