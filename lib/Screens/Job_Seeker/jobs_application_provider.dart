// lib/providers/job_applications_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class JobApplicationsProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final mainData = seekerDoc['user_data'] ?? {};
      final subProfiles = seekerDoc['user_profile'] ?? {};

      final applicationData = {
        'userId': user.uid,
        'jobId': jobId,
        'recruiterUid': recruiterUid, // Storing for easier querying later
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'profileSnapshot': {
          'user_Account_Data': Map<String, dynamic>.from(mainData),
          'user_Profile_Sections': Map<String, dynamic>.from(subProfiles),
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
