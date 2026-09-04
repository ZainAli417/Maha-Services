/// The recruiter's whole pipeline, counted once.
///
/// Every number on the dashboard comes from here rather than from a widget
/// counting a list inline. Two widgets counting the same thing is how a
/// "15 passed" card ends up beside a "14 passed" chart, and the recruiter has
/// no way to tell which one lied.
///
/// Pure and dependency-free: it works on [FunnelCandidate] records rather than
/// on `ApplicantRecord`, which carries a live Firestore reference no unit test
/// should have to fake.
library;

/// The only fields the funnel reads.
typedef FunnelCandidate = ({
  /// `shortlist` when the recruiter has shortlisted them.
  String status,
  bool sentToAdmin,

  /// AI match score, or null when nobody has run the analysis.
  int? aiScore,

  /// '' | invited | accepted | in_progress | submitted | expired
  String testStatus,

  /// Released percentage only. An unreleased score is not the recruiter's to
  /// count, and is not on their screen either.
  int? testPercentage,

  /// pass | fail | '' — set by the admin's pass mark at release time.
  String testVerdict,
  bool interviewBooked,
});

class HiringFunnel {
  const HiringFunnel({
    required this.shortlisted,
    required this.sentToAdmin,
    required this.notSentYet,
    required this.invited,
    required this.satTest,
    required this.expired,
    required this.awaitingResult,
    required this.scored,
    required this.passed,
    required this.failed,
    required this.interviewReady,
    required this.interviewBooked,
    required this.aiAnalysed,
    required this.avgAiScore,
    required this.avgTestScore,
  });

  /// Everyone on the shortlist. The denominator for every rate below.
  final int shortlisted;

  final int sentToAdmin;

  /// Shortlisted but not handed over yet — the recruiter's own queue.
  final int notSentYet;

  /// Had an invitation issued, at any stage after it.
  final int invited;

  /// Finished the sitting.
  final int satTest;

  /// Let the 24-hour window lapse without sitting it.
  final int expired;

  /// Invited, not expired, and no released score yet. Nothing for the
  /// recruiter to do; this is the number they are waiting on.
  final int awaitingResult;

  /// Has a released score.
  final int scored;

  final int passed;
  final int failed;

  /// Passed and has no interview booked — the recruiter's next action.
  final int interviewReady;

  final int interviewBooked;

  /// How many carry an AI match score at all.
  final int aiAnalysed;

  /// Mean over the candidates who have one. Null when none do — not 0, which
  /// would read as "everybody scored zero".
  final double? avgAiScore;
  final double? avgTestScore;

  static const empty = HiringFunnel(
    shortlisted: 0,
    sentToAdmin: 0,
    notSentYet: 0,
    invited: 0,
    satTest: 0,
    expired: 0,
    awaitingResult: 0,
    scored: 0,
    passed: 0,
    failed: 0,
    interviewReady: 0,
    interviewBooked: 0,
    aiAnalysed: 0,
    avgAiScore: null,
    avgTestScore: null,
  );

  int get aiNotAnalysed => shortlisted - aiAnalysed;

  /// Share of the shortlist that passed, 0–1. Null when nobody has a score,
  /// because a rate over nothing is not 0% — it is unknown.
  double? get passRate => scored == 0 ? null : passed / scored;

  /// Share of the shortlist that has been handed over.
  double? get handoverRate =>
      shortlisted == 0 ? null : sentToAdmin / shortlisted;

  /// Share of those invited who actually sat the test.
  double? get sittingRate => invited == 0 ? null : satTest / invited;

  /// Share of the passers who have a slot booked.
  double? get bookedRate => passed == 0 ? null : interviewBooked / passed;

  /// Counts [people] into a funnel.
  ///
  /// Only shortlisted candidates are counted. The dashboard is about the people
  /// the recruiter has actually chosen to work on; folding in every applicant
  /// would make every rate look far worse than the work being done.
  factory HiringFunnel.from(Iterable<FunnelCandidate> people) {
    final list = [
      for (final p in people)
        if (p.status.toLowerCase().trim() == 'shortlist') p,
    ];
    if (list.isEmpty) return empty;

    var sent = 0,
        invited = 0,
        sat = 0,
        expired = 0,
        scored = 0,
        passed = 0,
        failed = 0,
        booked = 0,
        ready = 0;
    final aiScores = <int>[];
    final testScores = <int>[];

    for (final p in list) {
      if (p.sentToAdmin) sent++;
      if (p.aiScore != null) aiScores.add(p.aiScore!);

      final st = p.testStatus.toLowerCase().trim();
      if (st.isNotEmpty) invited++;
      if (st == 'submitted') sat++;
      if (st == 'expired') expired++;

      final pct = p.testPercentage;
      if (pct != null) {
        scored++;
        testScores.add(pct);
        // A verdict that is anything other than a pass is a fail. Absent is
        // not a pass — reading it optimistically would count an unassessed
        // candidate as through.
        p.testVerdict.toLowerCase().trim() == 'pass' ? passed++ : failed++;
      }

      if (p.interviewBooked) booked++;
      if (p.testVerdict.toLowerCase().trim() == 'pass' &&
          pct != null &&
          !p.interviewBooked) {
        ready++;
      }
    }

    double? mean(List<int> xs) =>
        xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

    return HiringFunnel(
      shortlisted: list.length,
      sentToAdmin: sent,
      notSentYet: list.length - sent,
      invited: invited,
      satTest: sat,
      expired: expired,
      // Invited, still live, nothing back yet.
      awaitingResult: invited - sat - expired,
      scored: scored,
      passed: passed,
      failed: failed,
      interviewReady: ready,
      interviewBooked: booked,
      aiAnalysed: aiScores.length,
      avgAiScore: mean(aiScores),
      avgTestScore: mean(testScores),
    );
  }
}
