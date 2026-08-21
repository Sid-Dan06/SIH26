import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import '../widgets/home_widgets.dart';
import '../services/api_service.dart';
import 'syllabus_screen.dart';
import 'terminal_screen.dart';
import 'lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = ApiService.userName;
  String recommendationReason =
      "Strengthen your Python list comprehension skills before moving to advanced data processing.";
  String recommendationTopic = "Python List Comprehensions";
  String recommendationSkill = "Python";
  double progressValue = 0.45;
  bool isGeneratingLesson = false;
  List<dynamic> history = [];

  @override
  void initState() {
    super.initState();
    loadLiveProgress();
  }

  Future<void> loadLiveProgress() async {
    try {
      final results = await Future.wait([
        ApiService.fetchProgress(),
        ApiService.fetchHistory(),
      ]);

      final data = results[0] as Map<String, dynamic>;
      final historyData = results[1] as List<dynamic>;

      if (data.isNotEmpty) {
        setState(() {
          userName = ApiService.userName;
          history = historyData;

          if (data.containsKey('recommendation') &&
              data['recommendation'] != null) {
            recommendationReason =
                data['recommendation']['reason'] ?? recommendationReason;
            recommendationTopic =
                data['recommendation']['topic'] ?? recommendationTopic;
            recommendationSkill =
                data['recommendation']['skill'] ?? recommendationSkill;
          }

          if (data.containsKey('skill_profile')) {
            final profile = data['skill_profile'] as Map<String, dynamic>;

            if (profile.containsKey(recommendationSkill)) {
              final topics =
                  profile[recommendationSkill] as Map<String, dynamic>;

              if (topics.isNotEmpty) {
                double sum = 0;

                topics.forEach((key, value) {
                  sum += (value['mastery'] ?? 50.0);
                });

                progressValue = (sum / topics.length) / 100;
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> openAiLessonModal() async {
    setState(() => isGeneratingLesson = true);

    try {
      final content = await ApiService.generateContent(
        skill: recommendationSkill,
        topic: recommendationTopic,
        difficulty: 'Beginner',
        contentType: 'lesson_with_quiz',
        reason: recommendationReason,
      );

      setState(() => isGeneratingLesson = false);
      _showLessonDialog(content);
    } catch (e) {
      setState(() => isGeneratingLesson = false);
      _showFallbackLessonDialog();
    }
  }

  void _showLessonDialog(String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
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
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.purple,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendationTopic,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Complete Lesson 🎉',
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    navigator.pop();

                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Updating mastery & loading next recommendation...',
                        ),
                        backgroundColor: AppColors.purple,
                      ),
                    );

                    try {
                      await ApiService.completeLearningSession(
                        skill: recommendationSkill,
                        topic: recommendationTopic,
                        quizCorrect: 5,
                        quizTotal: 5,
                        timeTakenSeconds: 120.0,
                      );

                      await loadLiveProgress();

                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Mastery updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Failed to update progress: $e'),
                          backgroundColor: AppColors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFallbackLessonDialog() {
    _showLessonDialog(
      'List comprehensions provide a concise way to create lists in Python. Syntax: [expression for item in iterable].\n\n'
      '# Example:\n'
      'squares = [x**2 for x in range(10)]\n'
      'print(squares)',
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Welcome back, $userName',
            subtitle: 'Your personalized learning dashboard.',
          ),
          const SizedBox(height: 18),

          // Learning Quick Stats Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 12,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const _StatItem(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: Color(0xFFFF6B4A),
                  title: '5 Days',
                  subtitle: 'Streak',
                ),
                _divider(),
                const _StatItem(
                  icon: Icons.bolt_rounded,
                  iconColor: AppColors.yellow,
                  title: '1,450 XP',
                  subtitle: 'Earned',
                ),
                _divider(),
                _StatItem(
                  icon: Icons.track_changes_rounded,
                  iconColor: AppColors.green,
                  title: '${(progressValue * 100).toInt()}%',
                  subtitle: 'Mastery',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Active Learning Track Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Pill(
                      text: 'ACTIVE MODULE',
                      background: AppColors.lavender,
                      foreground: AppColors.purple,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(progressValue * 100).toInt()}% In Progress',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recommendationTopic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Skill Track: $recommendationSkill Mastery Course',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 14),
                ProgressBar(value: progressValue),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progressValue * 100).toInt()}% Completed',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                    Text(
                      '${SyllabusData.topicsBySkill[recommendationSkill]?.length ?? 0} Total Topics',
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Continue Learning',
                        icon: Icons.play_arrow_rounded,
                        onPressed: openAiLessonModal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              backgroundColor: AppColors.page,
                              body: SafeArea(
                                child: SyllabusScreen(),
                              ),
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View Syllabus',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Learning & Practice Hub (2x2 Grid)
          const SectionTitle(title: 'Learning & Practice Hub'),
          const SizedBox(height: 12),
          SizedBox(
            height: 115,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _HubTile(
                    icon: Icons.terminal_rounded,
                    iconBg: AppColors.lavender,
                    iconColor: AppColors.purple,
                    title: 'Terminal',
                    subtitle: 'Live Python sandbox',
                    badge: 'Practice',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          backgroundColor: AppColors.page,
                          body: SafeArea(
                            child: TerminalScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HubTile(
                    icon: Icons.auto_awesome,
                    iconBg: const Color(0xFFFFE6E9),
                    iconColor: const Color(0xFFE95B67),
                    title: 'Lesson Studio',
                    subtitle: 'AI micro-lessons',
                    badge: 'AI Powered',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          backgroundColor: AppColors.page,
                          body: SafeArea(
                            child: LessonScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const SectionTitle(title: 'Pro Tip of the Day'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.yellow,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Python List Comprehensions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                // Code Pro-Tip Snippet Card
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E4F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '# Create a filtered squares list:\nsquares = [x**2 for x in range(10) if x % 2 == 0]\nprint(squares)  # [0, 4, 16, 36, 64]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      color: Color(0xFFD4D0FF),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const Scaffold(
                        backgroundColor: AppColors.page,
                        body: SafeArea(
                          child: TerminalScreen(),
                        ),
                      ),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Try in Sandbox Terminal →',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Recent Sessions
          const SectionTitle(title: 'Recent Sessions'),
          const SizedBox(height: 12),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'No learning sessions recorded yet. Start a lesson or take a quiz!',
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppColors.muted,
                ),
              ),
            )
          else
            ...history.take(5).map(
                  (s) => _SessionTile(session: s),
                ),

          const SizedBox(height: 22),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 28,
        width: 1,
        color: AppColors.border,
      );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.text,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 8.5,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onTap;

  const _HubTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
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
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.muted,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _TrackCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 28,
        width: 1,
        color: AppColors.border,
      );
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
            child: const Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppColors.purple,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$skill • $topic',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (correct != null && total != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Scored $correct/$total',
                      style: const TextStyle(
                        fontSize: 8.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

