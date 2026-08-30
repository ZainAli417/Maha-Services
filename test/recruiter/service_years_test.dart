import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Recruiter/LIst_of_Applicants_provider.dart';

Map<String, dynamic> role(String start, String? end, {bool current = false}) => {
      'organization': 'PAF',
      'role': 'Technician',
      'startDate': start,
      'endDate': end ?? '',
      'isCurrent': current,
    };

num? years(List<Map<String, dynamic>> roles) =>
    ApplicantRecord.serviceYearsFrom(roles);

void main() {
  group('service years from dated roles', () {
    test('measures one posting end to end', () {
      // The case from the screenshot: a single 2008-2016 posting that was
      // being reported as "2 years" because the code counted jobs, not time.
      expect(years([role('2008-01', '2016-02')])!.round(), 8);
    });

    test('adds two separate postings', () {
      expect(
        years([role('2008-01', '2012-01'), role('2014-01', '2018-01')])!.round(),
        8,
      );
    });

    test('counts overlapping postings once', () {
      // Two concurrent appointments are two lines on a CV and one stretch of a
      // career. Adding them would hand the recruiter sixteen years for eight.
      final overlapping = [
        role('2008-01', '2016-01'),
        role('2010-01', '2014-01'),
      ];
      expect(years(overlapping)!.round(), 8);
    });

    test('merges postings that touch end to end', () {
      final backToBack = [
        role('2010-01', '2015-01'),
        role('2014-06', '2020-01'),
      ];
      expect(years(backToBack)!.round(), 10);
    });

    test('runs a current role up to today', () {
      // Anchored to this month, so the span is exactly five years however long
      // after writing this the test happens to run.
      final now = DateTime.now();
      final start = '${now.year - 5}-${now.month.toString().padLeft(2, '0')}';
      expect(years([role(start, null, current: true)])!.round(), 5);
    });

    test('an empty end date without isCurrent still runs to today', () {
      // The importer writes an empty string for an open-ended posting rather
      // than setting the flag, so treating it as "still there" is the only
      // reading that does not silently shorten a serving candidate's career.
      final now = DateTime.now();
      final start = '${now.year - 5}-${now.month.toString().padLeft(2, '0')}';
      expect(years([role(start, null)])!.round(), 5);
    });

    test('reads every date format in the data', () {
      // YYYY-MM from the importer, MM/YYYY from the onboarding form, and a
      // bare year from older records — one field, three spellings.
      expect(years([role('2010-01', '2020-01')])!.round(), 10);
      expect(years([role('01/2010', '01/2020')])!.round(), 10);
      expect(years([role('2010', '2020')])!.round(), 10);
    });

    test('is null when nothing is dated, not zero', () {
      // "No dates on file" and "no experience" are different claims, and a 0
      // here would let a years filter quietly bury the candidate.
      expect(years([role('', '')]), isNull);
      expect(years([]), isNull);
      expect(years([{'organization': 'PAF'}]), isNull);
    });

    test('ignores a role that ends before it starts', () {
      expect(years([role('2016-01', '2008-01')]), isNull);
    });

    test('ignores an impossible month', () {
      expect(years([role('2010-13', '2020-01')]), isNull);
    });

    test('does not round a few months up to a year', () {
      expect(years([role('2020-01', '2020-03')]), isNull);
    });

    test('skips an undated role but still measures the dated ones', () {
      final mixed = [
        role('2008-01', '2016-01'),
        {'organization': 'Somewhere', 'role': 'Unknown'},
      ];
      expect(years(mixed)!.round(), 8);
    });
  });
}
