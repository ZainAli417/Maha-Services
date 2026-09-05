import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/admin/assessment_ops.dart';
import '../../../services/backend_api.dart';

/// Gathers what the admin's own work is made of and turns it into an
/// [AssessmentOps].
///
/// Three live snapshots — requests, sittings, interviews — with no `where`
/// clause, so none of them needs an index. Paper status is the exception: it
/// comes from the backend, because `question_banks` has no Firestore rule at
/// all and is not meant to. Every document in it holds the answer key, so the
/// admin app reads a status summary through `/assessment/banks/summary`
/// instead and never sees a question.
///
/// Each source records its own failure. One of them being unavailable costs
/// the signals that depend on it and nothing else — the board carried three
/// working feeds behind a single error banner once, and it must not again.
///
/// The arithmetic is entirely in [AssessmentOps], which is pure; this class
/// only translates.
class AdminOpsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<OpsRequest> _requests = const [];
  List<OpsAssessment> _assessments = const [];
  List<OpsPaper> _papers = const [];
  List<OpsInterview> _interviews = const [];

  bool _requestsIn = false;
  bool _assessmentsIn = false;
  bool _papersIn = false;

  /// True until the two collections the funnel cannot be read without have
  /// arrived. Papers and interviews only add prompts, so the panel is useful
  /// before they land and must not be held back for them.
  bool get loading => !(_requestsIn && _assessmentsIn);

  /// What could not be read, one line per source. Empty when all is well.
  ///
  /// Held per source rather than as one string so the panel can say which
  /// signal is missing while still showing everything that did arrive.
  final Map<String, String> _failures = {};

  /// The failures worth telling the admin about, as plain sentences.
  List<String> get failures => _failures.values.toList();

  /// True when the funnel itself could not be read — nothing to show at all.
  bool get fatal =>
      _failures.containsKey('requests') || _failures.containsKey('assessments');

  /// The one message to lead with when [fatal].
  String get error => fatal ? failures.first : '';

  /// Whether paper status was actually read. An empty paper list otherwise
  /// reads as "no job has a paper", which would flag every batch as blocked.
  bool get papersKnown => _papersIn;

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
        papersKnown: _papersIn,
      );

  void start() {
    if (_subs.isNotEmpty) return;

    _subs.add(_db.collection('recruiter_requests').snapshots().listen((snap) {
      _requests = [
        for (final doc in snap.docs) _request(doc.id, doc.data()),
      ];
      _requestsIn = true;
      _clear('requests');
    }, onError: (e) => _fail('requests', 'the recruiter batches', e)));

    _subs.add(_db.collection('assessments').snapshots().listen((snap) {
      _assessments = [
        for (final doc in snap.docs) _assessment(doc.data()),
      ];
      _assessmentsIn = true;
      _clear('assessments');
    }, onError: (e) => _fail('assessments', 'the test sittings', e)));

    _subs.add(_db.collection('interviews').snapshots().listen((snap) {
      _interviews = [
        for (final doc in snap.docs) ?_interview(doc.data()),
      ];
      _clear('interviews');
    }, onError: (e) => _fail('interviews', 'the interview diary', e)));

    _loadPapers();
  }

  /// Paper status, from the backend rather than from Firestore.
  ///
  /// A one-off read, not a stream: a question paper is approved a handful of
  /// times a week, and the board is rebuilt whenever the dashboard is opened.
  Future<void> _loadPapers() async {
    try {
      final res = await BackendApi.get('/assessment/banks/summary');
      _papers = [
        for (final raw in (res['banks'] as List? ?? const []))
          if (raw is Map)
            (
              jobId: (raw['jobId'] ?? '').toString(),
              status: (raw['status'] ?? 'draft').toString(),
              questionCount: (raw['questionCount'] as num?)?.toInt() ?? 0,
            ),
      ];
      _papersIn = true;
      _clear('papers');
    } catch (e) {
      _fail('papers', 'the question papers', e);
    }
  }

  /// Records a source as unavailable, in a sentence rather than a stack trace.
  void _fail(String key, String what, Object e) {
    final reason = e is BackendException
        ? e.message
        : (e.toString().contains('permission-denied')
            ? 'this account is not allowed to read it'
            : e.toString());
    _failures[key] = 'Could not read $what — $reason';
    notifyListeners();
  }

  void _clear(String key) {
    _failures.remove(key);
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
