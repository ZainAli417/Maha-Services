/// One assessment as the candidate's own record of it.
///
/// Built from `GET /assessment/mine`. The score is here; the verdict is not —
/// pass or fail is the recruiter's decision to be told, and the server does
/// not send it to the candidate. Showing a made-up threshold here would tell
/// someone they had failed before anyone had decided anything.
class CandidateSitting {
  const CandidateSitting({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.answeredCount,
    required this.questionCount,
    required this.invitedAt,
    required this.expiresAt,
    required this.score,
    required this.correct,
    required this.skipped,
  });

  final String id;
  final String jobId;
  final String jobTitle;
  final String company;

  /// One of: invited, accepted, in_progress, submitted, expired.
  final String status;

  final int answeredCount;
  final int questionCount;
  final DateTime invitedAt;
  final DateTime? expiresAt;

  /// Percentage, or null when the sitting has not been marked.
  final int? score;
  final int? correct;
  final int? skipped;

  bool get isDone => status == 'submitted';
  bool get isExpired => status == 'expired';
  bool get isStarted => status == 'in_progress';

  /// Still sittable — invited, briefed or half-finished.
  bool get isOpen => !isDone && !isExpired;

  /// How far through, 0..1. Only meaningful once started.
  double get progress =>
      questionCount == 0 ? 0 : (answeredCount / questionCount).clamp(0.0, 1.0);

  /// What the candidate is being asked to do about it.
  String get action => switch (status) {
        'in_progress' => 'Resume',
        'invited' || 'accepted' => 'Start',
        'submitted' => 'View result',
        _ => 'Closed',
      };

  static DateTime? _time(dynamic raw) {
    if (raw is num && raw > 0) {
      return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    }
    return null;
  }

  static int? _int(dynamic raw) => raw is num ? raw.toInt() : null;

  factory CandidateSitting.fromJson(Map<String, dynamic> j) {
    final result = j['result'] is Map
        ? Map<String, dynamic>.from(j['result'] as Map)
        : const <String, dynamic>{};
    return CandidateSitting(
      id: (j['assessmentId'] ?? '').toString(),
      jobId: (j['jobId'] ?? '').toString(),
      jobTitle: (j['jobTitle'] ?? '').toString(),
      company: (j['company'] ?? '').toString(),
      status: (j['status'] ?? '').toString(),
      answeredCount: _int(j['answeredCount']) ?? 0,
      questionCount: _int(j['questionCount']) ?? 20,
      invitedAt: _time(j['invitedAt']) ?? DateTime(1970),
      expiresAt: _time(j['expiresAt']),
      score: _int(result['percentage']),
      correct: _int(result['correct']),
      skipped: _int(result['skipped']),
    );
  }
}

/// The filters offered above the list.
enum SittingFilter {
  all('All'),
  toDo('To do'),
  completed('Completed'),
  expired('Expired');

  const SittingFilter(this.label);

  final String label;
}

/// One job, with every sitting the candidate has had for it.
typedef SittingJobGroup = ({
  String jobId,
  String jobTitle,
  String company,
  List<CandidateSitting> sittings,
});

/// Searching, filtering and grouping — all of it pure.
abstract final class SittingLibrary {
  /// Matches on job title and company, case-insensitively.
  ///
  /// Deliberately not on status text: typing "expired" should not be a second
  /// way of doing what the filter row already does, because the two would
  /// disagree the moment one of them changed.
  static List<CandidateSitting> search(
      List<CandidateSitting> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final s in all)
        if (s.jobTitle.toLowerCase().contains(q) ||
            s.company.toLowerCase().contains(q))
          s,
    ];
  }

  static List<CandidateSitting> filter(
      List<CandidateSitting> all, SittingFilter filter) {
    return switch (filter) {
      SittingFilter.all => all,
      SittingFilter.toDo => [for (final s in all) if (s.isOpen) s],
      SittingFilter.completed => [for (final s in all) if (s.isDone) s],
      SittingFilter.expired => [for (final s in all) if (s.isExpired) s],
    };
  }

  /// Grouped by job, because a candidate thinks in roles applied for.
  ///
  /// A job with something still to sit comes first however old it is — that is
  /// the one with a deadline on it. Within a job, the same rule: open first,
  /// then most recent.
  static List<SittingJobGroup> byJob(List<CandidateSitting> all) {
    final groups = <String, List<CandidateSitting>>{};
    final order = <String>[];
    for (final s in all) {
      final key = s.jobId.isEmpty ? s.jobTitle : s.jobId;
      if (!groups.containsKey(key)) {
        groups[key] = [];
        order.add(key);
      }
      groups[key]!.add(s);
    }

    final out = <SittingJobGroup>[];
    for (final key in order) {
      final items = groups[key]!
        ..sort((a, b) {
          if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
          return b.invitedAt.compareTo(a.invitedAt);
        });
      final head = items.first;
      out.add((
        jobId: head.jobId,
        jobTitle: head.jobTitle.isEmpty ? 'Untitled role' : head.jobTitle,
        company: head.company,
        sittings: items,
      ));
    }

    out.sort((a, b) {
      final aOpen = a.sittings.any((s) => s.isOpen);
      final bOpen = b.sittings.any((s) => s.isOpen);
      if (aOpen != bOpen) return aOpen ? -1 : 1;
      return b.sittings.first.invitedAt.compareTo(a.sittings.first.invitedAt);
    });
    return out;
  }

  /// How many are waiting on the candidate. This is the number on the tab.
  static int toDoCount(List<CandidateSitting> all) =>
      all.where((s) => s.isOpen).length;

  /// The candidate's own record. Averages are null, never zero, when there is
  /// nothing marked — "no tests taken" and "averaged nought" are not the same
  /// thing to read about yourself.
  static ({int taken, int? average, int? best}) record(
      List<CandidateSitting> all) {
    final scored = [
      for (final s in all)
        if (s.isDone && s.score != null) s.score!,
    ];
    if (scored.isEmpty) {
      return (taken: all.where((s) => s.isDone).length, average: null, best: null);
    }
    final sum = scored.reduce((a, b) => a + b);
    return (
      taken: all.where((s) => s.isDone).length,
      average: (sum / scored.length).round(),
      best: scored.reduce((a, b) => a > b ? a : b),
    );
  }
}
