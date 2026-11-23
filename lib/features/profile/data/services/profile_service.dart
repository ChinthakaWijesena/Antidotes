import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

abstract class ProfileService {
  Future<UserProfile?> getUserProfile(String uid);
  Stream<UserProfile?> streamUserProfile(String uid);
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> recordJunkCleaned(String uid, int bytes);
  Future<void> recordRamOptimized(String uid);
  Future<void> recordDnsSwitch(String uid);
}

class FirestoreProfileService implements ProfileService {
  final FirebaseFirestore _firestore;

  FirestoreProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  @override
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCol.doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserProfile.fromMap(doc.data()!, defaultUid: uid);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<UserProfile?> streamUserProfile(String uid) {
    return _usersCol.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, defaultUid: uid);
    });
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _usersCol.doc(profile.uid).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> recordJunkCleaned(String uid, int bytes) async {
    if (bytes <= 0) return;
    try {
      await _usersCol.doc(uid).set({
        'totalCleanedBytes': FieldValue.increment(bytes),
        'lastActiveAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> recordRamOptimized(String uid) async {
    try {
      await _usersCol.doc(uid).set({
        'totalRamOptimizations': FieldValue.increment(1),
        'lastActiveAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<void> recordDnsSwitch(String uid) async {
    try {
      await _usersCol.doc(uid).set({
        'totalDnsSwitches': FieldValue.increment(1),
        'lastActiveAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
