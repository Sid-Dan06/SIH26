import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../services/api_service.dart';

class QuizGeneratorScreen extends StatefulWidget {
  const QuizGeneratorScreen({super.key});

  @override
  State<QuizGeneratorScreen> createState() => _QuizGeneratorScreenState();
}

class _QuizGeneratorScreenState extends State<QuizGeneratorScreen> {
  String selectedSkill = 'Python';
  late String selectedTopic;
  String selectedDifficulty = 'Beginner';

  bool isGenerating = false;
  String? quizContent;
  String? errorText;

  final List<String> difficulties = const [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    selectedTopic = SyllabusData.topicsBySkill[selectedSkill]!.first;
  }

  Future<void> generateQuiz() async {
    setState(() {
      isGenerating = true;
      errorText = null;
      quizContent = null;
    });
    try {
      final content = await ApiService.generateContent(
        skill: selectedSkill,
        topic: selectedTopic,
        difficulty: selectedDifficulty,
        contentType: 'MCQ Quiz (5 questions, with answers)',
        reason: 'Learner directly requested a practice quiz on this topic.',
      );
      setState(() => quizContent = content);
    } catch (e) {
      setState(() => errorText = 'Could not generate a quiz right now. $e');
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = SyllabusData.topicsBySkill[selectedSkill]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Quiz Generator',
            subtitle: 'Ask the AI for a fresh practice quiz on any topic.',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Skill',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                _Dropdown(
                  value: selectedSkill,
                  items: SyllabusData.topicsBySkill.keys.toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSkill = v!;
                      selectedTopic =
                          SyllabusData.topicsBySkill[selectedSkill]!.first;
                    });
                  },
                ),
                const SizedBox(height: 14),
                const Text('Topic',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                _Dropdown(
                  value: selectedTopic,
                  items: topics,
                  onChanged: (v) => setState(() => selectedTopic = v!),
                ),
                const SizedBox(height: 14),
                const Text('Difficulty',
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                _Dropdown(
                  value: selectedDifficulty,
                  items: difficulties,
                  onChanged: (v) => setState(() => selectedDifficulty = v!),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: isGenerating ? 'Generating...' : 'Generate Quiz',
                    icon: Icons.quiz_rounded,
                    onPressed: isGenerating ? null : generateQuiz,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.purple),
              ),
            ),
          if (errorText != null)
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                errorText!,
                style: const TextStyle(fontSize: 10.5, color: AppColors.red),
              ),
            ),
          if (quizContent != null) ...[
            Row(
              children: [
                const Icon(Icons.quiz_rounded,
                    color: AppColors.purple, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$selectedTopic Quiz',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                quizContent!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                  color: Colors.white,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.muted),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
