import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../services/backend_api.dart';
import 'assessment_models.dart';

/// One job that candidates have been shortlisted for, and the state of its
/// paper.
///
/// Assembled from the recruiter requests rather than from a jobs collection on
/// purpose: the only jobs worth writing a paper for are the ones somebody is
/// actually being shortlisted against.
class BankJob {
  const BankJob({
    required this.jobId,
    required this.title,
    required this.candidateCount,
    required this.requestCount,
    this.roleCounts = const {},
  });

  final String jobId;
  final String title;
  final int candidateCount;
  final int requestCount;

  /// How many shortlisted candidates hold each trade, most held first.
  ///
  /// The count is what matters. The model is told about at most eight trades,
  /// and the eight it should hear about are the ones the shortlist is actually
  /// made of — not whichever eight Firestore happened to return first, which is
  /// what the previous version sent.
  final Map<String, int> roleCounts;

  /// The trades in the order the model should hear about them.
  List<String> get roleTitles => roleCounts.keys.toList();

  /// How many trades will not fit in the prompt's eight slots.
  int get roleOverflow =>
      roleCounts.length > kPromptRoleLimit ? roleCounts.length - kPromptRoleLimit : 0;
}

/// How many trades the generation prompt describes. Mirrors the cap the backend
/// applies, so the screen can say which ones will be left out instead of
/// quietly dropping them.
const kPromptRoleLimit = 8;

/// Counts trades and returns them most-held first.
///
/// Ties break alphabetically so two reads of the same shortlist rank them the
/// same way. Without that, two Generate clicks could send the model different
/// lists for no visible reason and produce two differently-slanted papers.
///
/// Pure, so the ordering can be checked without Firestore.
Map<String, int> rankRoles(Iterable<String> roles) {
  final counts = <String, int>{};
  for (final raw in roles) {
    final role = raw.trim();
    if (role.isEmpty) continue;
    counts[role] = (counts[role] ?? 0) + 1;
  }
  final ordered = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  return {for (final e in ordered) e.key: e.value};
}

