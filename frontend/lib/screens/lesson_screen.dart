import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../services/api_service.dart';

class LessonScreen extends StatefulWidget {
  final String? initialSkill;
  final String? initialTopic;
  final String? initialDifficulty;
  final bool autoGenerate;

  const LessonScreen({
    super.key,
    this.initialSkill,
    this.initialTopic,
    this.initialDifficulty,
    this.autoGenerate = false,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late String selectedSkill;
  late String selectedTopic;
  late String selectedDifficulty;

  bool isGenerating = false;
  String? lessonContent;
  String? errorText;

  final List<String> difficulties = const [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];

  @override
  void initState() {
    super.initState();
    selectedSkill = widget.initialSkill != null &&
            SyllabusData.topicsBySkill.containsKey(widget.initialSkill)
        ? widget.initialSkill!
        : 'Python';

    final skillTopics = SyllabusData.topicsBySkill[selectedSkill]!;
    selectedTopic = widget.initialTopic != null &&
            skillTopics.contains(widget.initialTopic)
        ? widget.initialTopic!
        : skillTopics.first;

    selectedDifficulty = widget.initialDifficulty ?? 'Beginner';

    if (widget.autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        generateLesson();
      });
    }
  }

  Future<void> generateLesson() async {
    setState(() {
      isGenerating = true;
      errorText = null;
      lessonContent = null;
    });
    try {
      final content = await ApiService.generateContent(
        skill: selectedSkill,
        topic: selectedTopic,
        difficulty: selectedDifficulty,
        contentType: 'Explanation + Lesson + Examples',
        reason: 'Learner directly requested a lesson on this topic.',
      );
      if (mounted) setState(() => lessonContent = content);
    } catch (e) {
      if (mounted) setState(() => errorText = 'Could not generate a lesson right now. $e');
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
              Expanded(
                child: AppHeader(
                  title: 'Lesson Studio',
                  subtitle: 'AI-generated micro-lessons for $selectedTopic.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
                const Text('Skill Track',
                    style: TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text)),
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
                        fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text)),
                const SizedBox(height: 6),
                _Dropdown(
                  value: selectedTopic,
                  items: topics,
                  onChanged: (v) => setState(() => selectedTopic = v!),
                ),
                const SizedBox(height: 14),
                const Text('Difficulty Level',
                    style: TextStyle(
                        fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.text)),
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
                    text: isGenerating ? 'Generating Lesson...' : 'Generate AI Lesson',
                    icon: Icons.auto_awesome,
                    onPressed: isGenerating ? null : generateLesson,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(color: AppColors.purple),
                    const SizedBox(height: 14),
                    Text(
                      'AI is crafting your lesson for $selectedTopic...',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          if (errorText != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                errorText!,
                style: const TextStyle(fontSize: 11, color: AppColors.red),
              ),
            ),
          if (lessonContent != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                          color: AppColors.lavender,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.purple, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedTopic,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              '$selectedSkill • $selectedDifficulty Level',
                              style: const TextStyle(fontSize: 10, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.page,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SelectableText(
                      lessonContent!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.text,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
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
