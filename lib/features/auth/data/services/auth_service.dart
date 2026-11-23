import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/app_user.dart';

abstract class AuthService {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<void> updateDisplayName(String displayName);
}

class FirebaseAuthService implements AuthService {
  final fb_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthService({fb_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  @override
  Stream<AppUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  AppUser? get currentUser => _mapFirebaseUser(_firebaseAuth.currentUser);

  AppUser? _mapFirebaseUser(fb_auth.User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ??
          (user.email != null && user.email!.contains('@')
              ? user.email!.split('@').first
              : 'Antidotes User'),
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      createdAt: user.metadata.creationTime,
      lastLoginAt: user.metadata.lastSignInTime,
    );
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cred = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = _mapFirebaseUser(cred.user);
    if (user == null) {
      throw Exception('Authentication failed. No user returned.');
    }
    return user;
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user != null && displayName.trim().isNotEmpty) {
      await cred.user!.updateDisplayName(displayName.trim());
      await cred.user!.reload();
    }
    final user = _mapFirebaseUser(_firebaseAuth.currentUser ?? cred.user);
    if (user == null) {
      throw Exception('Registration failed.');
    }
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final current = _firebaseAuth.currentUser;
    if (current != null) {
      await current.updateDisplayName(displayName.trim());
      await current.reload();
    }
  }
}
