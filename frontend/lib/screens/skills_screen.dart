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
  double pythonScore = 0.0;
  double sqlScore = 0.0;
  double gitScore = 0.0;
  double linuxScore = 0.0;

  @override
  void initState() {
    super.initState();
    loadLiveSkills();
  }

  Future<void> loadLiveSkills() async {
    try {
      final data = await ApiService.fetchProgress();
      if (data.containsKey('skill_profile')) {
        final profile = data['skill_profile'] as Map<String, dynamic>;
        setState(() {
          pythonScore = profile.containsKey('Python')
              ? _avgSkill(profile['Python']) / 100
              : 0.0;

          sqlScore = profile.containsKey('SQL')
              ? _avgSkill(profile['SQL']) / 100
              : 0.0;

          gitScore = profile.containsKey('Git')
              ? _avgSkill(profile['Git']) / 100
              : 0.0;

          linuxScore = profile.containsKey('Linux')
              ? _avgSkill(profile['Linux']) / 100
              : 0.0;
        });
      }
    } catch (_) {}
  }

  double _avgSkill(Map<String, dynamic> topics) {
    if (topics.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    topics.forEach((_, value) {
      if (value is Map && value.containsKey('mastery')) {
        sum += (value['mastery'] as num).toDouble();
        count++;
      }
    });
    return count > 0 ? (sum / count) : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Skills Matrix',
            subtitle: 'Real-time breakdown of proficiency across skills.',
          ),
          const SizedBox(height: 18),
          const SectionTitle(title: 'Proficiency by Language & Tool'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                SkillRow(
                  name: 'Python',
                  value: pythonScore,
                  score: '${(pythonScore * 100).round()}%',
                ),
                SkillRow(
                  name: 'SQL',
                  value: sqlScore,
                  score: '${(sqlScore * 100).round()}%',
                ),
                SkillRow(
                  name: 'Git',
                  value: gitScore,
                  score: '${(gitScore * 100).round()}%',
                ),
                SkillRow(
                  name: 'Linux',
                  value: linuxScore,
                  score: '${(linuxScore * 100).round()}%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
