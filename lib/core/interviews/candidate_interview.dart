/// An interview as the candidate is allowed to see it.
///
/// Built from `GET /interviews/mine` rather than read from Firestore. The
/// interview document also carries the recruiter's private notes about this
/// candidate, so the backend returns a curated view instead and the candidate
/// app never touches the record itself.
///
/// The joining link is deliberately absent until the window opens — the server
/// withholds it, so it cannot be lifted out of a response early.
class CandidateInterview {
  const CandidateInterview({
    required this.id,
    required this.jobTitle,
    required this.company,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.mode,
    required this.status,
    required this.hasLink,
    required this.meetingLink,
    required this.joinOpensAt,
    required this.live,
  });

  final String id;
  final String jobTitle;
  final String company;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String mode;
  final String status;

  /// A link exists, whether or not it has been handed over yet.
  final bool hasLink;

  /// Empty until the joining window opens.
  final String meetingLink;

  final DateTime joinOpensAt;

  /// The meeting has been opened by the interviewer and not yet ended.
  final bool live;

  DateTime get endsAt => scheduledAt.add(Duration(minutes: durationMinutes));

  bool get canJoin => meetingLink.trim().isNotEmpty;

  static DateTime _date(dynamic raw) =>
      DateTime.tryParse((raw ?? '').toString())?.toLocal() ?? DateTime(1970);

  factory CandidateInterview.fromJson(Map<String, dynamic> j) =>
      CandidateInterview(
        id: (j['interviewId'] ?? '').toString(),
        jobTitle: (j['jobTitle'] ?? '').toString(),
        company: (j['company'] ?? '').toString(),
        scheduledAt: _date(j['scheduledAt']),
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 45,
        mode: (j['mode'] ?? 'video').toString(),
        status: (j['status'] ?? 'requested').toString(),
        hasLink: j['hasLink'] == true,
        meetingLink: (j['meetingLink'] ?? '').toString(),
        joinOpensAt: _date(j['joinOpensAt']),
        live: j['live'] == true,
      );
}

/// Which interview to put in front of the candidate, and how often to look again.
abstract final class CandidateInterviews {
  /// How long past the end an interview stays on screen.
  ///
  /// Matches the server's grace period: the candidate must still be able to
  /// rejoin an interview that has overrun.
  static const Duration grace = Duration(minutes: 30);

  /// The next interview worth showing, or null.
  ///
  /// One at a time. A candidate with two booked is looking at the near one, and
  /// a stack of cards on a dashboard reads as clutter rather than as news.
  static CandidateInterview? next(
    List<CandidateInterview> all,
    DateTime now,
  ) {
    CandidateInterview? best;
    for (final i in all) {
      if (i.status == 'cancelled') continue;
      if (now.isAfter(i.endsAt.add(grace))) continue;
      if (best == null || i.scheduledAt.isBefore(best.scheduledAt)) best = i;
    }
    return best;
  }

  /// How often to ask the server again, or null to stop asking.
  ///
  /// The link is only served inside the window, so the card cannot simply be
  /// fetched once and left: it has to look again around the time the window
  /// opens. Away from that moment there is nothing to learn quickly, so the
  /// polling backs right off.
  static Duration? refreshEvery(CandidateInterview? next, DateTime now) {
    if (next == null) return null;

    final opens = next.joinOpensAt;
    final closes = next.endsAt.add(grace);
    if (now.isAfter(closes)) return null;

    // Close to the window, the link is the thing being waited for.
    if (!now.isBefore(opens.subtract(const Duration(minutes: 10)))) {
      return const Duration(seconds: 30);
    }
    return const Duration(minutes: 5);
  }
}
