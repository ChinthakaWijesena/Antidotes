import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/profile_service.dart';
import '../../../auth/data/models/app_user.dart';

class ProfileController extends ChangeNotifier {
  final ProfileService _profileService;
  StreamSubscription<UserProfile?>? _profileSub;

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileController({required ProfileService profileService})
      // ignore: prefer_initializing_formals
      : _profileService = profileService;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void bindUser(AppUser? user) {
    _profileSub?.cancel();
    if (user == null) {
      _profile = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _profileSub = _profileService.streamUserProfile(user.uid).listen(
      (userProfile) async {
        if (userProfile == null) {
          // Create initial cloud profile for user if first time
          final initial = UserProfile(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoUrl,
            createdAt: user.createdAt ?? DateTime.now(),
            lastActiveAt: DateTime.now(),
          );
          await _profileService.saveUserProfile(initial);
          _profile = initial;
        } else {
          _profile = userProfile;
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> updateDisplayName(String newName) async {
    if (_profile == null) return;
    final updated = _profile!.copyWith(
      displayName: newName,
      lastActiveAt: DateTime.now(),
    );
    _profile = updated;
    notifyListeners();
    await _profileService.saveUserProfile(updated);
  }

  Future<void> recordJunkCleaned(int bytes) async {
    if (_profile == null || bytes <= 0) return;
    await _profileService.recordJunkCleaned(_profile!.uid, bytes);
  }

  Future<void> recordRamOptimized() async {
    if (_profile == null) return;
    await _profileService.recordRamOptimized(_profile!.uid);
  }

  Future<void> recordDnsSwitch() async {
    if (_profile == null) return;
    await _profileService.recordDnsSwitch(_profile!.uid);
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }
}
