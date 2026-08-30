import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/interviews/interview.dart';

Interview slot(
  String id,
  DateTime at, {
  int minutes = 45,
  InterviewStatus status = InterviewStatus.requested,
  String name = 'Candidate',
}) =>
    Interview(
      id: id,
      candidateUid: 'uid_$id',
      candidateName: name,
      jobId: 'job1',
      jobTitle: 'Cyber Defence',
      requestId: 'req1',
      recruiterUid: 'rec1',
      scheduledAt: at,
      durationMinutes: minutes,
      mode: InterviewMode.video,
      status: status,
    );

DateTime at(int hour, [int minute = 0]) => DateTime(2026, 9, 14, hour, minute);

void main() {
  group('clash detection', () {
    test('an overlapping booking is a clash', () {
      final booked = [slot('a', at(10))]; // 10:00–10:45
      expect(InterviewSchedule.clashes(booked, at(10, 30), 45), hasLength(1));
    });

    test('back to back is not a clash', () {
      // One finishing at 10:45 and the next starting at 10:45 is a normal
      // run of interviews, not a double booking.
      final booked = [slot('a', at(10))];
      expect(InterviewSchedule.clashes(booked, at(10, 45), 45), isEmpty);
    });

    test('a new booking that swallows an existing one is a clash', () {
      final booked = [slot('a', at(11), minutes: 30)];
      expect(InterviewSchedule.clashes(booked, at(10), 180), hasLength(1));
    });

    test('a booking entirely inside an existing one is a clash', () {
      final booked = [slot('a', at(9), minutes: 240)];
      expect(InterviewSchedule.clashes(booked, at(11), 30), hasLength(1));
    });

    test('a cancelled interview does not block the slot', () {
      final booked = [
        slot('a', at(10), status: InterviewStatus.cancelled),
      ];
      expect(InterviewSchedule.clashes(booked, at(10), 45), isEmpty);
    });

    test('the booking being edited does not clash with itself', () {
      final booked = [slot('a', at(10))];
      expect(
        InterviewSchedule.clashes(booked, at(10), 45, ignoreId: 'a'),
        isEmpty,
      );
    });

    test('a different day never clashes', () {
      final booked = [slot('a', at(10))];
      expect(
        InterviewSchedule.clashes(booked, DateTime(2026, 9, 15, 10), 45),
        isEmpty,
      );
    });
  });

  group('grouping by day', () {
    test('splits interviews across their own days', () {
      final grouped = InterviewSchedule.byDay([
        slot('a', at(10)),
        slot('b', DateTime(2026, 9, 15, 10)),
        slot('c', at(14)),
      ]);
      expect(grouped[DateTime(2026, 9, 14)], hasLength(2));
      expect(grouped[DateTime(2026, 9, 15)], hasLength(1));
    });

    test('orders each day by start time', () {
      final grouped = InterviewSchedule.byDay([
        slot('late', at(15)),
        slot('early', at(9)),
        slot('mid', at(12)),
      ]);
      expect(
        grouped[DateTime(2026, 9, 14)]!.map((i) => i.id),
        ['early', 'mid', 'late'],
      );
    });

    test('leaves cancelled interviews out of the calendar', () {
      final grouped = InterviewSchedule.byDay([
        slot('a', at(10), status: InterviewStatus.cancelled),
      ]);
      expect(grouped, isEmpty);
    });

    test('a booking just before midnight stays on its own day', () {
      final grouped = InterviewSchedule.byDay([
        slot('a', DateTime(2026, 9, 14, 23, 30)),
      ]);
      expect(grouped.keys.single, DateTime(2026, 9, 14));
    });
  });

  group('upcoming', () {
    test('drops what has already finished and sorts the rest', () {
      final past = DateTime.now().subtract(const Duration(days: 2));
      final soon = DateTime.now().add(const Duration(hours: 3));
      final later = DateTime.now().add(const Duration(days: 4));

      final upcoming = InterviewSchedule.upcoming([
        slot('later', later),
        slot('past', past),
        slot('soon', soon),
      ]);
      expect(upcoming.map((i) => i.id), ['soon', 'later']);
    });

    test('an interview running right now still counts as upcoming', () {
      // It has not finished, so a recruiter looking at "what is next" must
      // still see the one they are supposed to be in.
      final running = DateTime.now().subtract(const Duration(minutes: 10));
      final upcoming = InterviewSchedule.upcoming([slot('now', running)]);
      expect(upcoming, hasLength(1));
      expect(upcoming.single.isInProgress, isTrue);
    });

    test('a cancelled interview is never upcoming', () {
      final soon = DateTime.now().add(const Duration(hours: 2));
      expect(
        InterviewSchedule.upcoming(
            [slot('a', soon, status: InterviewStatus.cancelled)]),
        isEmpty,
      );
    });
  });

  group('an interview knows its own window', () {
    test('ends after its duration', () {
      expect(slot('a', at(10), minutes: 90).endsAt, at(11, 30));
    });

    test('is not in progress before it starts or after it ends', () {
      expect(slot('a', at(10)).isInProgress, isFalse);
      final finished =
          slot('a', DateTime.now().subtract(const Duration(hours: 3)));
      expect(finished.isInProgress, isFalse);
      expect(finished.isPast, isTrue);
    });

    test('reads an unknown mode or status as a sane default', () {
      // Documents written before a value existed must not crash the calendar.
      expect(InterviewMode.fromId('carrier_pigeon'), InterviewMode.video);
      expect(InterviewStatus.fromId(null), InterviewStatus.requested);
    });
  });
}
