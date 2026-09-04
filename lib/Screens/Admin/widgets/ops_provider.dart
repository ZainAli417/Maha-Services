import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/admin/assessment_ops.dart';

/// Streams the four collections the admin's own work lives in and turns them
/// into an [AssessmentOps].
///
/// All four are single-collection snapshots with no `where` clause, so none of
/// them needs an index and all of them stay live. The arithmetic is entirely in
/// [AssessmentOps], which is pure — this class only translates documents.
class AdminOpsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<OpsRequest> _requests = const [];
  List<OpsAssessment> _assessments = const [];
  List<OpsPaper> _papers = const [];
  List<OpsInterview> _interviews = const [];

  bool _requestsIn = false;
  bool _assessmentsIn = false;

  /// True until the two collections the funnel cannot be read without have
  /// arrived. Papers and interviews only add prompts, so the panel is useful
  /// before they land and must not be held back for them.
  bool get loading => !(_requestsIn && _assessmentsIn);

  String error = '';

  final _subs = <StreamSubscription>[];

  /// Rebuilt on every read so the time-based prompts ("expires within 6 hours")
  /// are measured against now rather than against whenever the stream last
  /// fired.
  AssessmentOps get ops => AssessmentOps(
        requests: _requests,
        assessments: _assessments,
        papers: _papers,
        interviews: _interviews,
        now: DateTime.now(),
      );

  void start() {
    if (_subs.isNotEmpty) return;

    _subs.add(_db.collection('recruiter_requests').snapshots().listen((snap) {
      _requests = [
        for (final doc in snap.docs) _request(doc.id, doc.data()),
      ];
      _requestsIn = true;
      notifyListeners();
    }, onError: _onError));

    _subs.add(_db.collection('assessments').snapshots().listen((snap) {
      _assessments = [
        for (final doc in snap.docs) _assessment(doc.data()),
      ];
      _assessmentsIn = true;
      notifyListeners();
    }, onError: _onError));

    _subs.add(_db.collection('question_banks').snapshots().listen((snap) {
      _papers = [
        for (final doc in snap.docs)
          (
            jobId: doc.id,
            status: (doc.data()['status'] ?? 'draft').toString(),
            questionCount:
                (doc.data()['questionCount'] as num?)?.toInt() ?? 0,
          ),
      ];
      notifyListeners();
    }, onError: _onError));

    _subs.add(_db.collection('interviews').snapshots().listen((snap) {
      _interviews = [
        for (final doc in snap.docs) ?_interview(doc.data()),
      ];
      notifyListeners();
    }, onError: _onError));
  }

  void _onError(Object e) {
    error = 'Could not read the operations board: $e';
    notifyListeners();
  }

  OpsRequest _request(String id, Map<String, dynamic> d) {
    final candidates = (d['candidate_ids'] as List?)?.length ??
        (d['candidates'] as List?)?.length ??
        (d['total_candidates'] as num?)?.toInt() ??
        0;

    // The job is read off the candidates rather than stored on the request, so
    // there is one copy of it and nothing to drift.
    var jobId = '';
    var jobTitle = '';
    for (final raw in (d['candidates'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final c = Map<String, dynamic>.from(raw);
      if (jobId.isEmpty) jobId = (c['job_id'] ?? '').toString();
      if (jobTitle.isEmpty) jobTitle = (c['job_title'] ?? '').toString();
      if (jobId.isNotEmpty && jobTitle.isNotEmpty) break;
    }

    return (
      requestId: id,
      jobId: jobId,
      jobTitle: jobTitle,
      candidates: candidates,
      status: (d['status'] ?? 'pending').toString(),
      releasedScores: (d['assessment_summary'] as Map? ?? const {}).length,
      kept: (d['final_selection'] as List? ?? const []).length,
    );
  }

  OpsAssessment _assessment(Map<String, dynamic> d) {
    final result = d['result'] is Map
        ? Map<String, dynamic>.from(d['result'] as Map)
        : const <String, dynamic>{};
    final integrity = d['integrity'] is Map
        ? Map<String, dynamic>.from(d['integrity'] as Map)
        : const <String, dynamic>{};

    return (
      requestId: (d['requestId'] ?? '').toString(),
      jobId: (d['jobId'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      percentage: (result['percentage'] as num?)?.toInt(),
      verdict: (result['verdict'] ?? '').toString(),
      released: d['releasedToRecruiterAt'] != null,
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      tabSwitches: (integrity['tabSwitches'] as num?)?.toInt() ?? 0,
    );
  }

  /// Null for a document with no usable time — an interview without one cannot
  /// be reasoned about, and defaulting it to now would invent an urgent
  /// warning out of a broken record.
  OpsInterview? _interview(Map<String, dynamic> d) {
    final at = d['scheduledAt'];
    final when = at is Timestamp
        ? at.toDate()
        : (at is String ? DateTime.tryParse(at) : null);
    if (when == null) return null;
    return (
      requestId: (d['requestId'] ?? '').toString(),
      hasLink: (d['meetingLink'] ?? '').toString().trim().isNotEmpty,
      scheduledAt: when,
      status: (d['status'] ?? 'requested').toString(),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
