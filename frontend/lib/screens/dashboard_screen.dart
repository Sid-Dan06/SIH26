import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/section_title.dart';
import '../services/api_service.dart';
import 'terminal_screen.dart';
import 'syllabus_screen.dart';
import 'lesson_screen.dart';
import 'quiz_generator_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool loading = true;
  Map<String, dynamic> skillProfile = {};
  List<dynamic> history = [];
  List<dynamic> quizHistory = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final results = await Future.wait([
        ApiService.fetchProgress(),
        ApiService.fetchHistory(),
        ApiService.fetchQuizHistory(),
      ]);
      final progress = results[0] as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          skillProfile = (progress['skill_profile'] as Map?)
                  ?.cast<String, dynamic>() ??
              {};
          history = results[1] as List<dynamic>;
          quizHistory = results[2] as List<dynamic>;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  double _overallMastery() {
    if (skillProfile.isEmpty) return 0;
    double total = 0;
    int count = 0;
    skillProfile.forEach((skill, topics) {
      (topics as Map).forEach((topic, value) {
        total += (value['mastery'] ?? 0).toDouble();
        count++;
      });
    });
    return count == 0 ? 0 : total / count;
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallMastery();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Dashboard, ${ApiService.userName}',
            subtitle: 'Everything about your training, in one place.',
          ),
          const SizedBox(height: 18),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Overall Mastery',
                    value: '${overall.toInt()}%',
                    icon: Icons.insights_rounded,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Sessions Logged',
                    value: '${history.length}',
                    icon: Icons.history_rounded,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Quiz Attempts',
                    value: '${quizHistory.length}',
                    icon: Icons.quiz_rounded,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Tools'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _ToolTile(
                  icon: Icons.terminal_rounded,
                  title: 'Terminal',
                  subtitle: 'Run Python code',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _ScaffoldWrap(child: TerminalScreen()))),
                ),
                _ToolTile(
                  icon: Icons.menu_book_rounded,
                  title: 'Syllabus',
                  subtitle: 'Browse curriculum',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _ScaffoldWrap(child: SyllabusScreen()))),
                ),
                _ToolTile(
                  icon: Icons.auto_awesome,
                  title: 'Lessons',
                  subtitle: 'Generate a lesson',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _ScaffoldWrap(child: LessonScreen()))),
                ),
                _ToolTile(
                  icon: Icons.quiz_rounded,
                  title: 'Quiz Generator',
                  subtitle: 'AI practice quiz',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const _ScaffoldWrap(child: QuizGeneratorScreen()))),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Skill Breakdown'),
            const SizedBox(height: 10),
            if (skillProfile.isEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Take the pre-assessment quiz to build your skill profile.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
              )
            else
              ...skillProfile.entries.map((e) => _SkillMiniRow(
                    skill: e.key,
                    topics: (e.value as Map).cast<String, dynamic>(),
                  )),
            const SizedBox(height: 20),
            const SectionTitle(title: 'Recent Sessions'),
            const SizedBox(height: 10),
            if (history.isEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'No learning sessions recorded yet.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
              )
            else
              ...history.take(5).map((s) => _SessionTile(session: s)),
          ],
        ],
      ),
    );
  }
}

/// Wraps a pushed screen with its own Scaffold + back button, since the
/// tab screens are normally rendered inside AppShell's SafeArea directly.
class _ScaffoldWrap extends StatelessWidget {
  final Widget child;
  const _ScaffoldWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(child: child),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 8.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.purple, size: 17),
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 8.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _SkillMiniRow extends StatelessWidget {
  final String skill;
  final Map<String, dynamic> topics;

  const _SkillMiniRow({required this.skill, required this.topics});

  @override
  Widget build(BuildContext context) {
    double avg = 0;
    if (topics.isNotEmpty) {
      double sum = 0;
      topics.forEach((_, v) => sum += (v['mastery'] ?? 0).toDouble());
      avg = sum / topics.length;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(skill,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          Text('${avg.toInt()}%',
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.purple)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final dynamic session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final skill = session['skill']?.toString() ?? '';
    final topic = session['topic']?.toString() ?? '';
    final correct = session['quiz_correct'];
    final total = session['quiz_total'];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.check_circle_outline,
                size: 16, color: AppColors.purple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$skill • $topic',
                    style: const TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w800)),
                if (correct != null && total != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text('Scored $correct/$total',
                        style: const TextStyle(
                            fontSize: 8.5, color: AppColors.muted)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
