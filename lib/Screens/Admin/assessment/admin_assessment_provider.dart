import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../services/backend_api.dart';

/// One question as the admin reviews it — with the answer, unlike every other
/// view of it in the product.
class BankQuestion {
  BankQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.topic,
    required this.explanation,
  });

  final String id;
  String text;
  List<String> options;
  int correctIndex;
  String difficulty;
  String topic;
  String explanation;

  factory BankQuestion.fromJson(Map<String, dynamic> j) => BankQuestion(
        id: (j['id'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        options: (j['options'] as List?)?.map((o) => o.toString()).toList() ?? const [],
        correctIndex: (j['correctIndex'] as num?)?.toInt() ?? 0,
        difficulty: (j['difficulty'] ?? 'medium').toString(),
        topic: (j['topic'] ?? '').toString(),
        explanation: (j['explanation'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'correctIndex': correctIndex,
        'difficulty': difficulty,
        'topic': topic,
        'explanation': explanation,
      };
}

/// The question bank for one job.
class QuestionBank {
  const QuestionBank({
    required this.jobId,
    required this.jobTitle,
    required this.status,
    required this.questions,
    this.generatedAt,
  });

  final String jobId;
  final String jobTitle;

  /// draft until an admin has read it; approved once they have.
  final String status;
  final List<BankQuestion> questions;
  final DateTime? generatedAt;

  bool get isApproved => status == 'approved';

  Map<String, int> get tierCounts {
    final counts = {'easy': 0, 'medium': 0, 'hard': 0};
    for (final q in questions) {
      counts[q.difficulty] = (counts[q.difficulty] ?? 0) + 1;
    }
    return counts;
  }

  factory QuestionBank.fromJson(Map<String, dynamic> j) => QuestionBank(
        jobId: (j['jobId'] ?? '').toString(),
        jobTitle: (j['jobTitle'] ?? '').toString(),
        status: (j['status'] ?? 'draft').toString(),
        questions: (j['questions'] as List?)
                ?.whereType<Map>()
                .map((m) => BankQuestion.fromJson(Map<String, dynamic>.from(m)))
                .toList() ??
            const [],
        generatedAt: _ts(j['generatedAt']),
      );

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }
}

/// One candidate's sitting, as the admin board shows it.
class AssessmentRow {
  const AssessmentRow({
    required this.assessmentId,
    required this.candidateUid,
    required this.candidateName,
    required this.status,
    required this.answeredCount,
    required this.questionCount,
    this.percentage,
    this.correct,
    this.verdict,
    this.rank,
    this.tabSwitches = 0,
    this.resumes = 0,
    this.submittedAt,
    this.expiresAt,
    this.released = false,
  });

  final String assessmentId, candidateUid, candidateName, status;
  final int answeredCount, questionCount;
  final int? percentage, correct, rank;
  final String? verdict;
  final int tabSwitches, resumes;
  final DateTime? submittedAt, expiresAt;
  final bool released;

  bool get isDone => status == 'submitted';
  double get progress => questionCount == 0 ? 0 : answeredCount / questionCount;

  factory AssessmentRow.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final result = d['result'] is Map
        ? Map<String, dynamic>.from(d['result'] as Map)
        : const <String, dynamic>{};
    final integrity = d['integrity'] is Map
        ? Map<String, dynamic>.from(d['integrity'] as Map)
        : const <String, dynamic>{};

    return AssessmentRow(
      assessmentId: doc.id,
      candidateUid: (d['candidateUid'] ?? '').toString(),
      candidateName: (d['candidateName'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      answeredCount: (d['answeredCount'] as num?)?.toInt() ?? 0,
      questionCount: (d['questionCount'] as num?)?.toInt() ?? 20,
      percentage: (result['percentage'] as num?)?.toInt(),
      correct: (result['correct'] as num?)?.toInt(),
      verdict: result['verdict']?.toString(),
      tabSwitches: (integrity['tabSwitches'] as num?)?.toInt() ?? 0,
      resumes: (integrity['resumes'] as num?)?.toInt() ?? 0,
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate(),
      released: d['releasedToRecruiterAt'] != null,
    );
  }
}

/// The admin's side of the assessment flow: build a paper, review it, invite a
/// batch, watch it happen, send the scores back.
///
/// Reads run over Firestore so the board is live without polling; every write
/// goes through the backend, because the backend is the only thing holding the
/// answer key and the server clock.
class AdminAssessmentProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _requestId;
  String? get requestId => _requestId;

  String _jobId = '';
  String get jobId => _jobId;

  String _jobTitle = '';
  String get jobTitle => _jobTitle;

  List<Map<String, dynamic>> _candidates = const [];
  List<Map<String, dynamic>> get candidates => _candidates;

  QuestionBank? _bank;
  QuestionBank? get bank => _bank;

  /// False when the last backend call did not complete at all.
  ///
  /// Kept apart from [error] so the screen can say "cannot reach the backend"
  /// rather than reporting an empty result as if it were the truth.
  bool _backendReachable = true;
  bool get backendReachable => _backendReachable;

  int _round = 1;
  int get round => _round;

  String _parentRequestId = '';
  String get parentRequestId => _parentRequestId;

  /// A revised batch has already been through the assessment. Its candidates
  /// were picked *because* of their scores, so offering to build a paper and
  /// invite them again would be offering to redo the step that produced them.
  bool get isRevisedBatch => _round >= 2;

  /// Scores the recruiter was sent, carried on the batch that produced them.
  Map<String, dynamic> _carriedScores = const {};
  Map<String, dynamic> get carriedScores => _carriedScores;

  List<AssessmentRow> _rows = const [];
  List<AssessmentRow> get rows => _rows;

  final Set<String> selected = {};

  int passMark = 60;

  bool _busy = false;
  bool get busy => _busy;

  String _error = '';
  String get error => _error;

  String _notice = '';
  String get notice => _notice;

  StreamSubscription? _boardSub;

  bool get scoresReleased => _rows.isNotEmpty && _rows.every((r) => r.released);
  int get submittedCount => _rows.where((r) => r.isDone).length;

  /// Loads one recruiter request and starts watching its assessments.
  Future<void> openRequest(String requestId) async {
    _requestId = requestId;
    _busy = true;
    _error = '';
    selected.clear();
    notifyListeners();

    try {
      final snap = await _db.collection('recruiter_requests').doc(requestId).get();
      final data = snap.data() ?? const {};
      _candidates = (data['candidates'] as List?)
              ?.whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList() ??
          const [];

      // Every candidate in a request applied to the same job, so the job id is
      // read off the batch rather than stored twice and allowed to drift.
      // Taking the first non-empty one rather than [0] blindly: a request
      // assembled from a mixed list would otherwise silently test everyone on
      // one person's job.
      _jobId = _firstNonEmpty(_candidates, 'job_id');
      _jobTitle = _firstNonEmpty(_candidates, 'job_title');
      final jobIds = _candidates
          .map((c) => (c['job_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (jobIds.length > 1) {
        _error = 'This request mixes ${jobIds.length} different jobs. One paper '
            'cannot fairly test all of them — split the request first.';
      }

      _round = (data['round'] as num?)?.toInt() ?? 1;
      _parentRequestId = (data['parent_request_id'] ?? '').toString();
      _carriedScores = await _loadCarriedScores();

      // A revised batch is past the assessment; there is no paper to build for
      // it and nobody to invite, so the backend is not called at all.
      if (!isRevisedBatch) await _loadBank();
      _watchBoard(isRevisedBatch && _parentRequestId.isNotEmpty
          ? _parentRequestId
          : requestId);
    } catch (e) {
      _error = 'Could not open this request: $e';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// The scores this batch was decided on.
  ///
  /// For a revised batch they live on the parent request, because that is
  /// where the assessment happened. Reading them from there rather than
  /// copying them forward keeps one copy of a number that decides careers.
  Future<Map<String, dynamic>> _loadCarriedScores() async {
    final source = isRevisedBatch ? _parentRequestId : _requestId;
    if (source == null || source.isEmpty) return const {};
    try {
      final snap =
          await _db.collection('recruiter_requests').doc(source).get();
      final raw = snap.data()?['assessment_summary'];
      return raw is Map ? Map<String, dynamic>.from(raw) : const {};
    } catch (_) {
      return const {};
    }
  }

  static String _firstNonEmpty(List<Map<String, dynamic>> rows, String key) {
    for (final row in rows) {
      final v = (row[key] ?? '').toString();
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  void _watchBoard(String requestId) {
    _boardSub?.cancel();
    _boardSub = _db
        .collection('assessments')
        .where('requestId', isEqualTo: requestId)
        .snapshots()
        .listen(
      (snap) {
        _rows = snap.docs.map(AssessmentRow.fromDoc).toList()
          ..sort((a, b) => (b.percentage ?? -1).compareTo(a.percentage ?? -1));
        notifyListeners();
      },
      onError: (e) {
        _error = 'Live updates stopped: $e';
        notifyListeners();
      },
    );
  }

  Future<void> _loadBank() async {
    if (_jobId.isEmpty) return;
    _backendReachable = true;
    try {
      final data = await BackendApi.get('/assessment/bank/$_jobId');
      _bank = QuestionBank.fromJson(data);
    } on BackendException catch (e) {
      // 404 is the normal starting state — no paper has been built yet — and
      // is not an error. Anything else is.
      _bank = null;
      if (e.statusCode != 404) _error = e.message;
    } catch (_) {
      // The request never reached the server. Saying "no paper has been
      // generated" here would be a guess dressed as a fact: there may well be
      // an approved paper sitting on the other side of a backend that is down.
      _bank = null;
      _backendReachable = false;
    }
  }

  /// Generates the paper. One Gemini call for the whole batch.
  Future<void> generateBank({bool force = false}) async {
    if (_jobId.isEmpty) {
      _error = 'This request has no job attached, so there is nothing to test on.';
      notifyListeners();
      return;
    }
    _busy = true;
    _error = '';
    _notice = '';
    notifyListeners();
    try {
      final roles = _candidates
          .map((c) => (c['target_role'] ?? '').toString())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList();

      final data = await BackendApi.post(
        '/assessment/bank/generate',
        {'jobId': _jobId, 'requestId': _requestId, 'roleTitles': roles, 'force': force},
        // Sixty questions is a long generation; the default 30s would time out
        // on the client while the server was still working.
        timeout: const Duration(seconds: 120),
      );
      await _loadBank();
      _notice = 'Generated ${data['questionCount']} questions. '
          'Review them before inviting anyone.';
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Generation failed. Check the backend is reachable.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> saveBank(List<BankQuestion> questions, {bool approve = false}) async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      final data = await BackendApi.patch('/assessment/bank/$_jobId', {
        'questions': questions.map((q) => q.toJson()).toList(),
        if (approve) 'status': 'approved',
      });
      _bank = QuestionBank.fromJson(data);
      _notice = approve ? 'Paper approved. You can now invite candidates.' : 'Changes saved.';
    } on BackendException catch (e) {
      _error = e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> approveBank() async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      final data = await BackendApi.patch('/assessment/bank/$_jobId', {'status': 'approved'});
      _bank = QuestionBank.fromJson(data);
      _notice = 'Paper approved. You can now invite candidates.';
    } on BackendException catch (e) {
      _error = e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void toggle(String uid) {
    selected.contains(uid) ? selected.remove(uid) : selected.add(uid);
    notifyListeners();
  }

  void selectAllUninvited() {
    final invited = _rows.map((r) => r.candidateUid).toSet();
    selected
      ..clear()
      ..addAll(_candidates
          .map((c) => (c['uid'] ?? '').toString())
          .where((uid) => uid.isNotEmpty && !invited.contains(uid)));
    notifyListeners();
  }

  Future<void> invite() async {
    if (selected.isEmpty) return;
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
          'candidateUids': selected.toList(),
          'passMark': passMark,
        },
        timeout: const Duration(seconds: 90),
      );
      selected.clear();
      final skipped = (data['skipped'] as List?)?.length ?? 0;
      _notice = 'Invited ${data['invited']} candidate(s), '
          '${data['emailed']} emailed'
          '${skipped > 0 ? ', $skipped already had an invitation' : ''}.';
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Invites failed. Check the backend is reachable.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> release(String note) async {
    _busy = true;
    _error = '';
    _notice = '';
    notifyListeners();
    try {
      final data = await BackendApi.post('/assessment/release', {
        'requestId': _requestId,
        'note': note,
      });
      _notice = 'Sent ${data['scored']} score(s) to the recruiter.';
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Release failed. Check the backend is reachable.';
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
