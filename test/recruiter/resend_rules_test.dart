import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Recruiter/LIst_of_Applicants_provider.dart';

Map<String, dynamic> request({
  required String id,
  required List<String> candidateIds,
  bool released = false,
  int round = 1,
  List<String> scored = const [],
  List<String> failed = const [],
  List<String>? finalSelection,
}) => {
      'request_id': id,
      'candidate_ids': candidateIds,
      'round': round,
      'final_selection': finalSelection ?? const <String>[],
      if (released) ...{
        'assessment_released_at': '2026-08-30T10:00:00Z',
        // One entry per candidate who actually has a score. The admin writes
        // this at release time; nobody else appears in it.
        'assessment_summary': {
          for (final uid in scored) uid: {'percentage': 70, 'verdict': 'pass'},
          for (final uid in failed) uid: {'percentage': 40, 'verdict': 'fail'},
        },
      },
    };

void main() {
  group('a candidate reopens only when their scores come back', () {
    test('nobody is resendable before a release', () {
      final p = ResendPolicy([request(id: 'r1', candidateIds: ['a', 'b'])]);
      expect(p.reopenedCandidateIds, isEmpty);
    });

    test('a release reopens only the candidates who have a score', () {
      // The other two were never invited, or have not finished. They have
      // produced nothing new, so reopening them would offer a second decision
      // on exactly the evidence the first one was made on.
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a', 'b', 'c'],
          released: true,
          scored: ['a'],
        ),
      ]);
      expect(p.reopenedCandidateIds, {'a'});
    });

    test('a released batch with nobody scored reopens nobody', () {
      final p = ResendPolicy([
        request(id: 'r1', candidateIds: ['a', 'b'], released: true),
      ]);
      expect(p.reopenedCandidateIds, isEmpty);
    });

    test('an unreleased batch stays shut while another is open', () {
      final p = ResendPolicy([
        request(id: 'r1', candidateIds: ['a'], released: true, scored: ['a']),
        request(id: 'r2', candidateIds: ['b']),
      ]);
      expect(p.reopenedCandidateIds, {'a'});
    });

    test('finds the released request a candidate belongs to', () {
      final p = ResendPolicy([
        request(id: 'r1', candidateIds: ['a'], released: true, scored: ['a']),
        request(id: 'r2', candidateIds: ['b'], released: true, scored: ['b']),
      ]);
      expect(p.releasedRequestFor('b')!['request_id'], 'r2');
      expect(p.releasedRequestFor('zzz'), isNull);
      // In the batch but without a score: not their request to reopen.
      expect(p.releasedRequestFor('c'), isNull);
    });

    test('ignores a request that has no candidate list at all', () {
      final p = ResendPolicy([
        {'request_id': 'r1', 'assessment_released_at': 'x'},
      ]);
      expect(p.reopenedCandidateIds, isEmpty);
      expect(p.releasedRequestFor('a'), isNull);
    });
  });

  group('the next round follows the one being revised', () {
    test('an untouched selection is round one', () {
      expect(const ResendPolicy([]).roundFor(['a', 'b']), 1);
    });

    test('revising a released round one produces round two', () {
      final p = ResendPolicy([
        request(
            id: 'r1', candidateIds: ['a', 'b'], released: true, scored: ['a', 'b']),
      ]);
      expect(p.roundFor(['a', 'b']), 2);
    });

    test('revising round two produces round three', () {
      final p = ResendPolicy([
        request(
            id: 'r2',
            candidateIds: ['a'],
            released: true,
            round: 2,
            scored: ['a']),
      ]);
      expect(p.roundFor(['a']), 3);
    });

    test('a mixed selection takes the highest round, not the first', () {
      // One fresh candidate alongside two being revised must not drag the
      // whole request back to round one and overwrite the history.
      final p = ResendPolicy([
        request(
            id: 'r2',
            candidateIds: ['a'],
            released: true,
            round: 2,
            scored: ['a']),
        request(id: 'r1', candidateIds: ['b'], released: true, scored: ['b']),
      ]);
      expect(p.roundFor(['a', 'b', 'fresh']), 3);
    });
  });

  group('the final selection lives on the request it revises', () {
    test('nobody is interview-ready before the recruiter answers', () {
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a', 'b', 'c'],
          released: true,
          scored: ['a', 'b', 'c'],
        ),
      ]);
      expect(p.finalSelectedCandidateIds, isEmpty);
      expect(p.supersededCandidateIds, isEmpty);
    });

    test('the kept candidates go forward and the rest are superseded', () {
      // Seventeen sent, four kept: one document holds the shortlist, the
      // scores and the answer, so the reason for the choice stays next to it.
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a', 'b', 'c', 'd'],
          released: true,
          scored: ['a', 'b', 'c', 'd'],
          finalSelection: ['a', 'c'],
          round: 2,
        ),
      ]);
      expect(p.finalSelectedCandidateIds, {'a', 'c'});
      expect(p.supersededCandidateIds, {'b', 'd'});
    });

    test('a superseded candidate is not rejected, only no longer live', () {
      // They stay in candidate_ids, which is the whole point: the record of
      // them having been considered has to survive the narrowing.
      final r = request(
        id: 'r1',
        candidateIds: ['a', 'b'],
        released: true,
        scored: ['a', 'b'],
        finalSelection: ['a'],
      );
      expect((r['candidate_ids'] as List).length, 2);
      expect(ResendPolicy.finalSelectionOf(r), ['a']);
    });

    test('finds the request a candidate was advanced in', () {
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a', 'b'],
          released: true,
          scored: ['a', 'b'],
          finalSelection: ['b'],
        ),
      ]);
      expect(p.advancedRequestFor('b')!['request_id'], 'r1');
      expect(p.advancedRequestFor('a'), isNull);
    });

    test('a request with no final selection supersedes nobody', () {
      // Guards the obvious wrong reading of the rule: an empty answer must not
      // mean "everyone was dropped".
      final p = ResendPolicy([
        request(id: 'r1', candidateIds: ['a', 'b'], released: true),
      ]);
      expect(p.supersededCandidateIds, isEmpty);
    });

    test('reads a final selection that arrives with no candidate list', () {
      final p = ResendPolicy([
        {'request_id': 'r1', 'final_selection': ['a']},
      ]);
      expect(p.finalSelectedCandidateIds, {'a'});
      expect(p.supersededCandidateIds, isEmpty);
    });
  });

  group('a failed assessment closes the question', () {
    test('a pass reopens the candidate and a fail does not', () {
      // The whole point of the rule: the recruiter still has a choice about
      // somebody who passed. Somebody who came in under the mark has been
      // decided by the test, and offering a checkbox would imply otherwise.
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a', 'b', 'c'],
          released: true,
          scored: ['a', 'b'],
          failed: ['c'],
        ),
      ]);
      expect(p.passedCandidateIds, {'a', 'b'});
      expect(p.failedCandidateIds, {'c'});
      expect(p.reopenedCandidateIds, {'a', 'b'});
    });

    test('a score with no verdict counts as not passed', () {
      // Absent is not a pass. Reading a missing verdict optimistically would
      // put an unassessed candidate in front of an interview panel.
      final p = ResendPolicy([
        {
          'request_id': 'r1',
          'candidate_ids': ['a'],
          'assessment_released_at': 'x',
          'assessment_summary': {
            'a': {'percentage': 90},
          },
        },
      ]);
      expect(p.passedCandidateIds, isEmpty);
      expect(p.failedCandidateIds, {'a'});
    });

    test('nobody is passed or failed before the release', () {
      final p = ResendPolicy([
        request(id: 'r1', candidateIds: ['a', 'b']),
      ]);
      expect(p.passedCandidateIds, isEmpty);
      expect(p.failedCandidateIds, isEmpty);
    });

    test('the interview hangs off the released request before advancement', () {
      // Booking is what advances them, so at the moment the dialog opens there
      // is no final_selection yet — and the interview still needs a request id.
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a', 'b'],
          released: true,
          scored: ['a'],
          failed: ['b'],
        ),
      ]);
      expect(p.advancedRequestFor('a'), isNull);
      expect(p.interviewRequestFor('a')!['request_id'], 'r1');
      // It answers "which request did this score come back on", for a failure
      // too. Whether an interview may be booked is decided by
      // passedCandidateIds, and putting that gate inside this lookup as well
      // would be two places to change one rule.
      expect(p.interviewRequestFor('b')!['request_id'], 'r1');
      expect(p.passedCandidateIds.contains('b'), isFalse);
    });

    test('advancement wins over the plain released request', () {
      final p = ResendPolicy([
        request(
          id: 'r1',
          candidateIds: ['a'],
          released: true,
          scored: ['a'],
          finalSelection: ['a'],
        ),
      ]);
      expect(p.interviewRequestFor('a')!['request_id'], 'r1');
      expect(p.advancedRequestFor('a')!['request_id'], 'r1');
    });
  });
}
