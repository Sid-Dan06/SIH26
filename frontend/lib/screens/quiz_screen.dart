import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/quiz_widgets.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int selected = -1;
  bool submitted = false;

  final answers = const ['1', '2', '3', 'iterable'];

  @override
  Widget build(BuildContext context) {
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

          const Row(
            children: [
              Text(
                'Question 3 of 10',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              Spacer(),
              Pill(
                text: 'Python Basics',
                background: AppColors.lavender,
                foreground: AppColors.purple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const ProgressBar(value: .3),

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
                const Text(
                  'Given list = [1, 2, 3], what is the output of my_list[-1]?',
                  style: TextStyle(
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
                  child: const Text(
                    'my_list = [1, 2, 3]\nprint(my_list[-1])',
                    style: TextStyle(
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
                          'AI Hint: Python supports negative indexing.',
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
                    onTap: submitted
                        ? null
                        : () => setState(() => selected = i),
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: submitted ? 'Next Question' : 'Submit Answer',
                    icon: submitted
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                    onPressed: selected < 0
                        ? null
                        : () => setState(() => submitted = true),
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
