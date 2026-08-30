import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/backend_api.dart';

/// Where a sitting is, from this screen's point of view.
enum AssessmentPhase {
  loading,

  /// Invitation is open and not yet accepted.
  invitation,

  /// Accepted, briefed, waiting on the candidate to begin.
  ready,

  /// A question is on screen.
  question,

  /// The answer has been graded and is being shown in red or green.
  feedback,
  finished,

  /// The 24 hours ran out before it was started.
  expired,
  error,
}

/// One question exactly as the candidate sees it — no correct answer in sight.
///
/// The backend grades every answer and never sends the key, so there is
/// nothing here for a candidate to read out of the app's memory or its network
/// tab. That is the whole reason this model is this thin.
class AssessmentQuestion {
  const AssessmentQuestion({
    required this.index,
    required this.total,
    required this.text,
    required this.options,
    required this.topic,
    required this.remainingMs,
  });

  final int index;
  final int total;
  final String text;
  final List<String> options;
  final String topic;
  final int remainingMs;

  factory AssessmentQuestion.fromJson(Map<String, dynamic> j) => AssessmentQuestion(
        index: (j['index'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        text: (j['text'] ?? '').toString(),
        options: (j['options'] as List?)?.map((o) => o.toString()).toList() ?? const [],
        topic: (j['topic'] ?? '').toString(),
        remainingMs: (j['remainingMs'] as num?)?.toInt() ?? 0,
      );
}

class AssessmentResult {
  const AssessmentResult({
    required this.correct,
    required this.total,
    required this.answered,
    required this.skipped,
    required this.percentage,
  });

  final int correct, total, answered, skipped, percentage;

  factory AssessmentResult.fromJson(Map<String, dynamic> j) => AssessmentResult(
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        answered: (j['answered'] as num?)?.toInt() ?? 0,
        skipped: (j['skipped'] as num?)?.toInt() ?? 0,
        percentage: (j['percentage'] as num?)?.toInt() ?? 0,
      );
}

/// Drives one candidate through one assessment.
///
/// Every rule that matters — whether the minute ran out, whether an answer is
/// right, what the score is — is decided by the server. What lives here is the
/// countdown the candidate watches and the state the screen paints. When the
/// two disagree the server wins: the local timer firing only sends the
/// question up unanswered, it does not decide anything.
class AssessmentProvider extends ChangeNotifier {
  AssessmentProvider(this.token);

  final String token;

  AssessmentPhase _phase = AssessmentPhase.loading;
  AssessmentPhase get phase => _phase;

  String _error = '';
  String get error => _error;

  // -- Briefing ---------------------------------------------------------------
  String jobTitle = '';
  String company = '';
  int questionCount = 20;
  int questionSeconds = 60;
  int sittingMinutes = 25;
  DateTime? expiresAt;
  List<String> rules = const [];

  // -- Live sitting -----------------------------------------------------------
  String? _sessionId;

  AssessmentQuestion? _question;
  AssessmentQuestion? get question => _question;

  int _selectedIndex = -1;
  int get selectedIndex => _selectedIndex;

  bool? _wasCorrect;
  bool? get wasCorrect => _wasCorrect;

  bool _timedOut = false;
  bool get timedOut => _timedOut;

  bool _busy = false;
  bool get busy => _busy;

  AssessmentResult? _result;
  AssessmentResult? get result => _result;

  int tabSwitches = 0;

  Timer? _ticker;
  int _msRemaining = 0;
  int get msRemaining => _msRemaining;

  /// 1.0 at the start of a question, 0.0 when the minute is gone.
  double get timeFraction {
    final span = questionSeconds * 1000;
    if (span <= 0) return 0;
    return (_msRemaining / span).clamp(0.0, 1.0);
  }

  bool get isRunning =>
      _phase == AssessmentPhase.question || _phase == AssessmentPhase.feedback;

  // ===========================================================================
  //  Lifecycle
  // ===========================================================================

  Future<void> load() async {
    _phase = AssessmentPhase.loading;
    notifyListeners();
    try {
      final data = await BackendApi.get('/assessment/session/$token');
      _applyBriefing(data);

      switch ((data['status'] ?? '').toString()) {
        case 'invited':
          _phase = AssessmentPhase.invitation;
        case 'accepted':
          _phase = AssessmentPhase.ready;
        case 'in_progress':
          // Resume rather than re-brief: the clock has been running.
          await start();
          return;
        case 'submitted':
          _result = _resultOf(data['result']);
          _phase = AssessmentPhase.finished;
        case 'expired':
          _phase = AssessmentPhase.expired;
        default:
          _phase = AssessmentPhase.error;
          _error = 'This assessment is not available.';
      }
    } on BackendException catch (e) {
      _phase = e.isGone ? AssessmentPhase.expired : AssessmentPhase.error;
      _error = e.message;
    } catch (_) {
      _phase = AssessmentPhase.error;
      _error = 'Could not reach the server. Check your connection and try again.';
    }
    notifyListeners();
  }

  void _applyBriefing(Map<String, dynamic> data) {
    jobTitle = (data['jobTitle'] ?? '').toString();
    company = (data['company'] ?? '').toString();
    questionCount = (data['questionCount'] as num?)?.toInt() ?? 20;
    questionSeconds = (data['questionSeconds'] as num?)?.toInt() ?? 60;
    sittingMinutes = (data['sittingMinutes'] as num?)?.toInt() ?? 25;
    final expiry = (data['expiresAt'] as num?)?.toInt();
    expiresAt = expiry == null ? null : DateTime.fromMillisecondsSinceEpoch(expiry);
    rules = (data['rules'] as List?)?.map((r) => r.toString()).toList() ?? const [];
  }

  Future<void> accept() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      await BackendApi.post('/assessment/session/$token/accept', const {});
      _phase = AssessmentPhase.ready;
    } on BackendException catch (e) {
      if (e.isGone) {
        _phase = AssessmentPhase.expired;
      } else {
        _error = e.message;
      }
    } catch (_) {
      _error = 'Could not reach the server. Check your connection.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> start() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      final data = await BackendApi.post('/assessment/session/$token/start', const {});
      _sessionId = (data['sessionId'] ?? '').toString();
      _consume(data);
    } on BackendException catch (e) {
      if (e.isGone) {
        _phase = AssessmentPhase.expired;
      } else {
        _phase = AssessmentPhase.error;
        _error = e.message;
      }
    } catch (_) {
      _phase = AssessmentPhase.error;
      _error = 'Could not start the assessment. Check your connection.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Submits an answer. A [choice] of -1 means the minute ran out.
  Future<void> answer(int choice) async {
    if (_busy || _phase != AssessmentPhase.question || _question == null) return;

    _stopTicker();
    _busy = true;
    _selectedIndex = choice;
    notifyListeners();

    try {
      final data = await BackendApi.post('/assessment/session/$token/answer', {
        'index': _question!.index,
        'chosenIndex': choice,
        'sessionId': _sessionId,
      });

      _wasCorrect = data['correct'] == true;
      _timedOut = data['timedOut'] == true;
      _phase = AssessmentPhase.feedback;
      notifyListeners();

      // Long enough to register, short enough not to feel like a penalty.
      await Future<void>.delayed(const Duration(milliseconds: 850));
      _consume(data);
    } on BackendException catch (e) {
      // A replaced session means another tab took over. Saying so is more
      // useful than a generic failure, because there is somewhere to go.
      _phase = AssessmentPhase.error;
      _error = e.message;
    } catch (_) {
      _phase = AssessmentPhase.error;
      _error = 'That answer did not reach the server. Check your connection.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Applies a server payload that either carries the next question or ends it.
  void _consume(Map<String, dynamic> data) {
    _selectedIndex = -1;
    _wasCorrect = null;
    _timedOut = false;

    if (data['done'] == true) {
      _result = _resultOf(data['result']);
      _question = null;
      _phase = AssessmentPhase.finished;
      _stopTicker();
      return;
    }

    final raw = data['question'];
    if (raw is! Map) {
      _phase = AssessmentPhase.error;
      _error = 'The server did not send the next question.';
      return;
    }

    _question = AssessmentQuestion.fromJson(Map<String, dynamic>.from(raw));
    _phase = AssessmentPhase.question;
    _startTicker(_question!.remainingMs);
  }

  Future<void> finishEarly() async {
    _stopTicker();
    try {
      final data = await BackendApi.post('/assessment/session/$token/finish', const {});
      _result = _resultOf(data['result']);
      _phase = AssessmentPhase.finished;
    } catch (_) {
      _phase = AssessmentPhase.error;
      _error = 'Could not submit. Check your connection.';
    }
    notifyListeners();
  }

  /// Notes that the candidate left the tab or tried to paste.
  ///
  /// Recorded and shown to the admin, never acted on automatically: a
  /// notification stealing focus is indistinguishable from looking something
  /// up, and failing someone on that would be indefensible.
  void reportEvent(String type) {
    if (!isRunning) return;
    if (type == 'blur') tabSwitches++;
    BackendApi.postQuietly('/assessment/session/$token/event', {'type': type});
    notifyListeners();
  }

  static AssessmentResult? _resultOf(dynamic raw) => raw is Map
      ? AssessmentResult.fromJson(Map<String, dynamic>.from(raw))
      : null;

  // ===========================================================================
  //  Countdown
  // ===========================================================================

  void _startTicker(int ms) {
    _stopTicker();
    _msRemaining = ms;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _msRemaining -= 100;
      if (_msRemaining <= 0) {
        _msRemaining = 0;
        _stopTicker();
        // Sends the question up unanswered. The server checks its own clock
        // before agreeing it timed out, so a tampered local timer changes
        // nothing about the outcome.
        answer(-1);
        return;
      }
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
