import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/quiz_widgets.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int selected = -1;
  bool submitted = false;
  bool loading = true;
  bool isSubmitting = false;
  int currentQuestionIndex = 0;

  List<dynamic> liveQuestions = [];
  List<Map<String, dynamic>> userResponses = [];

  @override
  void initState() {
    super.initState();
    loadBackendQuestions();
  }

  Future<void> loadBackendQuestions() async {
    try {
      final qList = await ApiService.fetchQuestions();
      if (mounted) {
        setState(() {
          liveQuestions = qList;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> submitCurrentAnswer() async {
    if (selected < 0 || isSubmitting) return;

    final q = liveQuestions.isNotEmpty
        ? liveQuestions[currentQuestionIndex]
        : {
            'question_id': 'q1',
            'options': ['1', '2', '3', 'iterable'],
          };

    final selectedText = (q['options'] as List)[selected];

    userResponses.add({
      'question_id': q['question_id'] ?? 'q1',
      'selected_answer': selectedText,
      'time_taken_seconds': 15.0,
    });

    if (currentQuestionIndex + 1 <
        (liveQuestions.isNotEmpty ? liveQuestions.length : 10)) {
      setState(() {
        currentQuestionIndex++;
        selected = -1;
      });
    } else {
      // Final Question Submitted!
      setState(() {
        isSubmitting = true;
        submitted = true;
      });

      try {
        await ApiService.submitQuiz(userResponses);
      } catch (e) {
        debugPrint("Network notice: $e");
      } finally {
        if (mounted) {
          setState(() {
            isSubmitting = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }

    final currentQuestion = liveQuestions.isNotEmpty
        ? liveQuestions[currentQuestionIndex]
        : {
            'question':
                'Given list = [1, 2, 3], what is the output of my_list[-1]?',
            'skill': 'Python',
            'topic': 'Basics',
            'options': ['1', '2', '3', 'iterable'],
          };

    final List<String> answers = List<String>.from(currentQuestion['options']);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Quick Quiz',
            subtitle: 'Test your knowledge and update your skill profile.',
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Text(
                'Question ${currentQuestionIndex + 1} of ${liveQuestions.isNotEmpty ? liveQuestions.length : 10}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              Pill(
                text:
                    '${currentQuestion['skill'] ?? 'Python'} ${currentQuestion['topic'] ?? 'Basics'}',
                background: AppColors.lavender,
                foreground: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProgressBar(
              value: (currentQuestionIndex + 1) /
                  (liveQuestions.isNotEmpty ? liveQuestions.length : 10)),
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
                Text(
                  currentQuestion['question'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentQuestion['question'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppColors.purple, size: 15),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'AI Hint: Read the options carefully.',
                          style: TextStyle(
                            color: AppColors.purple,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ...List.generate(
                  answers.length,
                  (i) => AnswerOption(
                    text: answers[i],
                    selected: selected == i,
                    correct: submitted && i == 2,
                    wrong: submitted && selected == i && i != 2,
                    onTap: (submitted || isSubmitting)
                        ? null
                        : () => setState(() => selected = i),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: submitted
                        ? 'Quiz Complete 🎉'
                        : (isSubmitting ? 'Submitting...' : 'Submit Answer'),
                    icon: submitted
                        ? Icons.check_circle_rounded
                        : Icons.check_rounded,
                    onPressed: (selected < 0 || isSubmitting)
                        ? null
                        : submitCurrentAnswer,
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
