import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'models/candidate_profile.dart';

/// Reads and writes [CandidateProfile] documents.
///
/// Storage is `Job_Seeker/{uid}.candidateProfile`, and that field is the whole
/// story: there is no `user_data` mirror, no separate questionnaire document
/// and no second copy of anything. The role template *is* the questionnaire,
/// and the answers live in `candidateProfile.answers`.
///
/// Every write goes through this class so there is exactly one place that
/// decides what a candidate document looks like.
class CandidateProfileService {
  CandidateProfileService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _collection = 'Job_Seeker';
  static const _field = 'candidateProfile';

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(_collection).doc(uid);

  /// Loads the candidate's profile, or null when onboarding never started.
  Future<CandidateProfile?> load(String uid) async {
    try {
      final snap = await _doc(uid).get();
      return parse(uid, snap.data());
    } catch (e) {
      debugPrint('⚠️ CandidateProfileService.load: $e');
    }
    return null;
  }

  Stream<CandidateProfile?> watch(String uid) =>
      _doc(uid).snapshots().map((s) => parse(uid, s.data()));

  /// Reads the profile out of a raw `Job_Seeker/{uid}` snapshot.
  ///
  /// Shared with every screen that already holds the document — the admin
  /// candidate list, the analytics aggregator — so none of them has to know
  /// which key the profile lives under.
  static CandidateProfile? parse(String uid, Map<String, dynamic>? doc) {
    final raw = doc?[_field];
    if (raw is! Map) return null;
    return CandidateProfile.fromJson(uid, Map<String, dynamic>.from(raw));
  }

  /// Persists a draft (auto-save).
  ///
  /// The whole profile is written every time rather than merged field by
  /// field. Firestore replaces arrays wholesale on a merge anyway, so a
  /// partial write is the thing that loses rows, not the full one.
  Future<void> saveDraft(CandidateProfile profile) => _write(
        profile.copyWith(onboardingStatus: OnboardingStatus.draft),
      );

  /// Writes an edit made from the profile manager.
  Future<void> save(CandidateProfile profile) => _write(profile);

  /// Finalizes onboarding: marks the profile complete and flips the
  /// `users/{uid}` gating flags the router reads.
  Future<void> submit(CandidateProfile profile) async {
    final completed = profile.copyWith(
      onboardingStatus: OnboardingStatus.completed,
    );
    await _write(completed);

    await _firestore.collection('users').doc(profile.uid).set({
      'isNew': 'no',
      'onboarding_completed': true,
      'onboarding_status': OnboardingStatus.completed.toJson(),
      'targetRole': completed.targetRole.toJson(),
      if (completed.personalInfo.fullName.isNotEmpty)
        'name': completed.personalInfo.fullName,
      'profileCompletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Records draft progress on `users/{uid}` so the router can tell a resumable
  /// draft from a never-started onboarding without reading the candidate doc.
  Future<void> markDraftStarted(String uid, TargetRole role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'onboarding_status': OnboardingStatus.draft.toJson(),
        'targetRole': role.toJson(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ CandidateProfileService.markDraftStarted: $e');
    }
  }

  Future<void> _write(CandidateProfile profile) => _doc(profile.uid).set({
        'uid': profile.uid,
        _field: profile.toJson(),
      }, SetOptions(merge: true));
}
