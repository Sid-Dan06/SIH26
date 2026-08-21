import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/progress_bar.dart';
import '../services/api_service.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

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
          const AppHeader(
            title: 'Syllabus',
            subtitle: 'Full curriculum across every tracked skill.',
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
  final double Function(String topic) masteryFor;

  const _SkillSection({
    required this.skill,
    required this.topics,
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
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 15),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 14),
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_icon, color: AppColors.purple, size: 18),
          ),
          title: Text(
            skill,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.text,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${topics.length} topics • ${avg.toInt()}% average mastery',
              style: const TextStyle(fontSize: 9, color: AppColors.muted),
            ),
          ),
          children: topics
              .map((topic) => _TopicRow(topic: topic, value: masteryFor(topic)))
              .toList(),
        ),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final String topic;
  final double value;

  const _TopicRow({required this.topic, required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0, 100);
    final done = pct >= 70;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 15,
            color: done ? AppColors.green : AppColors.muted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                ProgressBar(value: pct / 100, height: 5),
              ],
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 30,
            child: Text(
              '${pct.toInt()}%',
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
