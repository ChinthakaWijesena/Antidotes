import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/app_user.dart';
import '../../data/services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription<AppUser?>? _authSub;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuestMode = false;

  AuthController({required AuthService authService})
      // ignore: prefer_initializing_formals
      : _authService = authService {
    _currentUser = _authService.currentUser;
    _authSub = _authService.authStateChanges.listen((user) {
      _currentUser = user;
      if (user != null) {
        _isGuestMode = false;
      }
      notifyListeners();
    });
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isGuestMode => _isGuestMode;
  bool get isAuthenticated => _currentUser != null;
  bool get hasAccess => isAuthenticated || _isGuestMode;

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void continueAsGuest() {
    _isGuestMode = true;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _currentUser = user;
      _isGuestMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
      _currentUser = user;
      _isGuestMode = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signOut();
    } finally {
      _currentUser = null;
      _isGuestMode = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateDisplayName(String newName) async {
    if (_currentUser == null) return;
    try {
      await _authService.updateDisplayName(newName);
      _currentUser = _currentUser?.copyWith(displayName: newName);
      notifyListeners();
    } catch (e) {
      _errorMessage = _cleanErrorMessage(e.toString());
      notifyListeners();
    }
  }

  String _cleanErrorMessage(String raw) {
    if (raw.contains('non-mobile') || raw.contains('not supported on non-mobile')) {
      return 'Google Sign-In is not supported on Windows desktop. Please use Email & Password or click "Sign Up" below.';
    }
    if (raw.contains('unknown-error') ||
        raw.contains('internal error') ||
        raw.contains('user-not-found') ||
        raw.contains('wrong-password') ||
        raw.contains('invalid-credential')) {
      return 'Incorrect email/password or account does not exist. Click "Sign Up" below to create an account.';
    }
    if (raw.contains('email-already-in-use')) {
      return 'An account already exists with this email.';
    }
    if (raw.contains('weak-password')) {
      return 'Password should be at least 6 characters.';
    }
    if (raw.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network connection error. Check your internet.';
    }
    return raw.replaceFirst('Exception: ', '').replaceAll('FirebaseAuthException: ', '');
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
