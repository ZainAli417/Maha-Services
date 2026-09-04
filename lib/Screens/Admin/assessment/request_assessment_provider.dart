import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../services/backend_api.dart';
import 'assessment_models.dart';

/// The assessment as it appears on one recruiter request.
///
/// This is deliberately narrow. It knows how one batch of candidates is doing
/// on their test, how to invite them, and how to send their scores back — and
/// nothing about building question papers. The paper belongs to the *job*, is
/// written once, and is managed on its own screen; a request just uses it.
/// Mixing the two is what put candidates on the question-bank screen and a
/// "generate a paper" button in front of people who had already sat the test.
///
/// Reads run over Firestore so the board is live without polling. Every write
/// goes through the backend, because the backend is the only thing holding the
/// answer key and the only clock worth trusting.
class RequestAssessmentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _requestId = '';
  String get requestId => _requestId;

  String _jobId = '';
  String get jobId => _jobId;

  /// Whether an approved paper exists for this request's job.
  ///
  /// Three states, not two: approved, not yet approved, and unknown because
  /// the backend could not be reached. The third one used to be reported as
  /// the second, which told admins there was no paper when there was one.
  bool? _paperApproved;
  bool? get paperApproved => _paperApproved;

  bool _backendReachable = true;
  bool get backendReachable => _backendReachable;

  List<AssessmentRow> _rows = const [];
  List<AssessmentRow> get rows => _rows;

  int passMark = 60;

  bool _busy = false;
  bool get busy => _busy;

  String _error = '';
  String get error => _error;

  String _notice = '';
  String get notice => _notice;

  StreamSubscription? _boardSub;

  /// Row for one candidate, or null if they have never been invited.
  AssessmentRow? rowFor(String candidateUid) {
    for (final r in _rows) {
      if (r.candidateUid == candidateUid) return r;
    }
    return null;
  }

  bool isInvited(String uid) => rowFor(uid) != null;
  bool hasScore(String uid) => rowFor(uid)?.percentage != null;
  bool isReleased(String uid) => rowFor(uid)?.released == true;

  int get invitedCount => _rows.length;
  int get submittedCount => _rows.where((r) => r.isDone).length;
  int get scoredCount => _rows.where((r) => r.percentage != null).length;
  int get releasedCount => _rows.where((r) => r.released).length;

  /// Starts watching one request's assessments.
  Future<void> open({required String requestId, required String jobId}) async {
    if (_requestId == requestId && _jobId == jobId) return;
    _requestId = requestId;
    _jobId = jobId;
    _error = '';
    _notice = '';
    _rows = const [];
    notifyListeners();

    _watchBoard(requestId);
    await _checkPaper();
  }

  void _watchBoard(String requestId) {
    _boardSub?.cancel();
    // Single-field equality, so no composite index is needed. Ordering happens
    // in memory for the same reason.
    _boardSub = _db
        .collection('assessments')
        .where('requestId', isEqualTo: requestId)
        .snapshots()
        .listen((snap) {
      _rows = snap.docs.map(AssessmentRow.fromDoc).toList()
        ..sort((a, b) {
          final ap = a.percentage, bp = b.percentage;
          if (ap != null && bp != null) return bp.compareTo(ap);
          if (ap != null) return -1;
          if (bp != null) return 1;
          return a.candidateName.compareTo(b.candidateName);
        });
      notifyListeners();
    }, onError: (Object e) {
      _error = 'Could not read the assessment board: $e';
      notifyListeners();
    });
  }

  Future<void> _checkPaper() async {
    if (_jobId.isEmpty) {
      _paperApproved = false;
      return;
    }
    try {
      final data = await BackendApi.get('/assessment/bank/$_jobId');
      _backendReachable = true;
      _paperApproved = QuestionBank.fromJson(data).isApproved;
    } on BackendException catch (e) {
      // A 404 is an answer — there is no paper for this job yet. Any other
      // status means the question was asked and not answered, which is a third
      // state and must not be collapsed into either of the first two.
      _backendReachable = true;
      if (e.statusCode == 404) {
        _paperApproved = false;
      } else {
        _paperApproved = null;
        _error = e.message;
      }
    } catch (_) {
      _backendReachable = false;
      _paperApproved = null;
    }
    notifyListeners();
  }

  /// Invites [uids] to sit the test. One backend call for the whole batch.
  Future<bool> invite(List<String> uids) async {
    if (uids.isEmpty) return false;
    _busy = true;
    _error = '';
    _notice = '';
    notifyListeners();
    try {
      final data = await BackendApi.post(
        '/assessment/invite',
        {
          'requestId': _requestId,
          'jobId': _jobId,
          'candidateUids': uids,
          'passMark': passMark,
        },
        timeout: const Duration(seconds: 90),
      );
      final skipped = (data['skipped'] as List?)?.length ?? 0;
      _notice = 'Invited ${data['invited']} candidate(s), '
          '${data['emailed']} emailed'
          '${skipped > 0 ? ', $skipped already had an invitation' : ''}.';
      return true;
    } on BackendException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Invites failed — the assessment backend did not answer.';
      _backendReachable = false;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Sends the scores of [uids] to the recruiter, with [note].
  ///
  /// Only the named candidates. An admin who picks six out of ten is making a
  /// judgement, and releasing all ten would quietly overrule it.
  Future<bool> release({
    required List<String> uids,
    required String note,
  }) async {
    if (uids.isEmpty) return false;
    _busy = true;
    _error = '';
    _notice = '';
    notifyListeners();
    try {
      final data = await BackendApi.post('/assessment/release', {
        'requestId': _requestId,
        'candidateUids': uids,
        'note': note,
      });
      _notice = 'Sent ${data['scored']} score(s) to the recruiter.';
      return true;
    } on BackendException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Release failed — the assessment backend did not answer.';
      _backendReachable = false;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void setPassMark(int v) {
    passMark = v.clamp(0, 100);
    notifyListeners();
  }

  void clearMessages() {
    _error = '';
    _notice = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _boardSub?.cancel();
    super.dispose();
  }
}
