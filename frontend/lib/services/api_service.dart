import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔘 SET TO true FOR NOW (Testing mode without Login screen)
  // 🔘 SET TO false LATER (When you build your Login/Sign-Up screens)
  static bool isGuestTestingMode = true;

  // Local FastAPI URL for Web Chrome / Emulator
  static const String baseUrl = "http://10.0.2.2:8000";
  static String? userToken;
  static int? userId = 1;
  static String userName = "Potato";

  // Stores latest DB profile returned from backend
  static Map<String, dynamic>? latestDbProfile;

  // -------------------------------------------------------------
  // 🔐 PRODUCTION AUTHENTICATION SYSTEM (Ready for your Login UI)
  // -------------------------------------------------------------

  // 1. User Registration
  static Future<bool> register(
      String username, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'username': username, 'email': email, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        userToken = data['token'];
        userId = data['user']['id'];
        userName = data['user']['username'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  // 2. User Login
  static Future<bool> login(String loginStr, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': loginStr, 'password': password}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        userToken = data['token'];
        userId = data['user']['id'];
        userName = data['user']['username'];
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Helper to get active HTTP Headers (Uses Token or Guest Fallback)
  static Map<String, String> get _authHeaders {
    final headers = {'Content-Type': 'application/json'};
    if (userToken != null) {
      headers['Authorization'] = 'Bearer $userToken';
    } else if (isGuestTestingMode) {
      headers['Authorization'] = 'Bearer guest_test_token_123';
    }
    return headers;
  }

  // -------------------------------------------------------------
  // 🌐 CORE APP FEATURES (Quiz, Progress, Terminal, AI)
  // -------------------------------------------------------------

  // 3. Fetch Questions for Quiz Screen
  static Future<List<dynamic>> fetchQuestions() async {
    final res = await http.get(Uri.parse('$baseUrl/assessment/start'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to load questions from backend");
  }

  // 4. Submit Quiz & Save Progress to DB
  static Future<Map<String, dynamic>> submitQuiz(
      List<Map<String, dynamic>> responses) async {
    final res = await http.post(
      Uri.parse('$baseUrl/assessment/submit'),
      headers: _authHeaders,
      body: jsonEncode({
        'user_id': userId?.toString() ?? "guest_user_1",
        'responses': responses,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      latestDbProfile = data; // Save DB profile for live dashboard display
      return data;
    }
    throw Exception("Failed to submit quiz to backend");
  }

  // 5. Fetch Progress Profile from DB
  static Future<Map<String, dynamic>> fetchProgress() async {
    if (latestDbProfile != null) {
      return latestDbProfile!;
    }
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/progress'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        latestDbProfile = data;
        return data;
      }
    } catch (_) {}
    return {};
  }

  // 6. Execute Python Code in Mobile Terminal
  static Future<Map<String, dynamic>> executeCode(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/execute'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'language': 'python', 'code': code}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception("Failed to execute code in backend sandbox");
  }

  // 7. AI Content Generation (used by both the Lesson screen & Quiz
  // Generator screen — same backend endpoint, different content_type).
  static Future<String> generateContent({
    required String skill,
    required String topic,
    required String difficulty,
    required String contentType,
    double mastery = 40.0,
    String reason = "Requested directly by the learner.",
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/generate-content'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'skill': skill,
        'topic': topic,
        'mastery': mastery,
        'difficulty': difficulty,
        'content_type': contentType,
        'reason': reason,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['content']?.toString() ?? '';
    }
    throw Exception("Failed to generate AI content");
  }

  // 8. Session History (for the Dashboard screen)
  static Future<List<dynamic>> fetchHistory() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['sessions'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // 9. Quiz Attempt History (for the Dashboard screen)
  static Future<List<dynamic>> fetchQuizHistory() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/quiz-history'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['attempts'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  // 10. Complete Learning Session & update mastery
  static Future<Map<String, dynamic>> completeLearningSession({
    required String skill,
    required String topic,
    required int quizCorrect,
    required int quizTotal,
    double? exerciseScore,
    double? timeTakenSeconds,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/learning/complete'),
      headers: _authHeaders,
      body: jsonEncode({
        'user_id': userId?.toString() ?? "guest_user_1",
        'skill': skill,
        'topic': topic,
        'quiz_correct': quizCorrect,
        'quiz_total': quizTotal,
        'exercise_score': exerciseScore,
        'time_taken_seconds': timeTakenSeconds,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data.containsKey('updated_skill_profile')) {
        latestDbProfile = {
          'user_id': userId,
          'skill_profile': data['updated_skill_profile'],
          'recommendation': data['new_recommendation'],
        };
      }
      return data;
    }
    throw Exception("Failed to complete learning session on backend");
  }
}

/// Static syllabus reference data, mirrored from backend/data/questions.json
/// topic groupings. The backend has no dedicated /syllabus endpoint, so the
/// curriculum structure lives here and is combined with live mastery scores
/// pulled from /progress.
class SyllabusData {
  static const Map<String, List<String>> topicsBySkill = {
    'Python': [
      'Variables and Data Types',
      'Conditions',
      'Loops',
      'Functions',
      'Lists and Dictionaries',
      'OOP',
      'Exception Handling',
      'File Handling',
    ],
    'SQL': [
      'SELECT',
      'WHERE',
      'CRUD',
      'JOINs',
      'GROUP BY',
      'Aggregation',
      'ORDER BY',
      'Subqueries',
    ],
    'Git': [
      'Repository Basics',
      'Commit',
      'Branches',
      'Merge',
      'Conflict Resolution',
      'Pull and Push',
    ],
    'Linux': [
      'Basic Commands',
      'File System',
      'Permissions',
      'Package Management',
      'Processes',
    ],
  };
}
