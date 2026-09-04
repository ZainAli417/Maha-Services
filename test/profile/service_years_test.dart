import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/profile/service_years.dart';

Map<String, dynamic> role(String start, [String? end, bool current = false]) => {
      'startDate': start,
      'endDate': end ?? '',
      'isCurrent': current,
    };

void main() {
  group('ServiceYears.from', () {
    test('measures one dated role', () {
      // The role that produced the original bug: eight years shown as "2".
      expect(ServiceYears.from([role('2008-01', '2016-02')])!.round(), 8);
    });

    test('counts overlapping postings once', () {
      // Two concurrent appointments are two lines on a CV and one stretch of a
      // career. Adding them would hand a recruiter eight years for four.
      final years = ServiceYears.from([
        role('2010-01', '2014-01'),
        role('2011-01', '2013-01'),
      ])!;
      expect(years.round(), 4);
    });

    test('adds separate stretches with a gap between them', () {
      final years = ServiceYears.from([
        role('2000-01', '2002-01'),
        role('2010-01', '2013-01'),
      ])!;
      expect(years.round(), 5);
    });

    test('returns null when nothing is dated', () {
      // Not zero. "No dates on file" and "no experience" are different claims
      // about a candidate, and only one of them is a reason not to hire.
      expect(ServiceYears.from([{'organization': 'PIA'}]), isNull);
      expect(ServiceYears.from(const []), isNull);
    });

    test('ignores a posting shorter than six months', () {
      expect(ServiceYears.from([role('2020-01', '2020-03')]), isNull);
    });

    test('ignores a role that ends before it starts', () {
      expect(ServiceYears.from([role('2016-01', '2008-01')]), isNull);
    });

    test('runs a current role up to today', () {
      final start = DateTime.now().subtract(const Duration(days: 365 * 3 + 2));
      final years = ServiceYears.from([
        role('${start.year}-${start.month.toString().padLeft(2, '0')}',
            null, true),
      ])!;
      expect(years, greaterThan(2.5));
      expect(years, lessThan(3.6));
    });
  });

  group('ServiceYears.month', () {
    test('reads the three spellings this data actually contains', () {
      expect(ServiceYears.month('2016-02'), DateTime(2016, 2));
      expect(ServiceYears.month('02/2016'), DateTime(2016, 2));
      expect(ServiceYears.month('2016'), DateTime(2016));
    });

    test('refuses an impossible month rather than guessing', () {
      expect(ServiceYears.month('2016-13'), isNull);
      expect(ServiceYears.month('13/2016'), isNull);
    });

    test('refuses anything it does not recognise', () {
      expect(ServiceYears.month('Present'), isNull);
      expect(ServiceYears.month(''), isNull);
      expect(ServiceYears.month(null), isNull);
    });
  });

  group('provenance', () {
    test('counts only the roles that carry a usable start date', () {
      final roles = [
        role('2010-01', '2012-01'),
        {'organization': 'Undated Airline'},
        role('2014', '2016'),
      ];
      expect(ServiceYears.datedRoles(roles), 2);
    });

    test('labels to one decimal, not two', () {
      // The input is month-precision. A second decimal would claim accuracy
      // the data does not have.
      expect(ServiceYears.label(8.1123), '8.1 yrs');
    });
  });
}
