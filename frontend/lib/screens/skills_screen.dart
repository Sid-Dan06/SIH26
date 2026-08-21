import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/section_title.dart';
import '../widgets/skill_widgets.dart';
import '../services/api_service.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  double pythonScore = 0.86;
  double sqlScore = 0.61;
  double gitScore = 0.74;
  double linuxScore = 0.45;

  @override
  void initState() {
    super.initState();
    loadLiveSkills();
  }

  Future<void> loadLiveSkills() async {
    try {
      final data = await ApiService.fetchProgress();
      if (data.containsKey('skill_profile')) {
        final profile = data['skill_profile'];
        setState(() {
          if (profile.containsKey('Python')) {
            pythonScore = _avgSkill(profile['Python']) / 100;
          }
          if (profile.containsKey('SQL')) {
            sqlScore = _avgSkill(profile['SQL']) / 100;
          }
          if (profile.containsKey('Git')) {
            gitScore = _avgSkill(profile['Git']) / 100;
          }
          if (profile.containsKey('Linux')) {
            linuxScore = _avgSkill(profile['Linux']) / 100;
          }
        });
      }
    } catch (_) {}
  }

  double _avgSkill(Map<String, dynamic> topics) {
    if (topics.isEmpty) return 50.0;
    double sum = 0;
    topics.forEach((key, value) {
      sum += (value['mastery'] ?? 50.0);
    });
    return sum / topics.length;
  }

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
            child: Column(
              children: [
                const Row(
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
                const SizedBox(height: 16),
                SkillRow(
                    name: 'Python',
                    value: pythonScore,
                    score: '${(pythonScore * 100).toInt()}%'),
                SkillRow(
                    name: 'SQL',
                    value: sqlScore,
                    score: '${(sqlScore * 100).toInt()}%'),
                SkillRow(
                    name: 'Git',
                    value: gitScore,
                    score: '${(gitScore * 100).toInt()}%'),
                SkillRow(
                    name: 'Linux',
                    value: linuxScore,
                    score: '${(linuxScore * 100).toInt()}%'),
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
            text:
                'SQL optimization and Python fundamentals are currently performing well.',
          ),
          const InsightCard(
            color: AppColors.yellowBg,
            icon: Icons.warning_amber_rounded,
            title: 'Skill Gaps',
            text:
                'Linux permissions and advanced Git workflows need reinforcement.',
          ),
          const InsightCard(
            color: Color(0xFFFFE7D8),
            icon: Icons.auto_awesome,
            title: 'Advanced AI Merge',
            text:
                'Suggested next topics combine Git and Linux to improve practical workflow skills.',
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
