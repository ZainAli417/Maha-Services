// lib/providers/job_applications_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/onboarding/models/candidate_profile.dart';
import '../../core/onboarding/role_profile_snapshot.dart';
import '../../core/onboarding/role_template_service.dart';

class JobApplicationsProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RoleTemplateService _templates = RoleTemplateService();

  String? _errorMessage;
  final Set<String> _appliedJobs = {};

  String? _currentlyApplyingJobId;
  bool isApplyingTo(String jobId) => _currentlyApplyingJobId == jobId;

  String? get errorMessage => _errorMessage;
  bool hasApplied(String jobId) => _appliedJobs.contains(jobId);
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Keys inside `candidateProfile.personalInfo` that would let a recruiter
  /// contact the candidate directly.
  ///
  /// Kept in one place so the apply path and any future snapshot writer agree
  /// on what "contact details" means.
  static const _contactKeys = {
    'email',
    'secondaryEmail',
    'phone',
    'dateOfBirth',
    'socialLinks',
  };

  /// Copies the candidate profile for the application snapshot with every
  /// contact field removed from `personalInfo`.
  ///
  /// Recruiters read this snapshot to screen and shortlist, which needs
  /// skills, experience and role data — not a direct line to the candidate.
  /// Contact details reach the admin, who arranges interviews and travel, by a
  /// separate read of Job_Seeker/{uid} that recruiters have no access to.
  /// Redacting here rather than in the UI means the recruiter's client never
  /// receives the values at all, so there is nothing to recover from the
  /// network response.
  @visibleForTesting
  static Map<String, dynamic> withoutContactDetails(dynamic candidateProfile) {
    if (candidateProfile is! Map) return <String, dynamic>{};
    final copy = Map<String, dynamic>.from(candidateProfile);

    final personal = copy['personalInfo'];
    if (personal is Map) {
      copy['personalInfo'] = Map<String, dynamic>.from(personal)
        ..removeWhere((k, _) => _contactKeys.contains(k));
    }

    // `answers` holds the raw response to every template question, contact
    // questions included. The recruiter-facing rendering of those answers is
    // `role_profile`, which is built with the same exclusions; the raw map has
    // no reader on the recruiter side and every reason not to travel.
    copy.remove('answers');
    return copy;
  }

  /// Flattens the candidate's role-template answers for the application
  /// snapshot. Returns null for accounts that predate the template engine —
  /// the recruiter UI renders those from the legacy sections alone.
  Future<Map<String, dynamic>?> _buildRoleProfileSnapshot(
    Map<String, dynamic> seekerDoc,
  ) async {
    try {
      final raw = seekerDoc['candidateProfile'];
      if (raw is! Map) return null;
      final profile = CandidateProfile.fromJson(
          seekerDoc['uid']?.toString() ?? '', Map<String, dynamic>.from(raw));
      final roleId = profile.targetRole.roleId;
      if (roleId.isEmpty) return null;

      final template = await _templates.roleById(roleId);
      if (template == null) return null;

      return RoleProfileSnapshot.build(profile, template).toJson();
    } catch (e) {
      // A snapshot failure must never block an application.
      debugPrint('⚠️ role profile snapshot skipped: $e');
      return null;
    }
  }

  /// Load all job IDs the current user has applied to.
  Future<void> loadAppliedJobs() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userApps = await _firestore
          .collection('applications')
          .doc(user.uid)
          .collection('applied_jobs')
          .get();

      _appliedJobs
        ..clear()
        ..addAll(
          userApps.docs.map((doc) {
            final data = doc.data();
            return (data['jobId'] ?? doc.id).toString();
          }),
        );
      notifyListeners();
    } catch (e) {
      debugPrint('loadAppliedJobs error: $e');
    }
  }

  /// Apply to [jobId], take a snapshot of the seeker profile,
  /// and atomically increment both counters.
  Future<void> applyForJob(String jobId) async {
    final user = _auth.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to apply.';
      notifyListeners();
      return;
    }

    // 1️⃣ Local guard
    if (hasApplied(jobId)) {
      _errorMessage = 'You have already applied to this job.';
      notifyListeners();
      return;
    }

    final appliedRef = _firestore
        .collection('applications')
        .doc(user.uid)
        .collection('applied_jobs');
    final applicationRef = appliedRef.doc(jobId);

    final existing = await applicationRef.get();
    if (existing.exists) {
      _errorMessage = 'You have already applied to this job.';
      _appliedJobs.add(jobId);
      notifyListeners();
      return;
    }

    // 3️⃣ Set loading state
    _currentlyApplyingJobId = jobId;
    _errorMessage = null;
    notifyListeners();

    try {
      // 4️⃣ FETCH THE JOB DOCUMENT TO GET RECRUITER UID
      // We need the recruiterUid to know which recruiter's counter to increment
      final jobDocSnap = await _firestore
          .collection('Posted_jobs_public')
          .doc(jobId)
          .get();

      if (!jobDocSnap.exists) {
        throw Exception('Operational error: Job posting not found.');
      }

      final jobData = jobDocSnap.data()!;
      final jobStatus = (jobData['status'] ?? 'active')
          .toString()
          .toLowerCase()
          .trim();
      if (jobStatus != 'active') {
        throw Exception('This job is no longer accepting applications.');
      }

      final String? recruiterUid = jobData['recruiterUid'];

      if (recruiterUid == null || recruiterUid.isEmpty) {
        throw Exception('Operational error: Target recruiter ID missing.');
      }

      // 5️⃣ GET SEEKER PROFILE DATA
      final seekerSnap = await _firestore
          .collection('Job_Seeker')
          .doc(user.uid)
          .get();
      if (!seekerSnap.exists) {
        throw Exception(
          'Seeker profile not found. Please complete your profile.',
        );
      }

      final seekerDoc = seekerSnap.data()!;
      if (seekerDoc['candidateProfile'] is! Map) {
        throw Exception(
          'Your profile is incomplete. Please finish onboarding first.',
        );
      }
      final mainData = withoutContactDetails(seekerDoc['candidateProfile']);
      final roleProfile = await _buildRoleProfileSnapshot(seekerDoc);

      final applicationData = {
        'userId': user.uid,
        'jobId': jobId,
        'recruiterUid': recruiterUid, // Storing for easier querying later
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'profileSnapshot': {
          // Contact details are deliberately absent — see
          // [withoutContactDetails]. Admins read them straight from
          // Job_Seeker/{uid} when they review the shortlist.
          'candidate_profile': mainData,
          // Display-ready copy of the role-template answers, so recruiters and
          // admins can read a candidate's role profile without loading the
          // template — and see exactly what was true on the day they applied,
          // even if an admin edits the template afterwards.
          if (roleProfile != null) 'role_profile': roleProfile,
        },
      };

      // 6️⃣ ATOMIC BATCH OPERATION
      final batch = _firestore.batch();

      // A. Record the application in user's list using a deterministic job ID.
      batch.set(applicationRef, applicationData);

      // B. Increment PUBLIC counter
      final publicJobRef = _firestore
          .collection('Posted_jobs_public')
          .doc(jobId);
      batch.update(publicJobRef, {'applicationCount': FieldValue.increment(1)});

      // Execute the transaction
      await batch.commit();

      _appliedJobs.add(jobId);
      _errorMessage = null;
    } catch (e, st) {
      debugPrint('applyForJob full error: $e\n$st');
      _errorMessage = "Application Failed: ${e.toString()}";
    } finally {
      _currentlyApplyingJobId = null;
      notifyListeners();
    }
  }
}
