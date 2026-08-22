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
import 'onboarding_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = ApiService.userName;
  String recommendationReason =
      "Select a skill and take your diagnostic quiz to receive tailored AI learning recommendations!";
  String recommendationTopic = "Diagnostic Assessment";
  String recommendationSkill = "Python";
  double progressValue = 0.0; // 🌟 Zero dummy data: starts clean at 0%
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

      if (data.isNotEmpty && data.containsKey('skill_profile')) {
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

          final profile = data['skill_profile'] as Map<String, dynamic>;
          if (profile.containsKey(recommendationSkill)) {
            final topics = profile[recommendationSkill] as Map<String, dynamic>;
            if (topics.isNotEmpty) {
              double sum = 0;
              topics.forEach((key, value) {
                sum += (value['mastery'] ?? 0.0);
              });
              progressValue = (sum / topics.length) / 100;
            }
          }
        });
      }
    } catch (_) {}
  }

  void openAiLessonModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(
          initialSkill: recommendationSkill,
          initialTopic: recommendationTopic,
          initialDifficulty: "Beginner",
          autoGenerate: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int displayPct = (progressValue * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeader(
            title: 'Welcome back, $userName',
            subtitle: 'Track your skill development and AI recommendations.',
          ),
          const SizedBox(height: 18),

          // Daily Goal Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x336C5CE7),
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAILY GOAL PROGRESS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayPct > 0
                            ? '$displayPct% Mastery Reached'
                            : 'Start Your First Skill',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        displayPct > 0
                            ? 'Great pace! Keep practicing to unlock advanced tiers.'
                            : 'Tap below to select a skill and take your test!',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: progressValue > 0 ? progressValue : 0.05,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        strokeWidth: 5,
                      ),
                    ),
                    Text(
                      '$displayPct%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // AI Targeted Recommendation Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Pill(
                      text: recommendationSkill,
                      background: AppColors.lavender,
                      foreground: AppColors.purple,
                    ),
                    const Spacer(),
                    const Icon(Icons.auto_awesome,
                        color: AppColors.purple, size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  recommendationTopic,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendationReason,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    text: 'Start Micro-Lesson →',
                    onPressed: openAiLessonModal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Quick Actions'),
          const SizedBox(height: 12),

          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              );
            },
            child: const UpNextTile(
              icon: Icons.add_circle_outline_rounded,
              title: 'Select & Start New Skill',
              subtitle: 'Pick Python, SQL, Git, Linux',
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TerminalScreen()),
              );
            },
            child: const UpNextTile(
              icon: Icons.terminal_rounded,
              title: 'Interactive Code Terminal',
              subtitle: '5-second Python subprocess sandbox',
            ),
          ),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Recent Activity Feed'),
          const SizedBox(height: 12),

          if (history.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  'No recent learning sessions yet. Complete your first quiz to see activity history!',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length > 5 ? 5 : history.length,
              itemBuilder: (context, i) {
                final session = history[i];
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
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.lavender,
                        child: Icon(Icons.check_rounded,
                            color: AppColors.purple, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${session['skill']} - ${session['topic']}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text),
                            ),
                            Text(
                              'Score: ${session['quiz_correct']}/${session['quiz_total']}',
                              style: const TextStyle(
                                  fontSize: 9.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
