import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'lesson_screen.dart';

class SyllabusScreen extends StatefulWidget {
  final String? expandedSkill;

  const SyllabusScreen({super.key, this.expandedSkill});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  bool loading = true;
  Map<String, Map<String, double>> mastery = {};

  @override
  void initState() {
    super.initState();
    loadSyllabus();
  }

  Future<void> loadSyllabus() async {
    try {
      final data = await ApiService.fetchProgress();
      final profile = (data['skill_profile'] as Map?) ?? {};
      final parsed = <String, Map<String, double>>{};
      profile.forEach((skill, topics) {
        final topicMap = <String, double>{};
        (topics as Map).forEach((topic, value) {
          topicMap[topic] = (value['mastery'] ?? 0).toDouble();
        });
        parsed[skill] = topicMap;
      });
      if (mounted) setState(() => mastery = parsed);
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double _masteryFor(String skill, String topic) {
    return (mastery[skill]?[topic] ?? 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.text, size: 22),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AppShell()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: AppHeader(
                      title: 'Curriculum & Syllabus',
                      subtitle:
                          'Tap any topic to launch its AI lesson directly.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...SyllabusData.topicsBySkill.entries.map((entry) {
                final skill = entry.key;
                final topics = entry.value;
                final isInitiallyExpanded = widget.expandedSkill == null ||
                    widget.expandedSkill == skill;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: isInitiallyExpanded,
                    title: Text(
                      skill,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text),
                    ),
                    subtitle: Text('${topics.length} Modules',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.muted)),
                    children: topics.map((topic) {
                      final m = _masteryFor(skill, topic);
                      return ListTile(
                        title: Text(topic,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            ProgressBar(value: m / 100),
                            const SizedBox(height: 2),
                            Text(
                                m > 0 ? '${m.round()}% Mastery' : 'Not Started',
                                style: const TextStyle(
                                    fontSize: 9, color: AppColors.muted)),
                          ],
                        ),
                        trailing: const Icon(Icons.play_circle_outline_rounded,
                            color: AppColors.purple, size: 22),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LessonScreen(
                                initialSkill: skill,
                                initialTopic: topic,
                                initialDifficulty: 'Beginner',
                                autoGenerate: true,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
