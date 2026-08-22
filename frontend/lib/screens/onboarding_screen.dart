import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../main.dart';
import 'syllabus_screen.dart';
import 'quiz_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String selectedSkill = 'Python';
  int selectedOption =
      -1; // 0 = Option A (Beginner), 1 = Option B (Know Basics)

  final skills = [
    {
      'name': 'Python',
      'icon': Icons.code_rounded,
      'desc': 'Data Science & Automation'
    },
    {
      'name': 'SQL',
      'icon': Icons.storage_rounded,
      'desc': 'Databases & Querying'
    },
    {
      'name': 'Git',
      'icon': Icons.merge_type_rounded,
      'desc': 'Version Control & Workflow'
    },
    {
      'name': 'Linux',
      'icon': Icons.terminal_rounded,
      'desc': 'Terminal & Permissions'
    },
  ];

  void proceedToNextStep() {
    if (selectedOption == 0) {
      // 🔴 Option A: Don't know anything -> Open Syllabus at Lesson #1
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AppShell()),
                  (route) => false,
                ),
              ),
            ),
            body: SafeArea(
              child: SyllabusScreen(expandedSkill: selectedSkill),
            ),
          ),
        ),
      );
    } else if (selectedOption == 1) {
      // 🟡 Option B: Know some basics -> Open Diagnostic Quiz
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon:
                    const Icon(Icons.arrow_back_rounded, color: AppColors.text),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AppShell()),
                  (route) => false,
                ),
              ),
            ),
            body: SafeArea(
              child: QuizScreen(targetSkill: selectedSkill),
            ),
          ),
        ),
      );
    }
  }

  void _goBackToMainApp() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBackToMainApp();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text),
            onPressed: _goBackToMainApp,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.purple, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'DevPulse AI',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome! Select Your Skill',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select a skill and tell us your experience to generate your custom roadmap.',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.muted, height: 1.4),
                ),

                const SizedBox(height: 24),

                // Step 1: Select Skill
                const Text(
                  '1. Which skill do you want to learn?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: skills.length,
                  itemBuilder: (context, i) {
                    final item = skills[i];
                    final isSelected = selectedSkill == item['name'];
                    return InkWell(
                      onTap: () => setState(
                          () => selectedSkill = item['name'] as String),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.lavender : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.purple
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? AppColors.purple
                                  : AppColors.muted,
                              size: 20,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? AppColors.purple
                                    : AppColors.text,
                              ),
                            ),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(
                                  fontSize: 8.5, color: AppColors.muted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // Step 2: Select Level
                const Text(
                  '2. What is your current experience level?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text),
                ),
                const SizedBox(height: 12),

                // Option A Card
                InkWell(
                  onTap: () => setState(() => selectedOption = 0),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedOption == 0
                          ? AppColors.lavender
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedOption == 0
                            ? AppColors.purple
                            : AppColors.border,
                        width: selectedOption == 0 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.child_care_rounded,
                              color: Colors.green, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "I don't know anything at all",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Start from absolute basics with step-by-step AI micro-lessons.',
                                style: TextStyle(
                                    fontSize: 9.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Option B Card
                InkWell(
                  onTap: () => setState(() => selectedOption = 1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: selectedOption == 1
                          ? AppColors.lavender
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedOption == 1
                            ? AppColors.purple
                            : AppColors.border,
                        width: selectedOption == 1 ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.psychology_rounded,
                              color: Colors.orange, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "I know some basics / Intermediate",
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Take a diagnostic test to evaluate your skills & skip what you know.',
                                style: TextStyle(
                                    fontSize: 9.5, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Proceed Button
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Continue to My Course 🚀',
                    onPressed: selectedOption < 0 ? null : proceedToNextStep,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
