import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _hasInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get hasInitialized => _hasInitialized;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  AuthProvider() {
    debugPrint('AuthProvider: Constructor called');
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      debugPrint('AuthProvider: Starting initialization');
      _isLoading = true;
      notifyListeners();

      // Wait for Firebase to be initialized
      int attempts = 0;
      while (Firebase.apps.isEmpty && attempts < 50) {
        debugPrint(
          'AuthProvider: Waiting for Firebase initialization... Attempt ${attempts + 1}',
        );
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase initialization timeout after 5 seconds');
      }

      debugPrint(
        'AuthProvider: Firebase initialized, setting up auth listener',
      );

      // Set up auth state listener
      _authSubscription = _auth.authStateChanges().listen(
        (User? user) {
          debugPrint(
            'AuthProvider: Auth state changed - User: ${user?.email ?? 'null'}',
          );
          _user = user;

          if (!_hasInitialized) {
            _hasInitialized = true;
            _isLoading = false;
            debugPrint('AuthProvider: Initialization complete');
          }

          _hasError = false;
          _errorMessage = null;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('AuthProvider: Auth state error: $error');
          _setError('Authentication error: ${error.toString()}');
        },
      );

      debugPrint('AuthProvider: Auth state listener set up');
    } catch (e) {
      debugPrint('AuthProvider: Initialization error: $e');
      _setError('Failed to initialize authentication: ${e.toString()}');
    }
  }

  void _setError(String message) {
    debugPrint('AuthProvider: Setting error: $message');
    _hasError = true;
    _errorMessage = message;
    _isLoading = false;
    _hasInitialized = true;
    notifyListeners();
  }

  void clearError() {
    _hasError = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      debugPrint('AuthProvider: Attempting sign in for $email');
      _isLoading = true;
      clearError();
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();

      debugPrint('AuthProvider: Sign in successful');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint(
        'AuthProvider: FirebaseAuthException during sign in: ${e.code} - ${e.message}',
      );

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found for that email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your connection.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }

      _setError(message);
      return false;
    } catch (e) {
      _isLoading = false;
      debugPrint('AuthProvider: Unexpected error during sign in: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  Future<bool> signUp(
    String email,
    String password,
    String name, {
    String? businessName,
  }) async {
    try {
      debugPrint('AuthProvider: Attempting sign up for $email');
      _isLoading = true;
      clearError();
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        debugPrint('AuthProvider: Updated display name to $name');
      }

      _isLoading = false;
      notifyListeners();

      debugPrint('AuthProvider: Sign up successful');
      return credential.user != null;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint(
        'AuthProvider: FirebaseAuthException during sign up: ${e.code} - ${e.message}',
      );

      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          message = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        case 'operation-not-allowed':
          message = 'Email/password accounts are not enabled.';
          break;
        default:
          message = 'Sign up failed: ${e.message}';
      }

      _setError(message);
      return false;
    } catch (e) {
      _isLoading = false;
      debugPrint('AuthProvider: Unexpected error during sign up: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint('AuthProvider: Attempting sign out');
      _isLoading = true;
      notifyListeners();

      await _auth.signOut();

      _isLoading = false;
      debugPrint('AuthProvider: Sign out successful');
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('AuthProvider: Error during sign out: $e');
      _setError('Failed to sign out: ${e.toString()}');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      debugPrint('AuthProvider: Attempting password reset for $email');
      _isLoading = true;
      clearError();
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);

      _isLoading = false;
      notifyListeners();

      debugPrint('AuthProvider: Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      debugPrint(
        'AuthProvider: FirebaseAuthException during password reset: ${e.code}',
      );

      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email address.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }

      _setError(message);
      return false;
    } catch (e) {
      _isLoading = false;
      debugPrint('AuthProvider: Unexpected error during password reset: $e');
      _setError('An unexpected error occurred: ${e.toString()}');
      return false;
    }
  }

  // Method to refresh current user data
  Future<void> refreshUser() async {
    try {
      debugPrint('AuthProvider: Refreshing user data');
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        _user = _auth.currentUser;
        notifyListeners();
        debugPrint('AuthProvider: User data refreshed');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error refreshing user: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('AuthProvider: Disposing');
    _authSubscription?.cancel();
    super.dispose();
  }
}
