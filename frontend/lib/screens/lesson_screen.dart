import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/primary_button.dart';
import '../services/api_service.dart';
import '../main.dart';

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
    selectedTopic =
        widget.initialTopic != null && skillTopics.contains(widget.initialTopic)
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
      if (mounted)
        setState(() => errorText = 'Could not generate a lesson right now. $e');
    } finally {
      if (mounted) setState(() => isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = SyllabusData.topicsBySkill[selectedSkill]!;

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
                  Expanded(
                    child: AppHeader(
                      title: 'Lesson Studio',
                      subtitle:
                          'AI-generated micro-lessons for $selectedTopic.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown selectors card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedSkill,
                            decoration: InputDecoration(
                              labelText: 'Skill',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            items: SyllabusData.topicsBySkill.keys
                                .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedSkill = val;
                                  selectedTopic =
                                      SyllabusData.topicsBySkill[val]!.first;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedDifficulty,
                            decoration: InputDecoration(
                              labelText: 'Difficulty',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            items: difficulties
                                .map((d) => DropdownMenuItem(
                                    value: d,
                                    child: Text(d,
                                        style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => selectedDifficulty = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedTopic,
                      decoration: InputDecoration(
                        labelText: 'Topic',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: topics
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(fontSize: 12))))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedTopic = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: isGenerating
                            ? 'Generating...'
                            : 'Generate AI Lesson ✨',
                        onPressed: isGenerating ? null : generateLesson,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Lesson Display Card
              if (isGenerating)
                const ContainerLoader()
              else if (errorText != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE6E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(errorText!,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 12)),
                )
              else if (lessonContent != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    lessonContent!,
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.5, color: AppColors.text),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContainerLoader extends StatelessWidget {
  const ContainerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: AppColors.purple),
            SizedBox(height: 14),
            Text('Generating AI Micro-Lesson...',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
