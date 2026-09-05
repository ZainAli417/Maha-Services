import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/interviews/interview.dart';
import 'package:job_portal/core/interviews/join_window.dart';

final start = DateTime(2026, 9, 10, 9);
DateTime at(int minutes) => start.add(Duration(minutes: minutes));

Interview booking({
  int minutes = 45,
  String link = 'https://zoom.us/j/123',
  String zoomId = '123',
  DateTime? linkAt,
  DateTime? movedAt,
  DateTime? startedAt,
  DateTime? endedAt,
  InterviewStatus status = InterviewStatus.scheduled,
}) =>
    Interview(
      id: 'iv1',
      candidateUid: 'cand',
      candidateName: 'A Candidate',
      jobId: 'job1',
      jobTitle: 'First Officer',
      requestId: 'req1',
      recruiterUid: 'rec1',
      scheduledAt: start,
      durationMinutes: minutes,
      mode: InterviewMode.video,
      status: status,
      meetingLink: link,
      meetingProvider: link.isEmpty ? '' : 'zoom',
      zoomMeetingId: zoomId,
      linkGeneratedAt: linkAt,
      rescheduledAt: movedAt,
      zoomStartedAt: startedAt,
      zoomEndedAt: endedAt,
    );

void main() {
  group('InterviewJoin', () {
    test('opens fifteen minutes before the start', () {
      expect(InterviewJoin.opensAt(start), at(-15));
    });

    test('stays open half an hour past the booked end', () {
      // An interview that overruns must not lock out the person still in it.
      expect(InterviewJoin.closesAt(start, 45), at(75));
    });

    test('is shut the day before and open at the boundary', () {
      expect(InterviewJoin.isOpen(start, 45, at(-24 * 60)), isFalse);
      expect(InterviewJoin.isOpen(start, 45, at(-16)), isFalse);
      expect(InterviewJoin.isOpen(start, 45, at(-15)), isTrue);
    });

    test('is open throughout the interview and shut after the grace', () {
      expect(InterviewJoin.isOpen(start, 45, at(20)), isTrue);
      expect(InterviewJoin.isOpen(start, 45, at(75)), isTrue);
      expect(InterviewJoin.isOpen(start, 45, at(76)), isFalse);
    });
  });

  group('Interview', () {
    test('cannot be joined without a link, however good the timing', () {
      expect(booking(link: '').canJoinAt(at(0)), isFalse);
      expect(booking().canJoinAt(at(0)), isTrue);
    });

    test('is live on Zoom\'s word, not the clock\'s', () {
      // The start time passing means nothing; someone has to have opened it.
      expect(booking().isLive, isFalse);
      expect(booking(startedAt: at(1)).isLive, isTrue);
      expect(booking(startedAt: at(1), endedAt: at(40)).isLive, isFalse);
    });

    test('a cancelled interview is never live', () {
      expect(
        booking(startedAt: at(1), status: InterviewStatus.cancelled).isLive,
        isFalse,
      );
    });

    test('knows when it has no Zoom meeting behind the link', () {
      expect(booking(zoomId: '').hasZoomMeeting, isFalse);
      expect(booking().hasZoomMeeting, isTrue);
    });
  });

  group('linkOutOfDate', () {
    test('is false before anything has been moved', () {
      expect(booking(linkAt: at(-1000)).linkOutOfDate, isFalse);
    });

    test('is true when the slot moved after the meeting was made', () {
      expect(
        booking(linkAt: at(-1000), movedAt: at(-100)).linkOutOfDate,
        isTrue,
      );
    });

    test('is false again once the meeting is re-issued', () {
      // The backend clears rescheduledAt when it moves the Zoom meeting.
      expect(booking(linkAt: at(-100)).linkOutOfDate, isFalse);
    });

    test('says nothing about a booking that never had a meeting', () {
      expect(booking(link: '', movedAt: at(-100)).linkOutOfDate, isFalse);
    });
  });

  group('interviewInviteText', () {
    test('carries the when, not just the link', () {
      // A bare URL is how people join a day late.
      final text = interviewInviteText(booking(linkAt: at(-100)));
      expect(text, contains('https://zoom.us/j/123'));
      expect(text, contains('First Officer'));
      expect(text, contains('Thu 10 Sep 2026'));
      expect(text, contains('09:00'));
      expect(text, contains('45 minutes'));
    });

    test('names the time zone', () {
      expect(interviewInviteText(booking()), contains(start.timeZoneName));
    });

    test('states the passcode only when there is one', () {
      expect(interviewInviteText(booking()), isNot(contains('Passcode')));
    });

    test('explains the waiting room, because the candidate will be in it', () {
      expect(interviewInviteText(booking()), contains('waiting room'));
      expect(interviewInviteText(booking()), contains('15 minutes before'));
    });

    test('falls back to the company name when the role is blank', () {
      final text = interviewInviteText(Interview(
        id: 'iv2',
        candidateUid: 'c',
        candidateName: 'C',
        jobId: 'j',
        jobTitle: '',
        requestId: 'r',
        recruiterUid: 'rec',
        scheduledAt: start,
        durationMinutes: 45,
        mode: InterviewMode.video,
        status: InterviewStatus.scheduled,
        meetingLink: 'https://zoom.us/j/9',
      ));
      expect(text, contains('Maha Services'));
    });
  });

  group('opensInLabel', () {
    test('counts down in the coarsest unit that fits', () {
      expect(opensInLabel(at(-15), at(-3 * 24 * 60)), 'in 2 days');
      expect(opensInLabel(at(-15), at(-135)), 'in 2 hours');
      expect(opensInLabel(at(-15), at(-27)), 'in 12 minutes');
    });

    test('says "now" rather than a negative', () {
      expect(opensInLabel(at(-15), at(0)), 'now');
    });

    test('rounds the last minute up so it never reads "in 0 minutes"', () {
      expect(opensInLabel(at(-15), at(-15).subtract(const Duration(seconds: 20))),
          'in 1 minute');
    });

    test('gets the singular right', () {
      expect(opensInLabel(at(-15), at(-15 - 60)), 'in 1 hour');
      expect(opensInLabel(at(-15), at(-15 - 24 * 60)), 'in 1 day');
    });
  });
}
