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
        ..addAll(userApps.docs.map((doc) => doc.data()['jobId'] as String));
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

    // 2️⃣ Server-side guard
    final appliedRef = _firestore
        .collection('applications')
        .doc(user.uid)
        .collection('applied_jobs');
    try {
      final existing = await appliedRef
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        _errorMessage = 'You have already applied to this job.';
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('applyForJob: server-side guard failed: $e');
    }

    // 3️⃣ Begin apply flow - SET SPECIFIC JOB ID ✅
    _currentlyApplyingJobId = jobId;  // ← CHANGED
    _errorMessage = null;
    notifyListeners();

    try {
      final seekerRef = _firestore.collection('job_seeker').doc(user.uid);
      final seekerSnap = await seekerRef.get();

      if (!seekerSnap.exists) {
        throw Exception('Seeker profile not found at job_seeker/${user.uid}.');
      }

      final seekerDoc = seekerSnap.data()!;
      final mainData = seekerDoc['user_data'] ?? <String, dynamic>{};
      final subProfiles = seekerDoc['user_profile'] ?? <String, dynamic>{};

      final applicationData = {
        'userId': user.uid,
        'jobId': jobId,
        'appliedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'profileSnapshot': {
          'user_Account_Data': Map<String, dynamic>.from(mainData),
          'user_Profile_Sections': Map<String, dynamic>.from(subProfiles),
        },
      };

      final batch = _firestore.batch();
      final newAppRef = appliedRef.doc();
      batch.set(newAppRef, applicationData);

      final jobRef = _firestore.collection('Posted_jobs_public').doc(jobId);

      try {
        batch.update(jobRef, {
          'applicationCount': FieldValue.increment(1),
          'viewCount': FieldValue.increment(1),
        });
        await batch.commit();
      } catch (e) {
        debugPrint('applyForJob: batch.update failed: $e');
        final fallbackBatch = _firestore.batch();
        fallbackBatch.set(newAppRef, applicationData);
        fallbackBatch.set(jobRef, {
          'applicationCount': FieldValue.increment(1),
          'viewCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
        await fallbackBatch.commit();
      }

      _appliedJobs.add(jobId);
      _errorMessage = null;
    } catch (e, st) {
      debugPrint('applyForJob error: $e\n$st');
      _errorMessage = e.toString();
    } finally {
      _currentlyApplyingJobId = null;  // ← CHANGED
      notifyListeners();
    }
  }
}
