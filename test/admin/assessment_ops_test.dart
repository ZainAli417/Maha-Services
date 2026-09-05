import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/admin/assessment_ops.dart';

final now = DateTime(2026, 8, 31, 12);

OpsRequest req({
  String id = 'r1',
  String jobId = 'j1',
  String title = 'Cyber Defence',
  int candidates = 17,
  String status = 'active',
  int released = 0,
  int kept = 0,
}) => (
      requestId: id,
      jobId: jobId,
      jobTitle: title,
      candidates: candidates,
      status: status,
      releasedScores: released,
      kept: kept,
    );

OpsAssessment sitting({
  String requestId = 'r1',
  String jobId = 'j1',
  String status = 'submitted',
  int? percentage,
  String? verdict,
  bool released = false,
  DateTime? expiresAt,
  int tabSwitches = 0,
}) => (
      requestId: requestId,
      jobId: jobId,
      status: status,
      percentage: percentage,
      verdict: verdict ?? (percentage == null
          ? ''
          : (percentage >= 60 ? 'pass' : 'fail')),
      released: released,
      expiresAt: expiresAt,
      tabSwitches: tabSwitches,
    );

OpsInterview meeting({
  String requestId = 'r1',
  bool hasLink = false,
  DateTime? at,
  String status = 'scheduled',
}) => (
      requestId: requestId,
      hasLink: hasLink,
      scheduledAt: at ?? now.add(const Duration(days: 3)),
      status: status,
    );

AssessmentOps ops({
  List<OpsRequest> requests = const [],
  List<OpsAssessment> assessments = const [],
  List<OpsPaper> papers = const [],
  List<OpsInterview> interviews = const [],
  bool papersKnown = true,
}) => AssessmentOps(
      requests: requests,
      assessments: assessments,
      papers: papers,
      interviews: interviews,
      now: now,
      papersKnown: papersKnown,
    );

List<String> titles(AssessmentOps o) => [for (final a in o.actions) a.title];

