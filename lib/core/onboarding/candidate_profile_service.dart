import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'models/candidate_profile.dart';

/// Reads and writes [CandidateProfile] documents.
///
/// Storage lives on the existing candidate document — `Job_Seeker/{uid}` — under
/// a `candidateProfile` key, so no new Firestore rules are needed: the owner
/// already has write access and recruiters already have read access for search
/// and matching.
///
/// [submit] also mirrors onto the legacy `user_data.*` layout, which recruiter
/// shortlisting, AI matching and the CV generator still read. The mirror is
/// derived — `candidateProfile` is the single source of truth. There is no
/// separate questionnaire document: the role template *is* the questionnaire,
/// and the answers live in `candidateProfile.answers`.
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
      final raw = snap.data()?[_field];
      if (raw is Map) {
        return CandidateProfile.fromJson(uid, Map<String, dynamic>.from(raw));
      }
    } catch (e) {
      debugPrint('⚠️ CandidateProfileService.load: $e');
    }
    return null;
  }

  Stream<CandidateProfile?> watch(String uid) => _doc(uid).snapshots().map((s) {
        final raw = s.data()?[_field];
        if (raw is Map) {
          return CandidateProfile.fromJson(uid, Map<String, dynamic>.from(raw));
        }
        return null;
      });

  /// Persists a draft (auto-save). Merges, so a partially built profile never
  /// clobbers sections the candidate has not reached yet.
  Future<void> saveDraft(CandidateProfile profile) async {
    await _doc(profile.uid).set({
      _field: profile.copyWith(onboardingStatus: OnboardingStatus.draft).toJson(),
    }, SetOptions(merge: true));
  }

  /// Finalizes onboarding: marks the profile complete, mirrors it onto the
  /// legacy layout and flips the `users/{uid}` gating flags.
  Future<void> submit(CandidateProfile profile) async {
    final completed = profile.copyWith(
      onboardingStatus: OnboardingStatus.completed,
    );

    await _doc(profile.uid).set({
      _field: completed.toJson(),
      'user_data': _legacyUserData(completed),
    }, SetOptions(merge: true));

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

  /// Writes an edit made from the profile manager.
  ///
  /// Deliberately narrower than [submit]: it refreshes `candidateProfile` and
  /// the scalar half of the legacy `personalProfile` mirror, but never the
  /// `user_data` arrays. Firestore replaces arrays wholesale on a merge, so
  /// rewriting them here would discard experience, education and certification
  /// rows the legacy profile editors own.
  Future<void> updateRoleSections(CandidateProfile profile) async {
    await _doc(profile.uid).set({
      _field: profile.toJson(),
      'user_data': {'personalProfile': _legacyPersonalProfile(profile)},
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

  // ── Legacy mirrors ────────────────────────────────────────────────────────

  /// The scalar half of the legacy `personalProfile` map. Keys are exactly the
  /// ones the recruiter applicant list, the admin candidate panel and the CV
  /// generator read, so a candidate onboarded through a template renders the
  /// same as a legacy one.
  Map<String, dynamic> _legacyPersonalProfile(CandidateProfile p) {
    final personal = p.personalInfo;
    return {
      'name': personal.fullName,
      'fullName': personal.fullName,
      'email': personal.email,
      'secondary_email': personal.secondaryEmail,
      'contactNumber': personal.phone,
      'nationality': personal.citizenship.isEmpty
          ? personal.location.country
          : personal.citizenship.first,
      'location': personal.location.display,
      'dob': personal.dateOfBirth,
      'summary': personal.summary,
      'objectives': personal.summary,
      'socialLinks': personal.socialLinks,
      if (personal.profilePicUrl.isNotEmpty)
        'profilePicUrl': personal.profilePicUrl,
      'skills': [
        ...p.roleSpecificData.technicalCompetencies,
        ...p.roleSpecificData.toolsAndSystems,
      ],
    };
  }

  /// Shapes the new schema into the `user_data` layout the profile manager,
  /// recruiter cards and CV generator already read.
  Map<String, dynamic> _legacyUserData(CandidateProfile p) {
    return {
      'personalProfile': _legacyPersonalProfile(p),
      'professionalProfile': {'summary': p.personalInfo.summary},
      'educationalProfile': [
        for (final e in p.education)
          {
            'institutionName': e.institution,
            'duration': e.graduationYear?.toString() ?? '',
            'majorSubjects': e.fieldOfStudy,
            'marksOrCgpa': '',
            'degree': e.degree,
          },
      ],
      'professionalExperience': [
        for (final x in p.experience)
          {
            'organization': x.company,
            'role': x.title,
            'location': x.location,
            'startDate': x.startDate,
            'endDate': x.endDate ?? (x.isCurrent ? 'Present' : ''),
            'duration': _duration(x),
            'duties': x.responsibilities.join('\n'),
          },
      ],
      'certifications': [
        for (final c in p.certifications)
          {'name': c.name, 'organization': c.issuer},
        for (final l in p.roleSpecificData.licensesAndRatings)
          {'name': l.title, 'organization': l.issuingAuthority},
      ],
    };
  }

  static String _duration(ExperienceEntry x) {
    final end = x.isCurrent ? 'Present' : (x.endDate ?? '');
    if (x.startDate.isEmpty && end.isEmpty) return '';
    return '${x.startDate} - $end';
  }
}
