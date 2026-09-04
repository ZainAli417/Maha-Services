import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Admin/assessment/question_bank_provider.dart';

void main() {
  group('rankRoles', () {
    test('ranks by how many candidates hold each trade', () {
      // The bug this replaces: a Set was deduplicated first and then sliced, so
      // Firestore's read order decided which trades the paper was written for.
      final out = rankRoles([
        'Loadmaster',
        for (var i = 0; i < 6; i++) 'Fighter Pilot',
        for (var i = 0; i < 3; i++) 'Air Traffic Controller',
      ]);
      expect(out.keys.toList(),
          ['Fighter Pilot', 'Air Traffic Controller', 'Loadmaster']);
      expect(out['Fighter Pilot'], 6);
      expect(out['Loadmaster'], 1);
    });

    test('fifteen pilots outrank nine one-off trades', () {
      final out = rankRoles([
        for (var i = 0; i < 15; i++) 'Fighter Pilot',
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
      ]);
      expect(out.keys.first, 'Fighter Pilot');
      expect(out.keys.take(kPromptRoleLimit).contains('Fighter Pilot'), isTrue);
    });

    test('breaks ties alphabetically so two reads agree', () {
      // Otherwise two Generate clicks could send the model different lists and
      // produce two differently-slanted papers for no visible reason.
      expect(rankRoles(['Zulu', 'Alpha', 'Mike']).keys.toList(),
          ['Alpha', 'Mike', 'Zulu']);
      expect(rankRoles(['Mike', 'Zulu', 'Alpha']).keys.toList(),
          ['Alpha', 'Mike', 'Zulu']);
    });

    test('trims, and treats a padded duplicate as the same trade', () {
      final out = rankRoles(['Pilot', ' Pilot ', 'Nav']);
      expect(out['Pilot'], 2);
      expect(out.length, 2);
    });

    test('drops blanks without spending a slot on them', () {
      expect(rankRoles(['  ', '', 'Loadmaster']).keys.toList(), ['Loadmaster']);
    });

    test('returns nothing for nothing', () {
      expect(rankRoles(const []), isEmpty);
    });
  });

  group('BankJob', () {
    BankJob job(Map<String, int> counts) => BankJob(
          jobId: 'j1',
          title: 'Role',
          candidateCount: 17,
          requestCount: 1,
          roleCounts: counts,
        );

    test('reports how many trades will not reach the prompt', () {
      final counts = {
        for (var i = 0; i < 11; i++) 'Role $i': 1,
      };
      expect(job(counts).roleOverflow, 11 - kPromptRoleLimit);
    });

    test('reports no overflow when everything fits', () {
      expect(job({'A': 5, 'B': 2}).roleOverflow, 0);
      expect(job(const {}).roleOverflow, 0);
    });

    test('roleTitles keeps the ranked order', () {
      final ranked = rankRoles(['B', 'A', 'A']);
      expect(job(ranked).roleTitles, ['A', 'B']);
    });
  });
}
