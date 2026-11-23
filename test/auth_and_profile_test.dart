import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:antidotes/features/auth/data/models/app_user.dart';
import 'package:antidotes/features/auth/data/services/auth_service.dart';
import 'package:antidotes/features/auth/presentation/controllers/auth_controller.dart';
import 'package:antidotes/features/profile/data/models/user_profile.dart';
import 'package:antidotes/features/profile/data/services/profile_service.dart';
import 'package:antidotes/features/profile/presentation/controllers/profile_controller.dart';

class FakeAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (password == 'wrong') {
      throw Exception('wrong-password');
    }
    _user = AppUser(
      uid: 'fake-uid-123',
      email: email,
      displayName: 'Test User',
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AppUser> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (password.length < 6) {
      throw Exception('weak-password');
    }
    _user = AppUser(
      uid: 'fake-uid-456',
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!email.contains('@')) {
      throw Exception('invalid-email');
    }
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    if (_user != null) {
      _user = _user!.copyWith(displayName: displayName);
      _controller.add(_user);
    }
  }

  void dispose() {
    _controller.close();
  }
}

class FakeProfileService implements ProfileService {
  final _controller = StreamController<UserProfile?>.broadcast();
  UserProfile? _profile;

  @override
  Future<UserProfile?> getUserProfile(String uid) async => _profile;

  @override
  Stream<UserProfile?> streamUserProfile(String uid) async* {
    yield _profile;
    yield* _controller.stream;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _profile = profile;
    _controller.add(_profile);
  }

