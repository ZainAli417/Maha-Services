import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SavedJobsProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _savedSub;
  final Set<String> _savedJobIds = {};
  bool _isLoading = true;
  String? _error;

  SavedJobsProvider() {
    _authSub = _auth.authStateChanges().listen(_handleAuthChange);
    _handleAuthChange(_auth.currentUser);
  }

  Set<String> get savedJobIds => Set.unmodifiable(_savedJobIds);
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isSaved(String jobId) => _savedJobIds.contains(jobId);

  Future<void> _handleAuthChange(User? user) async {
    await _savedSub?.cancel();
    _savedSub = null;
    _savedJobIds.clear();

    if (user == null) {
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    _savedSub = _firestore
        .collection('Job_Seeker')
        .doc(user.uid)
        .collection('saved_jobs')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .listen(
          (snap) {
            _savedJobIds
              ..clear()
              ..addAll(snap.docs.map((doc) => doc.id));
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> toggleSaved(Map<String, dynamic> jobData) async {
    final user = _auth.currentUser;
    final jobId = jobData['id']?.toString();
    if (user == null || jobId == null || jobId.isEmpty) return;

    final ref = _firestore
        .collection('Job_Seeker')
        .doc(user.uid)
        .collection('saved_jobs')
        .doc(jobId);

    if (_savedJobIds.contains(jobId)) {
      await ref.delete();
      return;
    }

    await ref.set({
      'jobId': jobId,
      'title': jobData['title'] ?? '',
      'company': jobData['company'] ?? '',
      'department': jobData['department'] ?? '',
      'location': jobData['location'] ?? '',
      'recruiterUid': jobData['recruiterUid'] ?? '',
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _savedSub?.cancel();
    super.dispose();
  }
}
