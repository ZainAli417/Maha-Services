// lib/providers/list_applied_jobs_provider.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ListAppliedJobsProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Real‑time subscription to the user’s applied_jobs collection
  StreamSubscription<QuerySnapshot>? _appsSub;

  /// One subscription per jobId to its Posted_jobs_public/{jobId} doc
  final Map<String, StreamSubscription<DocumentSnapshot>>
  _jobDocSubs = {};

  /// Raw snapshots of applied_docs
  List<QueryDocumentSnapshot> _appliedDocs = [];

  /// Latest jobData cache
  final Map<String, Map<String, dynamic>> _jobDataMap = {};

  bool _isLoading = true;
  String? _error;

  List<_AppRecord> _applications = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<_AppRecord> get applications => List.unmodifiable(_applications);

  ListAppliedJobsProvider() {
    _startListeners();
  }

  void _startListeners() {
    final user = _auth.currentUser;
    if (user == null) {
      _error = 'Not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _appsSub = _firestore
        .collection('applications')
        .doc(user.uid)
        .collection('applied_jobs')
        .orderBy('appliedAt', descending: true)
        .snapshots()
        .listen((snap) {
      _appliedDocs = snap.docs;
      _subscribeToJobDocs(_extractJobIds());
    }, onError: (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  List<String> _extractJobIds() {
    return _appliedDocs
        .map((d) => (d.data() as Map<String, dynamic>)['jobId'] as String)
        .toSet()
        .toList();
  }

  void _subscribeToJobDocs(List<String> jobIds) {
    // 1) Cancel listeners for jobs no longer in the list
    final removed = _jobDocSubs.keys.where((id) => !jobIds.contains(id));
    for (var id in removed) {
      _jobDocSubs[id]!.cancel();
      _jobDocSubs.remove(id);
      _jobDataMap.remove(id);
    }

    // 2) Add listeners for new jobIds
    for (var id in jobIds) {
      if (_jobDocSubs.containsKey(id)) continue;
      final sub = _firestore
          .collection('Posted_jobs_public')
          .doc(id)
          .snapshots()
          .listen((docSnap) {
        if (docSnap.exists) {
          _jobDataMap[id] =
          docSnap.data() as Map<String, dynamic>;
        } else {
          _jobDataMap.remove(id);
        }
        _rebuildRecords();
      }, onError: (e) {
        // ignore single‑doc errors
        debugPrint('Job doc listener error for $id: $e');
      });
      _jobDocSubs[id] = sub;
    }

    // 3) Build initial records
    _rebuildRecords();
  }

  void _rebuildRecords() {
    final List<_AppRecord> recs = [];

    for (var doc in _appliedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final jid = data['jobId'] as String;
      final jobData = _jobDataMap[jid];
      if (jobData == null) continue;

      // parse dates robustly
      DateTime parseDate(String s) {
        try {
          return DateTime.parse(s);
        } catch (_) {}
        try {
          return DateFormat('MM/dd/yy').parse(s);
        } catch (_) {}
        return DateFormat('MM/dd/yyyy').parse(s);
      }

      DateTime parseAppliedAt(dynamic v) {
        if (v is Timestamp) return v.toDate();
        if (v is String) return DateTime.parse(v);
        throw Exception('Invalid appliedAt type');
      }

      recs.add(_AppRecord(
        jobId:        jid,
        title:        jobData['title'] ?? '—',
        company:      jobData['company'] ?? '—',
        contactEmail: jobData['contactEmail'] ?? '—',
        createdAt:    parseDate(jobData['createdAt'] ?? ''),
        deadline:     parseDate(jobData['deadline'] ?? ''),
        appliedAt:    parseAppliedAt(data['appliedAt']),
        status:       data['status'] ?? 'pending',
      ));
    }

    // Sort by appliedAt descending
    recs.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

    _applications = recs;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _appsSub?.cancel();
    for (var sub in _jobDocSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
  /// Cancel all existing listeners and restart them from scratch.
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // 1) cancel the user’s applied‐jobs listener
    await _appsSub?.cancel();

    // 2) cancel all per‐job listeners
    for (var sub in _jobDocSubs.values) {
      await sub.cancel();
    }
    _jobDocSubs.clear();
    _jobDataMap.clear();
    _appliedDocs = [];

    // 3) restart
    _startListeners();
  }

}


/// Internal model for displaying in the UI
class _AppRecord {
  final String jobId;
  final String title;
  final String company;
  final String contactEmail;
  final DateTime createdAt;
  final DateTime deadline;
  final DateTime appliedAt;
  final String status;

  _AppRecord({
    required this.jobId,
    required this.title,
    required this.company,
    required this.contactEmail,
    required this.createdAt,
    required this.deadline,
    required this.appliedAt,
    required this.status,
  });
}
