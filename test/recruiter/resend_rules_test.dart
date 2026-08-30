import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Recruiter/LIst_of_Applicants_provider.dart';

Map<String, dynamic> request({
  required String id,
  required List<String> candidateIds,
  bool released = false,
  int round = 1,
  List<String> scored = const [],
}) => {
      'request_id': id,
      'candidate_ids': candidateIds,
      'round': round,
      if (released) ...{
        'assessment_released_at': '2026-08-30T10:00:00Z',
        // One entry per candidate who actually has a score. The admin writes
        // this at release time; nobody else appears in it.
        'assessment_summary': {
          for (final uid in scored) uid: {'percentage': 70, 'verdict': 'pass'},
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
}
