import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.user,
  });
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static bool get isAuthenticated => _auth.currentUser != null;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign In with Email & Password using Firebase Authentication
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      final displayName = user?.displayName?.isNotEmpty == true
          ? user!.displayName!
          : email.trim().split('@').first;

      ApiService.isGuestTestingMode = false;
      ApiService.userName = displayName;

      // Also attempt background sync with FastAPI backend if running
      try {
        await ApiService.login(email.trim(), password);
      } catch (backendError) {
        debugPrint('Backend sync notice (optional): $backendError');
      }

      return AuthResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many failed login attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed. Please check your credentials.';
      }
      return AuthResult(success: false, errorMessage: message);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Sign Up with Email, Password & Username using Firebase Authentication
  static Future<AuthResult> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(username.trim());
        await user.reload();
      }

      ApiService.isGuestTestingMode = false;
      ApiService.userName = username.trim();

      // Also attempt background registration with FastAPI backend if running
      try {
        await ApiService.register(username.trim(), email.trim(), password);
      } catch (backendError) {
        debugPrint('Backend sync notice (optional): $backendError');
      }

      return AuthResult(success: true, user: _auth.currentUser);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists for this email address.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }
      return AuthResult(success: false, errorMessage: message);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Update Profile Details (Display Name & optional Email)
  static Future<AuthResult> updateProfile({
    required String displayName,
    String? email,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }

      ApiService.userName = displayName.trim();
      return AuthResult(success: true, user: _auth.currentUser);
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
      );
    }
  }

  /// Sign Out of Firebase Auth
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    ApiService.userToken = null;
    ApiService.userId = 1;
    ApiService.userName = "Guest User";
    ApiService.isGuestTestingMode = true;
    ApiService.latestDbProfile = null;
  }

  /// Continue as Guest without Firebase account
  static void continueAsGuest() {
    ApiService.isGuestTestingMode = true;
    ApiService.userToken = null;
    ApiService.userId = 1;
    ApiService.userName = "Guest User";
    ApiService.latestDbProfile = null;
  }
}
