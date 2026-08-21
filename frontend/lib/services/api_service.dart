import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔘 SET TO true FOR NOW (Testing mode without Login screen)
  // 🔘 SET TO false LATER (When you build your Login/Sign-Up screens)
  static bool isGuestTestingMode = true;

  // Local FastAPI URL for Web Chrome
  static const String baseUrl = "http://127.0.0.1:8000";
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
}