void main() {
  group('funnel', () {
    test('counts nothing for an empty board', () {
      final o = AssessmentOps.emptyAt(now);
      expect(o.received, 0);
      expect(o.passRate, isNull);
      expect(o.avgScore, isNull);
      expect(o.actions, isEmpty);
    });

    test('counts the live 17/15/2 shape', () {
      final o = ops(
        requests: [req(released: 17, kept: 4)],
        assessments: [
          for (final p in [95, 90, 90, 85, 85, 80, 75, 75, 70, 70, 65, 65, 60, 60, 60])
            sitting(percentage: p, released: true),
          sitting(percentage: 55, released: true),
          sitting(percentage: 45, released: true),
        ],
        papers: [(jobId: 'j1', status: 'approved', questionCount: 30)],
      );
      expect(o.received, 17);
      expect(o.invited, 17);
      expect(o.satTest, 17);
      expect(o.scored, 17);
      expect(o.passed, 15);
      expect(o.failed, 2);
      expect(o.releasedScores, 17);
      expect(o.unsentScores, 0);
      expect(o.notInvited, 0);
      expect(o.keptForInterview, 4);
      expect(o.passRate, closeTo(15 / 17, 0.001));
    });

    test('separates in-flight from expired from finished', () {
      final o = ops(
        requests: [req(candidates: 4)],
        assessments: [
          sitting(status: 'invited'),
          sitting(status: 'in_progress'),
          sitting(status: 'expired'),
          sitting(percentage: 80),
        ],
      );
      expect(o.inFlight, 2);
      expect(o.expired, 1);
      expect(o.satTest, 1);
      expect(o.sittingRate, 0.25);
    });

    test('counts candidates in a batch nobody invited', () {
      final o = ops(
        requests: [req(candidates: 17)],
        assessments: [for (var i = 0; i < 9; i++) sitting(percentage: 70)],
      );
      expect(o.notInvited, 8);
    });

    test('never reports a negative uninvited count', () {
      // More sittings than the request claims candidates would otherwise go
      // negative and render as "-2 never invited".
      final o = ops(
        requests: [req(candidates: 2)],
        assessments: [for (var i = 0; i < 4; i++) sitting(percentage: 70)],
      );
      expect(o.notInvited, 0);
    });
  });

  group('papers', () {
    test('a job with no paper blocks its batch', () {
      final o = ops(requests: [req()]);
      expect(o.jobsBlockedOnPaper, {'j1'});
      expect(titles(o).first, contains('cannot be tested yet'));
    });

    test('a draft paper still blocks — approval is the gate', () {
      final o = ops(
        requests: [req()],
        papers: [(jobId: 'j1', status: 'draft', questionCount: 60)],
      );
      expect(o.jobsBlockedOnPaper, {'j1'});
      expect(o.papersInDraft, 1);
    });

    test('an approved paper unblocks it', () {
      final o = ops(
        requests: [req()],
        papers: [(jobId: 'j1', status: 'approved', questionCount: 60)],
      );
      expect(o.jobsBlockedOnPaper, isEmpty);
      expect(o.papersApproved, 1);
    });
  });

  group('interviews', () {
    test('a booking inside 24 hours with no link is blocking', () {
      final o = ops(
        interviews: [meeting(at: now.add(const Duration(hours: 5)))],
      );
      expect(o.interviewsAtRisk, 1);
      expect(o.actions.first.urgency, OpsUrgency.blocking);
    });

    test('a booking next week with no link is only waiting', () {
      final o = ops(interviews: [meeting(at: now.add(const Duration(days: 7)))]);
      expect(o.interviewsAtRisk, 0);
      expect(o.interviewsWithoutLink, 1);
      expect(o.actions.single.urgency, OpsUrgency.waiting);
    });

    test('a cancelled interview is not counted at all', () {
      final o = ops(interviews: [meeting(status: 'cancelled')]);
      expect(o.interviewsBooked, 0);
      expect(o.interviewsWithoutLink, 0);
    });

    test('a past booking with no link is not called urgent', () {
      // It cannot be rescued by issuing a link now, so prompting for one would
      // be noise in the place the real warnings live.
      final o = ops(
        interviews: [meeting(at: now.subtract(const Duration(days: 1)))],
      );
      expect(o.interviewsAtRisk, 0);
    });
  });

  group('the action queue', () {
    test('unsent scores are named, because a recruiter is waiting', () {
      final o = ops(
        requests: [req(candidates: 3)],
        papers: [(jobId: 'j1', status: 'approved', questionCount: 30)],
        assessments: [
          sitting(percentage: 80),
          sitting(percentage: 40),
          sitting(percentage: 90, released: true),
        ],
      );
      expect(o.unsentScores, 2);
      expect(titles(o).any((t) => t.contains('2 scores not sent')), isTrue);
    });

    test('blocking outranks waiting outranks watching', () {
      final o = ops(
        requests: [req(candidates: 5, status: 'pending')],
        assessments: [
          sitting(status: 'in_progress'),
          sitting(percentage: 70),
        ],
        interviews: [meeting(at: now.add(const Duration(hours: 2)))],
      );
      final urgencies = [for (final a in o.actions) a.urgency];
      final sorted = [...urgencies]..sort((a, b) => a.index.compareTo(b.index));
      expect(urgencies, sorted);
      expect(urgencies.first, OpsUrgency.blocking);
    });

    test('nothing is invented when there is nothing to say', () {
      // A dashboard that offers advice nobody asked for teaches people to
      // ignore the panel that also carries the real warnings.
      final o = ops(
        requests: [req(candidates: 1, released: 1, kept: 1)],
        papers: [(jobId: 'j1', status: 'approved', questionCount: 30)],
        assessments: [sitting(percentage: 90, released: true)],
        interviews: [meeting(hasLink: true)],
      );
      expect(o.actions, isEmpty);
    });

    test('expiring invitations are counted only inside the window', () {
      final o = ops(
        assessments: [
          sitting(status: 'invited', expiresAt: now.add(const Duration(hours: 2))),
          sitting(status: 'invited', expiresAt: now.add(const Duration(hours: 20))),
          // Already gone — expiring is about what can still be saved.
          sitting(status: 'invited', expiresAt: now.subtract(const Duration(hours: 1))),
        ],
      );
      expect(o.expiringWithin(const Duration(hours: 6)), 1);
      expect(o.expiringWithin(const Duration(hours: 24)), 2);
    });

    test('flags tab switching without accusing anybody', () {
      final o = ops(
        assessments: [
          sitting(percentage: 70, released: true, tabSwitches: 4),
          sitting(percentage: 70, released: true, tabSwitches: 1),
        ],
      );
      expect(o.flaggedSittings, 1);
      final action = o.actions.firstWhere((a) => a.title.contains('switched tabs'));
      expect(action.urgency, OpsUrgency.watch);
      expect(action.detail, contains('Not proof of anything'));
    });
  });

  group('score histogram', () {
    test('buckets by ten points and puts 100 in the last bucket', () {
      final o = ops(
        assessments: [
          sitting(percentage: 0),
          sitting(percentage: 9),
          sitting(percentage: 60),
          sitting(percentage: 65),
          sitting(percentage: 100),
        ],
      );
      final h = o.scoreHistogram;
      expect(h.length, 10);
      expect(h[0], 2);
      expect(h[6], 2);
      expect(h[9], 1);
    });

    test('ignores sittings with no score', () {
      final o = ops(assessments: [sitting(status: 'in_progress')]);
      expect(o.scoreHistogram.reduce((a, b) => a + b), 0);
    });
  });

  group('per-job rows', () {
    test('rolls two batches of one job into one row', () {
      final o = ops(
        requests: [
          req(id: 'r1', candidates: 10),
          req(id: 'r2', candidates: 7),
        ],
        papers: [(jobId: 'j1', status: 'approved', questionCount: 30)],
        assessments: [
          sitting(requestId: 'r1', percentage: 80),
          sitting(requestId: 'r2', percentage: 40),
        ],
      );
      final row = o.jobRows.single;
      expect(row.shortlisted, 17);
      expect(row.invited, 2);
      expect(row.passed, 1);
      expect(row.failed, 1);
      expect(row.paperStatus, 'approved');
      expect(row.passRate, 0.5);
      expect(row.avgScore, 60);
    });

    test('a job with nothing scored reports null rates, not zero', () {
      final o = ops(requests: [req()], assessments: const []);
      final row = o.jobRows.single;
      expect(row.passRate, isNull);
      expect(row.avgScore, isNull);
      expect(row.paperStatus, 'none');
    });

    test('orders jobs by how many people are waiting on them', () {
      final o = ops(requests: [
        req(id: 'r1', jobId: 'small', title: 'Small', candidates: 3),
        req(id: 'r2', jobId: 'big', title: 'Big', candidates: 20),
      ]);
      expect([for (final r in o.jobRows) r.jobId], ['big', 'small']);
    });
  });

  group('papers that could not be read', () {
    // `question_banks` has no Firestore rule — it holds the answer key — so
    // paper status comes from the backend and can be missing. An empty list
    // then means "unknown", not "no paper exists", and the two lead to
    // opposite conclusions.
    final shortlist = [
      req(id: 'r1', jobId: 'j1', title: 'Avionics', candidates: 8),
    ];

    test('an empty paper list normally means every job is blocked', () {
      final o = ops(requests: shortlist);
      expect(o.jobsBlockedOnPaper, {'j1'});
      expect(titles(o), contains('1 job cannot be tested yet'));
    });

    test('but claims nothing when the feed was never read', () {
      final o = ops(requests: shortlist, papersKnown: false);
      expect(o.jobsBlockedOnPaper, isEmpty);
      expect(
        titles(o),
        isNot(contains('1 job cannot be tested yet')),
        reason: 'a red warning about an approved paper is worse than silence',
      );
    });

    test('the job table says "not checked" rather than guessing', () {
      final rows = ops(requests: shortlist, papersKnown: false).jobRows;
      expect(rows.single.paperStatus, 'unknown');
    });

    test('the rest of the board is unaffected', () {
      // The funnel is built from requests and sittings; losing paper status
      // must not cost anything else.
      final o = ops(requests: shortlist, papersKnown: false);
      expect(o.received, 8);
      expect(o.batches, 1);
      expect(o.jobRows.single.shortlisted, 8);
    });

    test('a real empty bank list is still reported as blocking', () {
      final o = ops(requests: shortlist, papers: const [], papersKnown: true);
      expect(o.jobsBlockedOnPaper, {'j1'});
    });
  });

}
