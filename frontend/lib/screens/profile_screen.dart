import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/section_title.dart';
import '../widgets/skill_widgets.dart';
import '../widgets/path_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool loading = true;
  Map<String, dynamic> skillProfile = {};
  List<dynamic> history = [];
  List<dynamic> quizHistory = [];

  double pythonScore = 0.86;
  double sqlScore = 0.61;
  double gitScore = 0.74;
  double linuxScore = 0.45;

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
          skillProfile = (progress['skill_profile'] as Map?)
                  ?.cast<String, dynamic>() ??
              {};

          history = results[1] as List<dynamic>;
          quizHistory = results[2] as List<dynamic>;

          if (skillProfile.containsKey('Python')) {
            pythonScore = _avgSkill(skillProfile['Python']) / 100;
          }

          if (skillProfile.containsKey('SQL')) {
            sqlScore = _avgSkill(skillProfile['SQL']) / 100;
          }

          if (skillProfile.containsKey('Git')) {
            gitScore = _avgSkill(skillProfile['Git']) / 100;
          }

          if (skillProfile.containsKey('Linux')) {
            linuxScore = _avgSkill(skillProfile['Linux']) / 100;
          }
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
    if (topics is! Map || topics.isEmpty) return 50.0;

    double sum = 0;

    topics.forEach((key, value) {
      if (value is Map) {
        sum += (value['mastery'] ?? 50.0).toDouble();
      }
    });

    return sum / topics.length;
  }

  double _overallMastery() {
    if (skillProfile.isEmpty) {
      return ((pythonScore + sqlScore + gitScore + linuxScore) / 4) * 100;
    }

    double total = 0;
    int count = 0;

    skillProfile.forEach((skill, topics) {
      if (topics is Map) {
        topics.forEach((topic, value) {
          if (value is Map) {
            total += (value['mastery'] ?? 0).toDouble();
            count++;
          }
        });
      }
    });

    return count == 0 ? 66.0 : total / count;
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AuthService.signOut();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  String selectedFocusTrack = 'Python & Data Engineering';

  void _showEditProfileModal() {
    final user = AuthService.currentUser;

    final currentName = ApiService.userName.isNotEmpty
        ? ApiService.userName
        : (user?.displayName ?? 'Learner');

    final nameController = TextEditingController(text: currentName);

    String focus = selectedFocusTrack;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 18),
                  const Row(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.purple,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Edit Profile Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Customize your display name and primary learning track.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'DISPLAY NAME',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: AppColors.muted,
                      ),
                      filled: true,
                      fillColor: AppColors.page,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PRIMARY LEARNING TRACK',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.page,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: focus,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.muted,
                        ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Python & Data Engineering',
                            child: Text('Python & Data Engineering'),
                          ),
                          DropdownMenuItem(
                            value: 'SQL & Database Architecture',
                            child: Text('SQL & Database Architecture'),
                          ),
                          DropdownMenuItem(
                            value: 'Git & Version Control Mastery',
                            child: Text('Git & Version Control Mastery'),
                          ),
                          DropdownMenuItem(
                            value: 'Linux & System Administration',
                            child: Text('Linux & System Administration'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => focus = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final newName =
                                  nameController.text.trim();

                              if (newName.isEmpty) return;

                              final messenger =
                                  ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);

                              setModalState(() => isSaving = true);

                              await AuthService.updateProfile(
                                displayName: newName,
                              );

                              if (mounted) {
                                setState(() {
                                  selectedFocusTrack = focus;
                                });

                                nav.pop();

                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Profile updated successfully! ✨',
                                    ),
                                    backgroundColor: AppColors.purple,
                                  ),
                                );
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final overall = _overallMastery();
    final user = AuthService.currentUser;

    final displayName = ApiService.userName.isNotEmpty
        ? ApiService.userName
        : (user?.displayName ?? 'Learner');

    final userEmail = user?.email ??
        (ApiService.isGuestTestingMode
            ? 'Guest Mode'
            : 'learner@devpulse.ai');

    final isGuest = ApiService.isGuestTestingMode || user == null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'My Profile & Progress',
            subtitle:
                'Real-time skill mastery, roadmap, and learning history.',
            showLogo: false,
          ),
          const SizedBox(height: 18),

          // User Info Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showEditProfileModal,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.lavender,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: AppColors.purple,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.purple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isGuest
                                  ? AppColors.yellowBg
                                  : AppColors.greenBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isGuest ? 'Guest' : 'Verified',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                color: isGuest
                                    ? const Color(0xFF8A6A00)
                                    : AppColors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$userEmail • $selectedFocusTrack',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _showEditProfileModal,
                  tooltip: 'Edit Profile',
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.purple,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: _handleSignOut,
                  tooltip: 'Sign Out',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.red,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.purple,
                ),
              ),
            )
          else ...[
            // Performance Metrics
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Overall Mastery',
                    value: '${overall.toInt()}%',
                    icon: Icons.insights_rounded,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    label: 'Quiz Attempts',
                    value: '${quizHistory.length}',
                    icon: Icons.quiz_rounded,
                    color: AppColors.yellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Skills & Progress Represented by Bars
            const SectionTitle(
              title: 'Skills Mastery Matrix',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border,
                ),
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
                  const Row(
                    children: [
                      Text(
                        'Proficiency by Language & Tool',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'Live Analysis',
                        style: TextStyle(
                          color: AppColors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SkillRow(
                    name: 'Python',
                    value: pythonScore,
                    score: '${(pythonScore * 100).toInt()}%',
                  ),
                  SkillRow(
                    name: 'SQL',
                    value: sqlScore,
                    score: '${(sqlScore * 100).toInt()}%',
                  ),
                  SkillRow(
                    name: 'Git',
                    value: gitScore,
                    score: '${(gitScore * 100).toInt()}%',
                  ),
                  SkillRow(
                    name: 'Linux',
                    value: linuxScore,
                    score: '${(linuxScore * 100).toInt()}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // AI Assessment Insights
            const SectionTitle(
              title: 'AI Assessment Insights',
            ),
            const SizedBox(height: 10),
            const InsightCard(
              color: AppColors.greenBg,
              icon: Icons.check_circle_outline,
              title: 'Strong Areas',
              text:
                  'SQL optimization and Python fundamentals are currently performing well.',
            ),
            const InsightCard(
              color: AppColors.yellowBg,
              icon: Icons.warning_amber_rounded,
              title: 'Skill Gaps',
              text:
                  'Linux permissions and advanced Git workflows need reinforcement.',
            ),
            const InsightCard(
              color: Color(0xFFFFE7D8),
              icon: Icons.auto_awesome,
              title: 'Targeted AI Recommendation',
              text:
                  'Suggested next micro-lessons combine Git and Linux for streamlined DevOps proficiency.',
            ),
            const SizedBox(height: 20),

            // My Learning Path Section
            const SectionTitle(
              title: 'My Learning Path Roadmap',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.route_rounded,
                    color: AppColors.purple,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Estimated completion: 3 weeks based on your current pace.',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const PathModule(
              completed: true,
              title: 'Database Fundamentals',
              subtitle: 'Relational models, normalization, ACID.',
              progress: 1,
              status: 'Completed',
              icon: Icons.storage_rounded,
            ),
            const PathModule(
              completed: true,
              title: 'Basic SQL Queries',
              subtitle: 'SELECT, JOIN, GROUP BY, filtering.',
              progress: 1,
              status: 'Completed',
              icon: Icons.table_chart_rounded,
            ),
            const PathModule(
              current: true,
              title: 'SQL Joins & Subqueries',
              subtitle:
                  'Build practical queries using real datasets.',
              progress: .6,
              status: 'In Progress',
              icon: Icons.code_rounded,
            ),
            const PathModule(
              title: 'Window Functions',
              subtitle:
                  'Advanced analytics and ranking queries.',
              progress: 0,
              status: 'Locked',
              icon: Icons.functions_rounded,
            ),
            const PathModule(
              title: 'Query Optimization',
              subtitle:
                  'Indexes, execution plans and performance.',
              progress: 0,
              status: 'Locked',
              icon: Icons.speed_rounded,
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 8.5,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}