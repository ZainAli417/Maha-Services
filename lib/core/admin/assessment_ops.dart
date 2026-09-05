/// What the admin actually owns, counted from live documents.
///
/// The admin's job is a queue: requests arrive, papers get written and
/// approved, candidates get invited, scores come back, scores go out, joining
/// links get issued. Every number and every prompt on the admin dashboard is
/// derived here so there is one definition of each — a screen that counts
/// "3 waiting" while a list shows four is worse than no number at all.
///
/// Pure and dependency-free. It takes plain records rather than Firestore
/// snapshots, so the rules can be tested without a database.
library;

/// One recruiter request, as the ops view reads it.
typedef OpsRequest = ({
  String requestId,
  String jobId,
  String jobTitle,

  /// Everyone the recruiter sent.
  int candidates,

  /// pending | active | rejected | closed
  String status,

  /// Candidates named in `assessment_summary` — i.e. scores the admin has
  /// released to the recruiter.
  int releasedScores,

  /// Candidates the recruiter kept after seeing the scores.
  int kept,
});

/// One candidate's sitting.
typedef OpsAssessment = ({
  String requestId,
  String jobId,

  /// invited | accepted | in_progress | submitted | expired
  String status,

  /// Null until they finish.
  int? percentage,

  /// pass | fail | ''
  String verdict,

  /// True once the admin has sent this score to the recruiter.
  bool released,

  /// When the 24-hour acceptance window closes.
  DateTime? expiresAt,
  int tabSwitches,
});

/// One job's question paper.
typedef OpsPaper = ({String jobId, String status, int questionCount});

/// One booked interview.
typedef OpsInterview = ({
  String requestId,
  bool hasLink,
  DateTime scheduledAt,

  /// requested | scheduled | completed | cancelled | no_show
  String status,
});

/// How much a prompt matters.
///
/// Ordered, and the order is the sort order of the action queue: something that
/// has stopped a person dead outranks something that is merely worth knowing.
enum OpsUrgency {
  /// Nobody can move until the admin acts.
  blocking,

  /// Somebody is waiting on the admin specifically.
  waiting,

  /// Time-limited — it stops mattering if left.
  soon,

  /// Awareness only. No action implied.
  watch,
}

/// One prompt on the admin's queue.
///
/// [detail] says what happens if it is left, not what to click. An admin who
/// knows the consequence can decide the priority themselves.
typedef OpsAction = ({
  String title,
  String detail,
  int count,
  OpsUrgency urgency,
});

/// One job's assessment state, for the per-job table.
typedef OpsJobRow = ({
  String jobId,
  String jobTitle,
  int shortlisted,
  int invited,
  int satTest,
  int passed,
  int failed,

  /// approved | draft | none
  String paperStatus,
  int paperQuestions,
  double? passRate,
  double? avgScore,
});

class AssessmentOps {
  const AssessmentOps({
    required this.requests,
    required this.assessments,
    required this.papers,
    required this.interviews,
    required this.now,
    this.papersKnown = true,
  });

  final List<OpsRequest> requests;
  final List<OpsAssessment> assessments;
  final List<OpsPaper> papers;
  final List<OpsInterview> interviews;
  final DateTime now;

  /// Whether the paper feed was actually read.
  ///
  /// An empty [papers] list is ambiguous: it means either "no paper has been
  /// written for any job" or "the paper feed could not be read". Those lead to
  /// opposite conclusions — the first says every batch is blocked, the second
  /// says nothing at all — and guessing the first would put a red warning on a
  /// dashboard for jobs whose papers are approved and fine.
  final bool papersKnown;

  /// An ops view with nothing in it. `now` has to be supplied because two of
  /// the prompts are about time running out, and a hardcoded date would make
  /// them quietly wrong.
  factory AssessmentOps.emptyAt(DateTime now) => AssessmentOps(
        requests: const [],
        assessments: const [],
        papers: const [],
        interviews: const [],
        now: now,
      );

  // ── funnel ───────────────────────────────────────────────────────────────

  int get batches => requests.length;
  int get pendingReview =>
      requests.where((r) => r.status.toLowerCase() == 'pending').length;

  /// Everyone recruiters have sent, across every batch.
  int get received => requests.fold(0, (n, r) => n + r.candidates);

  int get invited => assessments.length;
  int get satTest => assessments.where((a) => a.status == 'submitted').length;
  int get expired => assessments.where((a) => a.status == 'expired').length;
  int get inFlight => assessments
      .where((a) =>
          a.status == 'invited' ||
          a.status == 'accepted' ||
          a.status == 'in_progress')
      .length;

  int get scored => assessments.where((a) => a.percentage != null).length;
  int get passed => assessments.where((a) => a.verdict == 'pass').length;
  int get failed =>
      assessments.where((a) => a.percentage != null && a.verdict != 'pass').length;

  /// Scores the recruiter can see.
  int get releasedScores => assessments.where((a) => a.released).length;

  /// Scores sitting with the admin, finished and unsent. The recruiter is
  /// waiting on exactly this number.
  int get unsentScores =>
      assessments.where((a) => a.percentage != null && !a.released).length;

