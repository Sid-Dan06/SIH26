import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import '../widgets/home_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Welcome back, Alex',
            subtitle: 'Your adaptive learning journey continues.',
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x09000000),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Pill(
                      text: 'CURRENT STEP',
                      background: AppColors.lavender,
                      foreground: AppColors.purple,
                    ),
                    Spacer(),
                    Text(
                      '45%',
                      style: TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Python for Data Science',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Module 4 • Functions & Data Structures',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                const ProgressBar(value: .45),
                const SizedBox(height: 9),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('45% Completed',
                        style: TextStyle(fontSize: 9, color: AppColors.muted)),
                    Text('12/28 Lessons',
                        style: TextStyle(fontSize: 9, color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Continue Learning',
                        icon: Icons.play_arrow_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Syllabus',
                          style: TextStyle(fontSize: 10, color: AppColors.text),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const SectionTitle(title: 'Adaptive Recommendation'),
          const SizedBox(height: 9),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FF), Color(0xFFF7F4FF)],
              ),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFDCD5FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.purple, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recommendation',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Strengthen your Python list comprehension skills before moving to advanced data processing.',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.text,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Start Micro-Lesson →',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const SectionTitle(title: 'Daily Goal', action: 'Reset 12:30'),
          const SizedBox(height: 9),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 62,
                  height: 62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const CircularProgressIndicator(
                        value: .45,
                        strokeWidth: 7,
                        backgroundColor: Color(0xFFE8E7F0),
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.purple),
                      ),
                      const Text(
                        '45',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keep your streak alive!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '15 mins remaining to hit your goal.',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          const SectionTitle(title: 'Up Next'),
          const SizedBox(height: 9),
          const UpNextTile(
            icon: Icons.quiz_outlined,
            title: 'Data Cleaning Quiz',
            subtitle: 'Due in 2 days',
          ),
          const UpNextTile(
            icon: Icons.psychology_outlined,
            title: 'Python Skills Analysis',
            subtitle: 'AI review pending',
          ),
        ],
      ),
    );
  }
}
