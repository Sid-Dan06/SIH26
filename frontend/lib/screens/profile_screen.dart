import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/progress_bar.dart';
import '../widgets/section_title.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  String userName = ApiService.userName;
  Map<String, dynamic> skillProfile = {};
  List<dynamic> history = [];
  List<dynamic> quizHistory = [];

  double pythonScore = 0.0;
  double sqlScore = 0.0;
  double gitScore = 0.0;
  double linuxScore = 0.0;

  @override
  void initState() {
    super.initState();
    loadProfileData();
  }

  Future<void> loadProfileData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchProgress(),
        ApiService.fetchHistory(),
        ApiService.fetchQuizHistory(),
      ]);

      final progress = results[0] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          userName = ApiService.userName;
          skillProfile =
              (progress['skill_profile'] as Map?)?.cast<String, dynamic>() ??
                  {};

          history = results[1] as List<dynamic>;
          quizHistory = results[2] as List<dynamic>;

          // 🌟 Unstarted skills default cleanly to 0.0 (0%)
          pythonScore = skillProfile.containsKey('Python')
              ? _avgSkill(skillProfile['Python']) / 100
              : 0.0;

          sqlScore = skillProfile.containsKey('SQL')
              ? _avgSkill(skillProfile['SQL']) / 100
              : 0.0;

          gitScore = skillProfile.containsKey('Git')
              ? _avgSkill(skillProfile['Git']) / 100
              : 0.0;

          linuxScore = skillProfile.containsKey('Linux')
              ? _avgSkill(skillProfile['Linux']) / 100
              : 0.0;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  double _avgSkill(dynamic topics) {
    if (topics is! Map || topics.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    topics.forEach((_, value) {
      if (value is Map && value.containsKey('mastery')) {
        sum += (value['mastery'] as num).toDouble();
        count++;
      }
    });
    return count > 0 ? (sum / count) : 0.0;
  }

  double get overallMastery {
    final scores = [pythonScore, sqlScore, gitScore, linuxScore];
    final activeScores = scores.where((s) => s > 0).toList();
    if (activeScores.isEmpty) return 0.0;
    final total = activeScores.reduce((a, b) => a + b);
    return total / activeScores.length;
  }

  Future<void> _handleLogout() async {
    await AuthService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.purple),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'My Profile & Progress',
            subtitle: 'Real-time skill mastery, roadmap, and learning history.',
          ),
          const SizedBox(height: 18),

          // User Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.lavender,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'P',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Pill(
                            text: ApiService.isGuestTestingMode
                                ? 'Guest'
                                : 'Member',
                            background: const Color(0xFFFFF3E0),
                            foreground: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Learner • Active Session',
                        style: TextStyle(fontSize: 10, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded,
                      color: AppColors.red, size: 20),
                  onPressed: _handleLogout,
                  tooltip: 'Log Out',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 🚀 START NEW SKILL BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.purple, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.purple, size: 18),
              label: const Text(
                '+ Start Another Skill (Python, SQL, Git, Linux)',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Mastery & Attempts Stat Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.show_chart_rounded,
                          color: AppColors.purple, size: 20),
                      const SizedBox(height: 10),
                      Text(
                        '${(overallMastery * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const Text('Overall Mastery',
                          style:
                              TextStyle(fontSize: 9, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.quiz_outlined,
                          color: Colors.orange, size: 20),
                      const SizedBox(height: 10),
                      Text(
                        '${quizHistory.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                      const Text('Quiz Attempts',
                          style:
                              TextStyle(fontSize: 9, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Skills Mastery Matrix'),
          const SizedBox(height: 12),

          // Skills Matrix List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSkillRow('Python', pythonScore),
                const Divider(height: 24, color: AppColors.border),
                _buildSkillRow('SQL', sqlScore),
                const Divider(height: 24, color: AppColors.border),
                _buildSkillRow('Git', gitScore),
                const Divider(height: 24, color: AppColors.border),
                _buildSkillRow('Linux', linuxScore),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String label, double score) {
    final pct = (score * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text),
            ),
            Text(
              pct > 0 ? '$pct%' : '0% (Not Started)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pct > 0 ? AppColors.purple : AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(value: score),
      ],
    );
  }
}