  /// Not shortlisted-but-uninvited: candidates in a batch nobody has invited.
  ///
  /// Counted per batch rather than globally, because an assessment carries the
  /// request it belongs to and a batch is what gets invited.
  int get notInvited {
    final byRequest = <String, int>{};
    for (final a in assessments) {
      byRequest[a.requestId] = (byRequest[a.requestId] ?? 0) + 1;
    }
    var total = 0;
    for (final r in requests) {
      final done = byRequest[r.requestId] ?? 0;
      if (r.candidates > done) total += r.candidates - done;
    }
    return total;
  }

  int get keptForInterview => requests.fold(0, (n, r) => n + r.kept);

  List<OpsInterview> get liveInterviews =>
      interviews.where((i) => i.status != 'cancelled').toList();

  int get interviewsBooked => liveInterviews.length;
  int get interviewsWithoutLink =>
      liveInterviews.where((i) => !i.hasLink).length;

  /// Booked, no link, and starting within 24 hours. The candidate has nowhere
  /// to join from.
  int get interviewsAtRisk => liveInterviews
      .where((i) =>
          !i.hasLink &&
          i.status != 'completed' &&
          i.scheduledAt.isAfter(now) &&
          i.scheduledAt.difference(now).inHours <= 24)
      .length;

  // ── papers ───────────────────────────────────────────────────────────────

  Map<String, OpsPaper> get _papersByJob => {
        for (final p in papers) p.jobId: p,
      };

  /// Jobs with candidates waiting and no approved paper. Nobody on these can be
  /// invited at all.
  Set<String> get jobsBlockedOnPaper {
    if (!papersKnown) return const {};
    final byJob = _papersByJob;
    return {
      for (final r in requests)
        if (r.jobId.isNotEmpty && byJob[r.jobId]?.status != 'approved')
          r.jobId,
    };
  }

  int get papersInDraft =>
      papers.where((p) => p.status != 'approved').length;

  int get papersApproved =>
      papers.where((p) => p.status == 'approved').length;

  // ── integrity ────────────────────────────────────────────────────────────

  /// Sittings with tab switches on record. Not proof of anything, which is why
  /// it is surfaced as something to look at rather than acted on.
  int get flaggedSittings =>
      assessments.where((a) => a.tabSwitches >= 3).length;

  // ── rates ────────────────────────────────────────────────────────────────

  /// Null rather than zero when nothing has been scored — a rate over nothing
  /// is unknown, not 0%.
  double? get passRate => scored == 0 ? null : passed / scored;

  /// Of those invited, how many actually sat it.
  double? get sittingRate => invited == 0 ? null : satTest / invited;

  double? get avgScore {
    final xs = [
      for (final a in assessments)
        if (a.percentage != null) a.percentage!,
    ];
    return xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;
  }

  // ── score distribution ───────────────────────────────────────────────────

  /// Released and unreleased scores in ten-point buckets, 0-9 … 90-100.
  ///
  /// Ten buckets rather than a pass/fail split because the shape is the point:
  /// a batch clustered at 55-65 says the pass mark is doing the deciding, and a
  /// batch spread from 20 to 95 says the paper is.
  List<int> get scoreHistogram {
    final buckets = List<int>.filled(10, 0);
    for (final a in assessments) {
      final p = a.percentage;
      if (p == null) continue;
      final i = (p ~/ 10).clamp(0, 9);
      buckets[i] += 1;
    }
    return buckets;
  }

  // ── per job ──────────────────────────────────────────────────────────────

  List<OpsJobRow> get jobRows {
    final shortlisted = <String, int>{};
    final titles = <String, String>{};
    for (final r in requests) {
      if (r.jobId.isEmpty) continue;
      shortlisted[r.jobId] = (shortlisted[r.jobId] ?? 0) + r.candidates;
      if (r.jobTitle.isNotEmpty) titles[r.jobId] = r.jobTitle;
    }

    final byJob = _papersByJob;
    final rows = <OpsJobRow>[];

    for (final jobId in shortlisted.keys) {
      final sittings = assessments.where((a) => a.jobId == jobId).toList();
      final done = sittings.where((a) => a.percentage != null).toList();
      final pass = done.where((a) => a.verdict == 'pass').length;
      final paper = byJob[jobId];

      rows.add((
        jobId: jobId,
        jobTitle: titles[jobId] ?? jobId,
        shortlisted: shortlisted[jobId]!,
        invited: sittings.length,
        satTest: sittings.where((a) => a.status == 'submitted').length,
        passed: pass,
        failed: done.length - pass,
        paperStatus: switch ((papersKnown, paper)) {
          (false, _) => 'unknown',
          (_, null) => 'none',
          (_, final p?) => p.status == 'approved' ? 'approved' : 'draft',
        },
        paperQuestions: paper?.questionCount ?? 0,
        passRate: done.isEmpty ? null : pass / done.length,
        avgScore: done.isEmpty
            ? null
            : done.map((a) => a.percentage!).reduce((a, b) => a + b) /
                done.length,
      ));
    }

    rows.sort((a, b) => b.shortlisted.compareTo(a.shortlisted));
    return rows;
  }

