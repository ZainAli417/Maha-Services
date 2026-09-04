import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Recruiter/LIst_of_Applicants_provider.dart';

/// A candidate reduced to the only thing the ordering reads.
typedef Row = ({String name, num? score});

List<String> names(List<Row> rows) => [for (final r in rows) r.name];

List<Row> sorted(List<Row> rows, {required bool ascending}) =>
    ShortlistOrder.by(rows, value: (r) => r.score, ascending: ascending);

void main() {
  group('ShortlistOrder.by', () {
    test('highest first', () {
      final out = sorted([
        (name: 'low', score: 45),
        (name: 'high', score: 95),
        (name: 'mid', score: 70),
      ], ascending: false);
      expect(names(out), ['high', 'mid', 'low']);
    });

    test('lowest first', () {
      final out = sorted([
        (name: 'low', score: 45),
        (name: 'high', score: 95),
        (name: 'mid', score: 70),
      ], ascending: true);
      expect(names(out), ['low', 'mid', 'high']);
    });

    test('keeps candidates with no score at the end, descending', () {
      final out = sorted([
        (name: 'none', score: null),
        (name: 'high', score: 95),
        (name: 'low', score: 45),
      ], ascending: false);
      expect(names(out), ['high', 'low', 'none']);
    });

    test('keeps candidates with no score at the end, ascending too', () {
      // The rule that matters. "Not analyzed" is not a low score, and treating
      // it as one would bury every candidate who actually sat the test
      // underneath everyone who never took it.
      final out = sorted([
        (name: 'none', score: null),
        (name: 'high', score: 95),
        (name: 'low', score: 45),
      ], ascending: true);
      expect(names(out), ['low', 'high', 'none']);
    });

    test('does not confuse an absent score with zero', () {
      final out = sorted([
        (name: 'zero', score: 0),
        (name: 'none', score: null),
        (name: 'low', score: 45),
      ], ascending: true);
      expect(names(out), ['zero', 'low', 'none']);
    });

    test('is stable across ties', () {
      // Three candidates on 12/20 is the live data. They have to keep the same
      // relative order on every rebuild — Dart's List.sort does not promise it.
      final rows = [
        (name: 'a', score: 60),
        (name: 'b', score: 60),
        (name: 'c', score: 60),
        (name: 'd', score: 95),
      ];
      expect(names(sorted(rows, ascending: false)), ['d', 'a', 'b', 'c']);
      expect(names(sorted(rows, ascending: true)), ['a', 'b', 'c', 'd']);
    });

    test('is stable across ties among the unscored as well', () {
      final rows = [
        (name: 'x', score: null),
        (name: 'y', score: null),
        (name: 'z', score: 70),
      ];
      expect(names(sorted(rows, ascending: false)), ['z', 'x', 'y']);
      expect(names(sorted(rows, ascending: true)), ['z', 'x', 'y']);
    });

    test('leaves the original list untouched', () {
      final rows = [(name: 'a', score: 10), (name: 'b', score: 90)];
      sorted(rows, ascending: false);
      expect(names(rows), ['a', 'b']);
    });

    test('handles an empty list and a single row', () {
      expect(sorted(const [], ascending: false), isEmpty);
      expect(names(sorted([(name: 'only', score: null)], ascending: true)),
          ['only']);
    });
  });

  group('ShortlistOrder.cycle', () {
    test('a first click sorts highest first', () {
      // What a recruiter is actually asking when they click a score column.
      final next = ShortlistOrder.cycle(null, ShortlistSortColumn.testScore);
      expect(next, (column: ShortlistSortColumn.testScore, ascending: false));
    });

    test('a second click reverses it', () {
      final next = ShortlistOrder.cycle(
        (column: ShortlistSortColumn.testScore, ascending: false),
        ShortlistSortColumn.testScore,
      );
      expect(next, (column: ShortlistSortColumn.testScore, ascending: true));
    });

    test('a third click clears the sort', () {
      // There has to be a way back to the order the list arrived in.
      final next = ShortlistOrder.cycle(
        (column: ShortlistSortColumn.testScore, ascending: true),
        ShortlistSortColumn.testScore,
      );
      expect(next, isNull);
    });

    test('clicking a different column starts that column at highest first', () {
      final next = ShortlistOrder.cycle(
        (column: ShortlistSortColumn.testScore, ascending: true),
        ShortlistSortColumn.aiScore,
      );
      expect(next, (column: ShortlistSortColumn.aiScore, ascending: false));
    });
  });
}
