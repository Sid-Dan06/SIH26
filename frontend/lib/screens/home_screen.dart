import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
          }
        });
      }
    } catch (_) {}
  }

  Future<void> openAiLessonModal() async {
    setState(() => isGeneratingLesson = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/generate-content'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topic': recommendationTopic,
          'target_difficulty': 'Beginner',
          'content_type': 'lesson_with_quiz',
          'reason': recommendationReason,
        }),
      );

      setState(() => isGeneratingLesson = false);

      if (res.statusCode == 200) {
        final lessonData = jsonDecode(res.body);
        _showLessonDialog(lessonData);
      } else {
        _showFallbackLessonDialog();
      }
    } catch (e) {
      setState(() => isGeneratingLesson = false);
      _showFallbackLessonDialog();
    }
  }

  void _showLessonDialog(Map<String, dynamic> lesson) {
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
                    Text(
                      lesson['topic'] ?? 'AI Micro-Lesson',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    lesson['explanation'] ??
                        'Here is your AI generated micro-lesson explanation.',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.text, height: 1.5),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Code Examples',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    (lesson['examples'] != null &&
                            (lesson['examples'] as List).isNotEmpty)
                        ? lesson['examples'][0]
                        : '# Python Code Example\nnumbers = [1, 2, 3, 4]\nsquares = [x**2 for x in numbers]\nprint(squares)',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  text: 'Complete Lesson 🎉',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFallbackLessonDialog() {
    _showLessonDialog({
      'topic': recommendationTopic,
      'explanation':
          'List comprehensions provide a concise way to create lists in Python. Syntax: [expression for item in iterable].',
      'examples': [
        '# Example:\nsquares = [x**2 for x in range(10)]\nprint(squares)'
      ],
    });
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
                Row(
                  children: [
                    const Pill(
                      text: 'CURRENT STEP',
                      background: AppColors.lavender,
                      foreground: AppColors.purple,
                    ),
                    const Spacer(),
                    Text(
                      '${(progressValue * 100).toInt()}%',
                      style: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
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
                const Text(
                  'Module 4 • Functions & Data Structures',
                  style: TextStyle(fontSize: 10, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                ProgressBar(value: progressValue),
                const SizedBox(height: 9),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(progressValue * 100).toInt()}% Completed',
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.muted)),
                    const Text('12/28 Lessons',
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
                        onPressed: openAiLessonModal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              backgroundColor: AppColors.page,
                              body: const SafeArea(child: SyllabusScreen()),
                            ),
                          ),
                        ),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Recommendation',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        recommendationReason,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.text,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 9),
                      InkWell(
                        onTap: isGeneratingLesson ? null : openAiLessonModal,
                        child: Text(
                          isGeneratingLesson
                              ? 'Generating AI Lesson...'
                              : 'Start Micro-Lesson →',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
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
                      CircularProgressIndicator(
                        value: progressValue,
                        strokeWidth: 7,
                        backgroundColor: const Color(0xFFE8E7F0),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.purple),
                      ),
                      Text(
                        '${(progressValue * 100).toInt()}',
                        style: const TextStyle(
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
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor: AppColors.page,
                  body: const SafeArea(child: TerminalScreen()),
                ),
              ),
            ),
            child: const UpNextTile(
              icon: Icons.terminal_rounded,
              title: 'Open Terminal',
              subtitle: 'Practice running code',
            ),
          ),
        ],
      ),
    );
  }
}
