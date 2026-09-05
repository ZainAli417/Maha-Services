import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/assessments/candidate_sitting.dart';

final day = DateTime(2026, 9, 1);

CandidateSitting s({
  String id = 'a1',
  String jobId = 'j1',
  String title = 'Cyber Defence',
  String company = 'Edwars',
  String status = 'invited',
  int answered = 0,
  int? score,
  int daysAgo = 0,
}) =>
    CandidateSitting(
      id: id,
      jobId: jobId,
      jobTitle: title,
      company: company,
      status: status,
      answeredCount: answered,
      questionCount: 20,
      invitedAt: day.subtract(Duration(days: daysAgo)),
      expiresAt: day.add(const Duration(hours: 24)),
      score: score,
      correct: score == null ? null : (score / 5).round(),
      skipped: score == null ? null : 2,
    );

void main() {
  group('fromJson', () {
    test('reads what the server actually sends', () {
      final c = CandidateSitting.fromJson({
        'assessmentId': 'x1',
        'jobId': 'j9',
        'jobTitle': 'Avionics',
        'company': 'Maha',
        'status': 'submitted',
        'answeredCount': 18,
        'questionCount': 20,
        'invitedAt': day.millisecondsSinceEpoch,
        'expiresAt': null,
        'result': {'percentage': 75, 'correct': 15, 'skipped': 2},
      });
      expect(c.id, 'x1');
      expect(c.score, 75);
      expect(c.isDone, isTrue);
      expect(c.expiresAt, isNull);
    });

    test('survives a response with nothing in it', () {
      final c = CandidateSitting.fromJson(const {});
      expect(c.questionCount, 20);
      expect(c.score, isNull);
      expect(c.isOpen, isTrue);
    });

    test('an unmarked sitting has no score rather than zero', () {
      // Zero would read as "you got nothing right".
      final c = CandidateSitting.fromJson({'status': 'in_progress'});
      expect(c.score, isNull);
      expect(c.isStarted, isTrue);
    });
  });

  group('a single sitting', () {
    test('knows what the candidate should do about it', () {
      expect(s(status: 'invited').action, 'Start');
      expect(s(status: 'accepted').action, 'Start');
      expect(s(status: 'in_progress').action, 'Resume');
      expect(s(status: 'submitted').action, 'View result');
      expect(s(status: 'expired').action, 'Closed');
    });

    test('is open until it is marked or lapses', () {
      expect(s(status: 'invited').isOpen, isTrue);
      expect(s(status: 'in_progress').isOpen, isTrue);
      expect(s(status: 'submitted').isOpen, isFalse);
      expect(s(status: 'expired').isOpen, isFalse);
    });

    test('reports progress without dividing by zero', () {
      expect(s(answered: 5).progress, 0.25);
      expect(
        CandidateSitting.fromJson({'questionCount': 0}).progress,
        0,
      );
    });
  });

  group('search', () {
    final all = [
      s(id: 'a', title: 'Cyber Defence', company: 'Edwars'),
      s(id: 'b', title: 'Avionics Engineer', company: 'Maha Air'),
    ];

    test('matches the job title, case-insensitively', () {
      expect(SittingLibrary.search(all, 'avionics').single.id, 'b');
      expect(SittingLibrary.search(all, 'CYBER').single.id, 'a');
    });

    test('matches the company too', () {
      expect(SittingLibrary.search(all, 'maha').single.id, 'b');
    });

    test('an empty query changes nothing', () {
      expect(SittingLibrary.search(all, '   ').length, 2);
    });

    test('does not quietly double as a status filter', () {
      // "expired" belongs to the filter row. Two ways of doing it would
      // disagree the day one of them changed.
      expect(SittingLibrary.search([s(status: 'expired')], 'expired'), isEmpty);
    });
  });

  group('filter', () {
    final all = [
      s(id: 'open', status: 'invited'),
      s(id: 'running', status: 'in_progress'),
      s(id: 'done', status: 'submitted', score: 80),
      s(id: 'gone', status: 'expired'),
    ];

    test('to do covers both invited and half-finished', () {
      expect(
        SittingLibrary.filter(all, SittingFilter.toDo).map((x) => x.id),
        ['open', 'running'],
      );
    });

    test('completed and expired are separate', () {
      expect(SittingLibrary.filter(all, SittingFilter.completed).single.id, 'done');
      expect(SittingLibrary.filter(all, SittingFilter.expired).single.id, 'gone');
    });

    test('all means all', () {
      expect(SittingLibrary.filter(all, SittingFilter.all).length, 4);
    });
  });

  group('byJob', () {
    test('gathers sittings under one job', () {
      final g = SittingLibrary.byJob([
        s(id: 'a', jobId: 'j1', status: 'submitted', score: 70, daysAgo: 5),
        s(id: 'b', jobId: 'j1', status: 'invited'),
        s(id: 'c', jobId: 'j2', status: 'submitted', score: 60, daysAgo: 9),
      ]);
      expect(g.length, 2);
      expect(g.first.sittings.length, 2);
    });

    test('a job with something still to sit comes first, however old', () {
      // That is the one with a deadline on it.
      final g = SittingLibrary.byJob([
        s(id: 'recent', jobId: 'new', status: 'submitted', score: 90),
        s(id: 'waiting', jobId: 'old', status: 'invited', daysAgo: 40),
      ]);
      expect(g.first.jobId, 'old');
    });

    test('within a job, open first then newest', () {
      final g = SittingLibrary.byJob([
        s(id: 'old', status: 'submitted', score: 50, daysAgo: 9),
        s(id: 'newer', status: 'submitted', score: 60, daysAgo: 2),
        s(id: 'open', status: 'invited', daysAgo: 30),
      ]);
      expect(g.single.sittings.map((x) => x.id), ['open', 'newer', 'old']);
    });

    test('falls back to the title when a job id is missing', () {
      final g = SittingLibrary.byJob([s(jobId: '', title: 'Loose Role')]);
      expect(g.single.jobTitle, 'Loose Role');
    });

    test('never shows a blank heading', () {
      final g = SittingLibrary.byJob([s(jobId: 'j1', title: '')]);
      expect(g.single.jobTitle, 'Untitled role');
    });

    test('is empty for an empty list rather than throwing', () {
      expect(SittingLibrary.byJob(const []), isEmpty);
    });
  });

  group('toDoCount', () {
    test('counts only what is waiting on the candidate', () {
      expect(
        SittingLibrary.toDoCount([
          s(status: 'invited'),
          s(status: 'in_progress'),
          s(status: 'submitted', score: 80),
          s(status: 'expired'),
        ]),
        2,
      );
    });
  });

  group('record', () {
    test('averages and bests only the marked sittings', () {
      final r = SittingLibrary.record([
        s(status: 'submitted', score: 80),
        s(status: 'submitted', score: 60),
        s(status: 'invited'),
      ]);
      expect(r.taken, 2);
      expect(r.average, 70);
      expect(r.best, 80);
    });

    test('rounds the average rather than truncating it', () {
      final r = SittingLibrary.record([
        s(status: 'submitted', score: 80),
        s(status: 'submitted', score: 75),
      ]);
      expect(r.average, 78);
    });

    test('has no average at all before any test is marked', () {
      // Zero would read as "you averaged nought".
      final r = SittingLibrary.record([s(status: 'invited')]);
      expect(r.taken, 0);
      expect(r.average, isNull);
      expect(r.best, isNull);
    });

    test('does not count a submitted sitting whose score is missing', () {
      final r = SittingLibrary.record([s(status: 'submitted')]);
      expect(r.taken, 1);
      expect(r.average, isNull);
    });
  });
}
