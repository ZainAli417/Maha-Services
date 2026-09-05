import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/interviews/candidate_interview.dart';

final start = DateTime(2026, 9, 10, 9);
DateTime at(int minutes) => start.add(Duration(minutes: minutes));

CandidateInterview iv({
  String id = 'iv1',
  DateTime? when,
  int minutes = 45,
  String status = 'scheduled',
  bool hasLink = true,
  String link = '',
  bool live = false,
}) {
  final s = when ?? start;
  return CandidateInterview(
    id: id,
    jobTitle: 'First Officer',
    company: 'Maha',
    scheduledAt: s,
    durationMinutes: minutes,
    mode: 'video',
    status: status,
    hasLink: hasLink,
    meetingLink: link,
    joinOpensAt: s.subtract(const Duration(minutes: 15)),
    live: live,
  );
}

void main() {
  group('fromJson', () {
    test('reads what the backend actually sends', () {
      final c = CandidateInterview.fromJson({
        'interviewId': 'iv9',
        'jobTitle': 'Avionics Technician',
        'company': 'Maha',
        'scheduledAt': '2026-09-10T09:00:00.000Z',
        'durationMinutes': 30,
        'mode': 'video',
        'status': 'scheduled',
        'hasLink': true,
        'meetingLink': 'https://zoom.us/j/1',
        'joinOpensAt': '2026-09-10T08:45:00.000Z',
        'live': false,
      });
      expect(c.id, 'iv9');
      expect(c.durationMinutes, 30);
      expect(c.canJoin, isTrue);
      expect(c.scheduledAt.isUtc, isFalse); // shown in the candidate's own zone
    });

    test('survives a response with fields missing', () {
      // A partial response must not crash the dashboard.
      final c = CandidateInterview.fromJson(const {});
      expect(c.durationMinutes, 45);
      expect(c.canJoin, isFalse);
      expect(c.hasLink, isFalse);
      expect(c.live, isFalse);
    });

    test('a link withheld by the server is not a link', () {
      // hasLink true with meetingLink empty is the normal state before the
      // window opens, and it must not light up the join button.
      final c = iv(hasLink: true, link: '');
      expect(c.hasLink, isTrue);
      expect(c.canJoin, isFalse);
    });
  });

  group('next', () {
    test('is null when there is nothing booked', () {
      expect(CandidateInterviews.next(const [], start), isNull);
    });

    test('picks the soonest of several', () {
      final list = [
        iv(id: 'late', when: at(600)),
        iv(id: 'soon', when: at(60)),
        iv(id: 'later', when: at(1200)),
      ];
      expect(CandidateInterviews.next(list, start)!.id, 'soon');
    });

    test('skips a cancelled interview entirely', () {
      final list = [
        iv(id: 'off', when: at(60), status: 'cancelled'),
        iv(id: 'on', when: at(600)),
      ];
      expect(CandidateInterviews.next(list, start)!.id, 'on');
    });

    test('keeps showing one that has just overrun', () {
      // The candidate may still need to rejoin.
      final list = [iv(when: start, minutes: 45)];
      expect(CandidateInterviews.next(list, at(70)), isNotNull);
    });

    test('drops one once the grace period has passed', () {
      final list = [iv(when: start, minutes: 45)];
      expect(CandidateInterviews.next(list, at(76)), isNull);
    });

    test('moves on to the next booking once the first is done', () {
      final list = [iv(id: 'first'), iv(id: 'second', when: at(300))];
      expect(CandidateInterviews.next(list, at(76))!.id, 'second');
    });
  });

  group('refreshEvery', () {
    test('stops asking when there is nothing to wait for', () {
      expect(CandidateInterviews.refreshEvery(null, start), isNull);
    });

    test('backs off to five minutes when the interview is days away', () {
      expect(
        CandidateInterviews.refreshEvery(iv(when: at(3 * 24 * 60)), start),
        const Duration(minutes: 5),
      );
    });

    test('speeds up shortly before the link is due', () {
      // The link only appears in the response once the window opens, so this
      // is the stretch where a stale card would be visibly wrong.
      expect(
        CandidateInterviews.refreshEvery(iv(), at(-20)),
        const Duration(seconds: 30),
      );
    });

    test('stays quick throughout the interview', () {
      expect(
        CandidateInterviews.refreshEvery(iv(), at(20)),
        const Duration(seconds: 30),
      );
    });

    test('stops once the window has closed for good', () {
      expect(CandidateInterviews.refreshEvery(iv(), at(76)), isNull);
    });
  });
}