  // ── the queue ────────────────────────────────────────────────────────────

  /// What is actually waiting on the admin, most consequential first.
  ///
  /// Every entry is derived from a live count. Nothing generic appears here: a
  /// dashboard that offers advice nobody asked for teaches people to ignore the
  /// panel that also carries the real warnings.
  List<OpsAction> get actions {
    final out = <OpsAction>[];

    final blocked = jobsBlockedOnPaper.length;
    if (blocked > 0) {
      out.add((
        title: '$blocked job${blocked == 1 ? '' : 's'} cannot be tested yet',
        detail: 'Candidates are shortlisted against '
            '${blocked == 1 ? 'it' : 'them'} but there is no approved question '
            'paper, so nobody on '
            '${blocked == 1 ? 'that batch' : 'those batches'} can be invited.',
        count: blocked,
        urgency: OpsUrgency.blocking,
      ));
    }

    if (interviewsAtRisk > 0) {
      out.add((
        title: '$interviewsAtRisk interview'
            '${interviewsAtRisk == 1 ? '' : 's'} within 24 hours with no link',
        detail: 'The slot is booked and the candidate has nowhere to join '
            'from. Issuing the joining link is the only thing left.',
        count: interviewsAtRisk,
        urgency: OpsUrgency.blocking,
      ));
    }

    if (unsentScores > 0) {
      out.add((
        title: '$unsentScores score${unsentScores == 1 ? '' : 's'} not sent to '
            'the recruiter',
        detail: 'These candidates have finished and been graded. Until the '
            'scores go across, the recruiter cannot choose anyone for '
            'interview.',
        count: unsentScores,
        urgency: OpsUrgency.waiting,
      ));
    }

    if (pendingReview > 0) {
      out.add((
        title: '$pendingReview batch${pendingReview == 1 ? '' : 'es'} awaiting '
            'review',
        detail: 'A recruiter has sent '
            '${pendingReview == 1 ? 'a shortlist' : 'shortlists'} that nobody '
            'has opened yet.',
        count: pendingReview,
        urgency: OpsUrgency.waiting,
      ));
    }

    final unlinked = interviewsWithoutLink - interviewsAtRisk;
    if (unlinked > 0) {
      out.add((
        title: '$unlinked booked interview${unlinked == 1 ? '' : 's'} still '
            'need a link',
        detail: 'Not urgent yet — none of these is inside 24 hours — but the '
            'candidate has not been told how to join.',
        count: unlinked,
        urgency: OpsUrgency.waiting,
      ));
    }

    if (papersInDraft > 0) {
      out.add((
        title: '$papersInDraft question paper'
            '${papersInDraft == 1 ? '' : 's'} in draft',
        detail: 'Generated but not read. A wrong answer key scores every '
            'candidate against it, and that cannot be taken back once a batch '
            'has sat the test.',
        count: papersInDraft,
        urgency: OpsUrgency.waiting,
      ));
    }

    final closing = expiringWithin(const Duration(hours: 6));
    if (closing > 0) {
      out.add((
        title: '$closing invitation${closing == 1 ? '' : 's'} expire within 6 '
            'hours',
        detail: 'These candidates have not accepted yet. When the window '
            'closes they lose the sitting and have to be invited again.',
        count: closing,
        urgency: OpsUrgency.soon,
      ));
    }

    if (notInvited > 0) {
      out.add((
        title: '$notInvited shortlisted candidate'
            '${notInvited == 1 ? '' : 's'} never invited',
        detail: 'They are in a batch that has been partly invited. Nothing is '
            'wrong with that — but nothing is happening to them either.',
        count: notInvited,
        urgency: OpsUrgency.watch,
      ));
    }

    if (flaggedSittings > 0) {
      out.add((
        title: '$flaggedSittings sitting${flaggedSittings == 1 ? '' : 's'} '
            'switched tabs three times or more',
        detail: 'Not proof of anything on its own — a phone call does it too. '
            'Worth reading alongside the score before it decides anything.',
        count: flaggedSittings,
        urgency: OpsUrgency.watch,
      ));
    }

    if (inFlight > 0) {
      out.add((
        title: '$inFlight candidate${inFlight == 1 ? '' : 's'} mid-test',
        detail: 'Invited or sitting it now. Nothing to do — the score arrives '
            'on its own.',
        count: inFlight,
        urgency: OpsUrgency.watch,
      ));
    }

    out.sort((a, b) {
      final byUrgency = a.urgency.index.compareTo(b.urgency.index);
      return byUrgency != 0 ? byUrgency : b.count.compareTo(a.count);
    });
    return out;
  }

  /// Invitations whose acceptance window closes inside [window].
  int expiringWithin(Duration window) {
    final cutoff = now.add(window);
    return assessments
        .where((a) =>
            a.status == 'invited' &&
            a.expiresAt != null &&
            a.expiresAt!.isAfter(now) &&
            a.expiresAt!.isBefore(cutoff))
        .length;
  }
}
