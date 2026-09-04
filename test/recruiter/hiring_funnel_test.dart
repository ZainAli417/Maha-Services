import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/recruiter/hiring_funnel.dart';

FunnelCandidate person({
  String status = 'shortlist',
  bool sentToAdmin = false,
  int? aiScore,
  String testStatus = '',
  int? testPercentage,
  String testVerdict = '',
  bool interviewBooked = false,
}) => (
      status: status,
      sentToAdmin: sentToAdmin,
      aiScore: aiScore,
      testStatus: testStatus,
      testPercentage: testPercentage,
      testVerdict: testVerdict,
      interviewBooked: interviewBooked,
    );

/// A candidate who sat the test and had their score released.
FunnelCandidate scoredPerson(int pct, {bool booked = false}) => person(
      sentToAdmin: true,
      testStatus: 'submitted',
      testPercentage: pct,
      testVerdict: pct >= 60 ? 'pass' : 'fail',
      interviewBooked: booked,
    );

void main() {
  group('HiringFunnel.from', () {
    test('counts nothing for an empty list', () {
      expect(HiringFunnel.from(const []).shortlisted, 0);
      expect(HiringFunnel.from(const []).passRate, isNull);
    });

    test('ignores candidates who are not shortlisted', () {
      // The dashboard is about the people the recruiter chose to work on.
      // Folding in every applicant would make every rate look worse than the
      // work actually being done.
      final f = HiringFunnel.from([
        person(status: 'pending'),
        person(status: 'rejected'),
        person(),
      ]);
      expect(f.shortlisted, 1);
    });

    test('counts the live 17/15/2 shape end to end', () {
      final f = HiringFunnel.from([
        for (final pct in [95, 90, 90, 85, 85, 80, 75, 75, 70, 70, 65, 65, 60, 60, 60])
          scoredPerson(pct),
        scoredPerson(55),
        scoredPerson(45),
      ]);
      expect(f.shortlisted, 17);
      expect(f.sentToAdmin, 17);
      expect(f.notSentYet, 0);
      expect(f.invited, 17);
      expect(f.satTest, 17);
      expect(f.scored, 17);
      expect(f.passed, 15);
      expect(f.failed, 2);
      expect(f.interviewReady, 15);
      expect(f.interviewBooked, 0);
      expect(f.awaitingResult, 0);
    });

    test('separates awaiting-result from expired', () {
      // Two very different facts: one candidate the recruiter is waiting on,
      // one who let the window lapse and is never coming back.
      final f = HiringFunnel.from([
        person(sentToAdmin: true, testStatus: 'in_progress'),
        person(sentToAdmin: true, testStatus: 'invited'),
        person(sentToAdmin: true, testStatus: 'expired'),
        scoredPerson(80),
      ]);
      expect(f.invited, 4);
      expect(f.satTest, 1);
      expect(f.expired, 1);
      expect(f.awaitingResult, 2);
    });

    test('a booked interview takes the candidate out of interview-ready', () {
      final f = HiringFunnel.from([
        scoredPerson(90, booked: true),
        scoredPerson(80),
      ]);
      expect(f.passed, 2);
      expect(f.interviewBooked, 1);
      expect(f.interviewReady, 1);
    });

    test('a failed candidate is never interview-ready', () {
      final f = HiringFunnel.from([scoredPerson(45)]);
      expect(f.failed, 1);
      expect(f.interviewReady, 0);
    });

    test('a score with no verdict counts as failed, not passed', () {
      // Absent is not a pass. Reading it optimistically would put an
      // unassessed candidate through the gate.
      final f = HiringFunnel.from([
        person(testStatus: 'submitted', testPercentage: 90),
      ]);
      expect(f.scored, 1);
      expect(f.passed, 0);
      expect(f.failed, 1);
    });

    test('an unreleased score is not counted', () {
      // testPercentage is null until the admin releases it. The recruiter
      // cannot see it, so the dashboard must not claim it.
      final f = HiringFunnel.from([
        person(sentToAdmin: true, testStatus: 'submitted'),
      ]);
      expect(f.satTest, 1);
      expect(f.scored, 0);
      expect(f.passRate, isNull);
    });
  });

  group('averages and rates', () {
    test('averages only over candidates who have a score', () {
      final f = HiringFunnel.from([
        person(aiScore: 80, testStatus: 'submitted', testPercentage: 60,
            testVerdict: 'pass'),
        person(aiScore: 60),
        person(),
      ]);
      expect(f.avgAiScore, 70);
      expect(f.avgTestScore, 60);
      expect(f.aiAnalysed, 2);
      expect(f.aiNotAnalysed, 1);
    });

    test('an average over nobody is null, not zero', () {
      // "Nobody has been analysed" and "everybody scored zero" are different
      // facts, and a 0 on a dashboard tile reads as the second.
      final f = HiringFunnel.from([person(), person()]);
      expect(f.avgAiScore, isNull);
      expect(f.avgTestScore, isNull);
    });

    test('rates are null rather than zero when the denominator is empty', () {
      final f = HiringFunnel.from([person()]);
      expect(f.passRate, isNull);
      expect(f.sittingRate, isNull);
      expect(f.bookedRate, isNull);
      expect(f.handoverRate, 0);
    });

    test('rates read correctly on the live shape', () {
      final f = HiringFunnel.from([
        for (var i = 0; i < 15; i++) scoredPerson(70),
        scoredPerson(50),
        scoredPerson(40),
      ]);
      expect(f.passRate, closeTo(15 / 17, 0.001));
      expect(f.handoverRate, 1);
      expect(f.sittingRate, 1);
      expect(f.bookedRate, 0);
    });
  });
}