/// The question-bank screen's state: one paper per job, built once, reused by
/// every request against that job.
///
/// It knows nothing about candidates, invitations or scores. A paper is a
/// property of the job — writing one is authoring work, not hiring work — and
/// keeping the two apart is why this screen no longer shows a candidate list
/// that duplicated the recruiter-request screen.
class QuestionBankProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<BankJob> _jobs = const [];
  List<BankJob> get jobs => _jobs;

  String _jobId = '';
  String get jobId => _jobId;

  String _jobTitle = '';
  String get jobTitle => _jobTitle;

  Map<String, int> _roleCounts = const {};

  /// The trades that will actually reach the prompt, ranked and capped.
  List<String> get promptRoles =>
      _roleCounts.keys.take(kPromptRoleLimit).toList();

  QuestionBank? _bank;
  QuestionBank? get bank => _bank;

  /// False when the last backend call did not complete at all.
  ///
  /// Kept apart from [error] so the screen can say "cannot reach the backend"
  /// instead of reporting an empty result as though it were the answer.
  bool _backendReachable = true;
  bool get backendReachable => _backendReachable;

  bool _loadingJobs = false;
  bool get loadingJobs => _loadingJobs;

  bool _busy = false;
  bool get busy => _busy;

  String _error = '';
  String get error => _error;

  String _notice = '';
  String get notice => _notice;

  StreamSubscription? _jobsSub;

  BankJob? get selectedJob {
    for (final j in _jobs) {
      if (j.jobId == _jobId) return j;
    }
    return null;
  }

  /// Watches the recruiter requests and derives the list of testable jobs.
  void watchJobs() {
    if (_jobsSub != null) return;
    _loadingJobs = true;
    notifyListeners();

    _jobsSub =
        _db.collection('recruiter_requests').snapshots().listen((snap) {
      final byJob = <String,
          ({
            String title,
            Set<String> uids,
            Set<String> reqs,
            Map<String, String> roleByUid,
          })>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final candidates = (data['candidates'] as List?)?.whereType<Map>() ?? const [];
        for (final raw in candidates) {
          final c = Map<String, dynamic>.from(raw);
          final jobId = (c['job_id'] ?? '').toString();
          if (jobId.isEmpty) continue;
          final entry = byJob.putIfAbsent(
            jobId,
            () => (
              title: (c['job_title'] ?? '').toString(),
              uids: <String>{},
              reqs: <String>{},
              roleByUid: <String, String>{},
            ),
          );
          final uid = (c['uid'] ?? '').toString();
          if (uid.isNotEmpty) entry.uids.add(uid);
          entry.reqs.add(doc.id);
          final role = (c['target_role'] ?? '').toString().trim();
          // Keyed by candidate, so somebody who appears in two batches for the
          // same job is one person holding one trade, counted once.
          if (uid.isNotEmpty && role.isNotEmpty) entry.roleByUid[uid] = role;
        }
      }

      _jobs = [
        for (final e in byJob.entries)
          BankJob(
            jobId: e.key,
            title: e.value.title.isEmpty ? e.key : e.value.title,
            candidateCount: e.value.uids.length,
            requestCount: e.value.reqs.length,
            roleCounts: rankRoles(e.value.roleByUid.values),
          ),
      ]..sort((a, b) => b.candidateCount.compareTo(a.candidateCount));

      _loadingJobs = false;
      notifyListeners();
    }, onError: (e) {
      _loadingJobs = false;
      _error = 'Could not list jobs: $e';
      notifyListeners();
    });
  }

  Future<void> openJob(String jobId) async {
    if (jobId.isEmpty) return;
    _jobId = jobId;
    final job = selectedJob;
    _jobTitle = job?.title ?? jobId;
    _roleCounts = job?.roleCounts ?? const {};
    _bank = null;
    _error = '';
    _notice = '';
    _busy = true;
    notifyListeners();
    await _loadBank();
    _busy = false;
    notifyListeners();
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
      // an approved paper sitting behind a backend that is down.
      _bank = null;
      _backendReachable = false;
    }
  }

  /// Generates the paper. One Gemini call per job, ever — every candidate
  /// shortlisted against this job is sampled from the same bank.
  Future<void> generateBank({bool force = false}) async {
    if (_jobId.isEmpty) {
      _error = 'Pick a job first — a paper is written for a job, not a batch.';
      notifyListeners();
      return;
    }
    _busy = true;
    _error = '';
    _notice = '';
    notifyListeners();
    try {
      final data = await BackendApi.post(
        '/assessment/bank/generate',
        {
          'jobId': _jobId,
          // Ranked by how many candidates hold each trade, and capped here as
          // well as on the server: the cap belongs where the list is chosen, so
          // what the screen shows and what the model is told are the same eight.
          'roleTitles': promptRoles,
          'force': force,
        },
        // Sixty questions is a long generation; the default 30s would time out
        // on the client while the server was still working.
        timeout: const Duration(seconds: 120),
      );
      await _loadBank();
      _notice = 'Generated ${data['questionCount']} questions. '
          'Read them before approving.';
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Generation failed — the assessment backend did not answer.';
      _backendReachable = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> saveBank(
    List<BankQuestion> questions, {
    bool approve = false,
  }) async {
    _busy = true;
    _error = '';
    notifyListeners();
    try {
      final data = await BackendApi.patch('/assessment/bank/$_jobId', {
        'questions': questions.map((q) => q.toJson()).toList(),
        if (approve) 'status': 'approved',
      });
      _bank = QuestionBank.fromJson(data);
      _notice = approve
          ? 'Paper approved. Requests against this job can now be invited.'
          : 'Changes saved.';
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Save failed — the assessment backend did not answer.';
      _backendReachable = false;
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
      final data = await BackendApi.patch(
        '/assessment/bank/$_jobId',
        {'status': 'approved'},
      );
      _bank = QuestionBank.fromJson(data);
      _notice = 'Paper approved. Requests against this job can now be invited.';
    } on BackendException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Approval failed — the assessment backend did not answer.';
      _backendReachable = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = '';
    _notice = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _jobsSub?.cancel();
    super.dispose();
  }
}