  @override
  Future<void> recordJunkCleaned(String uid, int bytes) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        totalCleanedBytes: _profile!.totalCleanedBytes + bytes,
      );
      _controller.add(_profile);
    }
  }

  @override
  Future<void> recordRamOptimized(String uid) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        totalRamOptimizations: _profile!.totalRamOptimizations + 1,
      );
      _controller.add(_profile);
    }
  }

  @override
  Future<void> recordDnsSwitch(String uid) async {
    if (_profile != null) {
      _profile = _profile!.copyWith(
        totalDnsSwitches: _profile!.totalDnsSwitches + 1,
      );
      _controller.add(_profile);
    }
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('AppUser Model Tests', () {
    test('AppUser computes initials properly', () {
      const user1 = AppUser(
        uid: '1',
        email: 'john.doe@test.com',
        displayName: 'John Doe',
      );
      expect(user1.initials, 'JD');

      const user2 = AppUser(
        uid: '2',
        email: 'single@test.com',
        displayName: 'Chinthaka',
      );
      expect(user2.initials, 'CH');

      const user3 = AppUser(
        uid: '3',
        email: 'anon@test.com',
        displayName: '',
      );
      expect(user3.initials, 'A');
    });

    test('AppUser converts to and from map', () {
      final now = DateTime.now();
      final user = AppUser(
        uid: '123',
        email: 'test@antidotes.com',
        displayName: 'Antidotes Tester',
        isEmailVerified: true,
        createdAt: now,
      );

      final map = user.toMap();
      final deserialized = AppUser.fromMap(map);

      expect(deserialized.uid, '123');
      expect(deserialized.email, 'test@antidotes.com');
      expect(deserialized.displayName, 'Antidotes Tester');
      expect(deserialized.isEmailVerified, true);
    });
  });

  group('UserProfile Model Tests', () {
    test('UserProfile formats cleaned storage correctly', () {
      final now = DateTime.now();
      final p1 = UserProfile(
        uid: '1',
        email: 'a@b.com',
        displayName: 'User',
        createdAt: now,
        lastActiveAt: now,
        totalCleanedBytes: 524288000, // 500 MB
      );
      expect(p1.formattedCleanedStorage, '500.0 MB');

      final p2 = UserProfile(
        uid: '2',
        email: 'a@b.com',
        displayName: 'User',
        createdAt: now,
        lastActiveAt: now,
        totalCleanedBytes: 3221225472, // 3 GB
      );
      expect(p2.formattedCleanedStorage, '3.00 GB');
    });

    test('UserProfile serialization', () {
      final now = DateTime.now();
      final profile = UserProfile(
        uid: 'u-1',
        email: 'chinthaka@test.com',
        displayName: 'Chinthaka',
        createdAt: now,
        lastActiveAt: now,
        totalCleanedBytes: 1048576,
        totalRamOptimizations: 5,
        totalDnsSwitches: 2,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);

      expect(restored.uid, 'u-1');
      expect(restored.displayName, 'Chinthaka');
      expect(restored.totalRamOptimizations, 5);
      expect(restored.totalDnsSwitches, 2);
    });
  });

  group('AuthController Tests', () {
    late FakeAuthService authService;
    late AuthController authController;

    setUp(() {
      authService = FakeAuthService();
      authController = AuthController(authService: authService);
    });

    tearDown(() {
      authController.dispose();
      authService.dispose();
    });

    test('Initial state is not authenticated', () {
      expect(authController.isAuthenticated, false);
      expect(authController.currentUser, isNull);
      expect(authController.isGuestMode, false);
      expect(authController.hasAccess, false);
    });

    test('Continue as guest gives access', () {
      authController.continueAsGuest();
      expect(authController.isGuestMode, true);
      expect(authController.hasAccess, true);
      expect(authController.isAuthenticated, false);
    });

    test('Login with email success', () async {
      final result = await authController.loginWithEmail('test@abc.com', 'password123');
      expect(result, true);
      expect(authController.isAuthenticated, true);
      expect(authController.currentUser?.email, 'test@abc.com');
      expect(authController.hasAccess, true);
      expect(authController.isGuestMode, false);
    });

    test('Login with wrong password handles error gracefully', () async {
      final result = await authController.loginWithEmail('test@abc.com', 'wrong');
      expect(result, false);
      expect(authController.isAuthenticated, false);
      expect(authController.errorMessage, contains('Incorrect email/password'));
    });

    test('Register user success', () async {
      final result = await authController.registerWithEmail(
        'new@abc.com',
        'password123',
        'New Member',
      );
      expect(result, true);
      expect(authController.isAuthenticated, true);
      expect(authController.currentUser?.displayName, 'New Member');
    });

    test('Logout clears user and guest mode', () async {
      await authController.loginWithEmail('test@abc.com', 'pass');
      expect(authController.isAuthenticated, true);

      await authController.logout();
      expect(authController.isAuthenticated, false);
      expect(authController.currentUser, isNull);
      expect(authController.isGuestMode, false);
      expect(authController.hasAccess, false);
    });
  });

  group('ProfileController Tests', () {
    late FakeProfileService profileService;
    late ProfileController profileController;

    setUp(() {
      profileService = FakeProfileService();
      profileController = ProfileController(profileService: profileService);
    });

    tearDown(() {
      profileController.dispose();
      profileService.dispose();
    });

    test('Binding null user clears profile', () {
      profileController.bindUser(null);
      expect(profileController.profile, isNull);
    });

    test('Binding valid user initializes profile', () async {
      final user = AppUser(
        uid: 'user-xyz',
        email: 'xyz@test.com',
        displayName: 'XYZ User',
      );

      profileController.bindUser(user);
      // Wait for stream event
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(profileController.profile, isNotNull);
      expect(profileController.profile?.uid, 'user-xyz');
      expect(profileController.profile?.displayName, 'XYZ User');
    });

    test('Updating display name saves to service', () async {
      final user = AppUser(
        uid: 'user-xyz',
        email: 'xyz@test.com',
        displayName: 'Initial Name',
      );
      profileController.bindUser(user);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await profileController.updateDisplayName('Updated Name');
      expect(profileController.profile?.displayName, 'Updated Name');
    });

    test('Recording optimization stats updates profile counters', () async {
      final user = AppUser(
        uid: 'user-xyz',
        email: 'xyz@test.com',
        displayName: 'XYZ User',
      );
      profileController.bindUser(user);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await profileController.recordJunkCleaned(1048576); // 1 MB
      await profileController.recordRamOptimized();
      await profileController.recordDnsSwitch();

      expect(profileController.profile?.totalCleanedBytes, 1048576);
      expect(profileController.profile?.totalRamOptimizations, 1);
      expect(profileController.profile?.totalDnsSwitches, 1);
    });
  });
}
