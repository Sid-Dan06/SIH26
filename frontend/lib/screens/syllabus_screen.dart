import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';
import 'lesson_screen.dart';
import 'terminal_screen.dart';
import 'quiz_generator_screen.dart';

class SyllabusScreen extends StatefulWidget {
  final String? expandedSkill;

  const SyllabusScreen({super.key, this.expandedSkill});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  bool loading = true;

  // skill -> topic -> mastery (0-100)
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
      // fall back to unassessed topics below
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double _masteryFor(String skill, String topic) {
    return (mastery[skill]?[topic] ?? 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              const Expanded(
                child: AppHeader(
                  title: 'Curriculum & Syllabus',
                  subtitle: 'Tap any topic to launch its AI lesson directly.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              ),
            )
          else
            ...SyllabusData.topicsBySkill.entries.map(
              (entry) => _SkillSection(
                skill: entry.key,
                topics: entry.value,
                initiallyExpanded: widget.expandedSkill == null || widget.expandedSkill == entry.key,
                masteryFor: (topic) => _masteryFor(entry.key, topic),
              ),
            ),
        ],
      ),
    );
  }
}

class _SkillSection extends StatelessWidget {
  final String skill;
  final List<String> topics;
  final bool initiallyExpanded;
  final double Function(String topic) masteryFor;

  const _SkillSection({
    required this.skill,
    required this.topics,
    this.initiallyExpanded = false,
    required this.masteryFor,
  });

  IconData get _icon {
    switch (skill) {
      case 'Python':
        return Icons.code_rounded;
      case 'SQL':
        return Icons.storage_rounded;
      case 'Git':
        return Icons.merge_type_rounded;
      case 'Linux':
        return Icons.terminal_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avg = topics.isEmpty
        ? 0.0
        : topics.map(masteryFor).reduce((a, b) => a + b) / topics.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppColors.purple, size: 20),
          ),
          title: Text(
            skill,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.text,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${topics.length} topics • ${avg.toInt()}% average mastery',
              style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
            ),
          ),
          children: topics
              .map((topic) => _TopicRow(
                    skill: skill,
                    topic: topic,
                    value: masteryFor(topic),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String skill;
  final String topic;
  final double value;

  const _TopicRow({
    required this.skill,
    required this.topic,
    required this.value,
  });

  void _openLesson(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.page,
          body: SafeArea(
            child: LessonScreen(
              initialSkill: skill,
              initialTopic: topic,
              autoGenerate: true,
            ),
          ),
        ),
      ),
    );
  }

  void _showTopicOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  'Track: $skill • Current Mastery: ${value.toInt()}%',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.purple, size: 20),
                  ),
                  title: const Text(
                    'Launch AI Micro-Lesson',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                  subtitle: const Text(
                    'Generate interactive explanation, syntax & examples',
                    style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.muted),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openLesson(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.yellowBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.quiz_rounded, color: Color(0xFF8A6A00), size: 20),
                  ),
                  title: const Text(
                    'Generate Topic Quiz',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text),
                  ),
                  subtitle: const Text(
                    'Take a quick targeted assessment test',
                    style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.muted),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          backgroundColor: AppColors.page,
                          body: SafeArea(child: QuizGeneratorScreen()),
                        ),
                      ),
                    );
                  },
                ),
                if (skill == 'Python' || skill == 'Linux')
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.greenBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.terminal_rounded, color: AppColors.green, size: 20),
                    ),
                    title: const Text(
                      'Open in Code Sandbox',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                    subtitle: const Text(
                      'Practice syntax live in the interactive terminal',
                      style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.muted),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            backgroundColor: AppColors.page,
                            body: SafeArea(child: TerminalScreen()),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0, 100);
    final done = pct >= 70;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openLesson(context),
          onLongPress: () => _showTopicOptions(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  size: 16,
                  color: done ? AppColors.green : AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 5),
                      ProgressBar(value: pct / 100, height: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, color: AppColors.purple, size: 13),
                      SizedBox(width: 2),
                      Text(
                        'Lesson',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded, size: 16, color: AppColors.muted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showTopicOptions(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
