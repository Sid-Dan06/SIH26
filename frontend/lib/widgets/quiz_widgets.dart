import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AnswerOption extends StatelessWidget {
  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  const AnswerOption({
    super.key,
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color background = Colors.white;
    Color border = AppColors.border;
    Color iconColor = AppColors.muted;

    if (selected) {
      background = AppColors.lavender;
      border = AppColors.purple;
      iconColor = AppColors.purple;
    }
    if (correct) {
      background = AppColors.greenBg;
      border = AppColors.green;
      iconColor = AppColors.green;
    }
    if (wrong) {
      background = const Color(0xFFFFE6E9);
      border = AppColors.red;
      iconColor = AppColors.red;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(
              selected || correct
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 17,
              color: iconColor,
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: AppColors.text,
              ),
            ),
            const Spacer(),
            if (correct)
              const Icon(Icons.check_circle,
                  size: 15, color: AppColors.green),
            if (wrong)
              const Icon(Icons.cancel, size: 15, color: AppColors.red),
          ],
        ),
      ),
    );
  }
}
