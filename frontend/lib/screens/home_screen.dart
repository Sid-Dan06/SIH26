import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_title.dart';
import '../services/api_service.dart';
import 'syllabus_screen.dart';
import 'terminal_screen.dart';
import 'lesson_screen.dart';
import 'quiz_screen.dart';

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

  @override
  void initState() {
    super.initState();
    loadLiveProgress();
  }

  Future<void> loadLiveProgress() async {
    try {
      final data = await ApiService.fetchProgress();
      if (data.isNotEmpty) {
        setState(() {
          userName = ApiService.userName;
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
              final topics = profile[recommendationSkill] as Map<String, dynamic>;
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
                    const Icon(Icons.auto_awesome,
                        color: AppColors.purple, size: 22),
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
                        fontSize: 11.5, color: AppColors.text, height: 1.5),
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
                        content: Text('Updating mastery & loading next recommendation...'),
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
      'print(squares)'
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                ProgressBar(value: progressValue),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progressValue * 100).toInt()}% Completed',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                    Text(
                      '${SyllabusData.topicsBySkill[recommendationSkill]?.length ?? 0} Total Topics',
                      style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
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
                              body: SafeArea(child: SyllabusScreen()),
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'View Syllabus',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.text),
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
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _HubTile(
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
                      body: SafeArea(child: TerminalScreen()),
                    ),
                  ),
                ),
              ),
              _HubTile(
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
                      body: SafeArea(child: LessonScreen()),
                    ),
                  ),
                ),
              ),
              _HubTile(
                icon: Icons.quiz_rounded,
                iconBg: AppColors.yellowBg,
                iconColor: const Color(0xFF8A6A00),
                title: 'Quick Quiz',
                subtitle: 'Test your skills',
                badge: 'Assessment',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      backgroundColor: AppColors.page,
                      body: SafeArea(child: QuizScreen()),
                    ),
                  ),
                ),
              ),
              _HubTile(
                icon: Icons.menu_book_rounded,
                iconBg: AppColors.greenBg,
                iconColor: AppColors.green,
                title: 'Syllabus',
                subtitle: 'Browse all tracks',
                badge: 'Curriculum',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(
                      backgroundColor: AppColors.page,
                      body: SafeArea(child: SyllabusScreen()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Popular Learning Tracks
          const SectionTitle(title: 'Curriculum Tracks'),
          const SizedBox(height: 12),
          _TrackCard(
            title: 'Python Programming Track',
            subtitle: '8 topics • Variables, Functions, Loops & OOP',
            icon: Icons.code_rounded,
            color: AppColors.purple,
            bg: AppColors.lavender,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Scaffold(
                  backgroundColor: AppColors.page,
                  body: SafeArea(child: SyllabusScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _TrackCard(
            title: 'SQL & Database Architecture',
            subtitle: '8 topics • CRUD, JOINs, Group By & Subqueries',
            icon: Icons.storage_rounded,
            color: AppColors.green,
            bg: AppColors.greenBg,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Scaffold(
                  backgroundColor: AppColors.page,
                  body: SafeArea(child: SyllabusScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _TrackCard(
            title: 'Linux & Command Line Tools',
            subtitle: '5 topics • File system, permissions & scripts',
            icon: Icons.terminal_outlined,
            color: const Color(0xFFE95B67),
            bg: const Color(0xFFFFE6E9),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Scaffold(
                  backgroundColor: AppColors.page,
                  body: SafeArea(child: SyllabusScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Code Pro-Tip Snippet Card
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
                    Icon(Icons.lightbulb_outline_rounded, color: AppColors.yellow, size: 18),
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
                        body: SafeArea(child: TerminalScreen()),
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
