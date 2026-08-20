import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/section_title.dart';
import '../widgets/skill_widgets.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Skills Profile',
            subtitle: 'Real-time analysis of your technical proficiency.',
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Proficiency Matrix',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Live Analysis',
                      style: TextStyle(
                        color: AppColors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                SkillRow(name: 'Python', value: .86, score: '86%'),
                SkillRow(name: 'SQL', value: .61, score: '61%'),
                SkillRow(name: 'Git', value: .74, score: '74%'),
                SkillRow(name: 'Linux', value: .45, score: '45%'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const SectionTitle(title: 'AI Assessment'),
          const SizedBox(height: 9),

          const InsightCard(
            color: AppColors.greenBg,
            icon: Icons.check_circle_outline,
            title: 'Strong Areas',
            text: 'SQL optimization and Python fundamentals are currently performing well.',
          ),
          const InsightCard(
            color: AppColors.yellowBg,
            icon: Icons.warning_amber_rounded,
            title: 'Skill Gaps',
            text: 'Linux permissions and advanced Git workflows need reinforcement.',
          ),
          const InsightCard(
            color: Color(0xFFFFE7D8),
            icon: Icons.auto_awesome,
            title: 'Advanced AI Merge',
            text: 'Suggested next topics combine Git and Linux to improve practical workflow skills.',
          ),

          const SizedBox(height: 16),
          const SectionTitle(title: 'Recommended Next Steps'),
          const SizedBox(height: 9),

          const RecommendationTile(
            number: '01',
            title: 'Bash Mastery Path',
            subtitle: 'Targeted module to improve Linux automation skills.',
          ),
          const RecommendationTile(
            number: '02',
            title: 'Git Conflict Simulator',
            subtitle: 'Interactive practice for advanced merge scenarios.',
          ),
        ],
      ),
    );
  }
}
