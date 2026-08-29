import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Onboarding/widgets/month_year_picker.dart';
import 'package:job_portal/core/onboarding/phone_codes.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';
import 'package:job_portal/core/onboarding/models/question.dart';

void main() {
  group('PhoneCodes.split', () {
    test('recovers the country and national part from a stored number', () {
      final r = PhoneCodes.split('+971 50 123 4567');
      expect(r.country.iso, 'AE');
      expect(r.number, '501234567');
    });

    test('prefers the longest dial code so +1868 is not read as +1', () {
      // Trinidad and Tobago shares its leading +1 with the US and Canada. A
      // naive first-match would file every Caribbean number under the US.
      expect(PhoneCodes.split('+18685551234').country.iso, 'TT');
    });

    test('a genuinely shared dial code resolves by priority, deterministically',
        () {
      // +1 covers the US, Canada and much of the Caribbean; +7 covers Russia
      // and Kazakhstan. Neither is decidable from the dial code alone, so the
      // only requirement is that the answer is stable and sensible — the
      // candidate can change the flag in one tap.
      expect(PhoneCodes.split('+15551234567').country.iso, 'US');
      expect(PhoneCodes.split('+15551234567').country.iso,
          PhoneCodes.split('+15559999999').country.iso);
      expect(PhoneCodes.split('+77015551234').country.iso, isNotEmpty);
    });

    test('falls back to the default country for a number with no dial code',
        () {
      // Legacy profiles and CV-extracted numbers were never entered through
      // this control, so they may carry no country at all. Keeping the digits
      // and letting the candidate correct the flag beats discarding them.
      final r = PhoneCodes.split('0501234567');
      expect(r.country.iso, PhoneCodes.defaultIso);
      expect(r.number, '0501234567');
    });

    test('an unrecognised dial code keeps the whole string as the number', () {
      final r = PhoneCodes.split('+999 12345');
      expect(r.number, '+999 12345');
    });

    test('empty and null inputs produce an empty number, not a crash', () {
      expect(PhoneCodes.split(null).number, '');
      expect(PhoneCodes.split('   ').number, '');
    });
  });

  group('PhoneCodes.join', () {
    test('round-trips through split without drift', () {
      final country = PhoneCodes.byIso('PK')!;
      final joined = PhoneCodes.join(country, '300 1234567');
      final back = PhoneCodes.split(joined);
      expect(back.country.iso, 'PK');
      expect(joined, '+92 300 1234567');
    });

    test('an empty national part stores nothing at all', () {
      // Otherwise a candidate who only opened the country picker would store
      // "+971", which reads as a phone number to every downstream consumer
      // and to the required-field check.
      expect(PhoneCodes.join(PhoneCodes.fallback, '  '), '');
    });
  });

  test('every dial code parses and every flag is a regional indicator pair',
      () {
    for (final c in PhoneCodes.all) {
      expect(c.dialCode.startsWith('+'), isTrue, reason: c.iso);
      expect(c.iso.length, 2, reason: c.iso);
      expect(c.flag.runes.length, 2, reason: c.iso);
    }
  });

  group('MonthYearPicker.format', () {
    test('renders storage format as something readable', () {
      expect(MonthYearPicker.format('03/2021'), 'Mar 2021');
      expect(MonthYearPicker.format('12/1999', long: true), 'December 1999');
    });

    test('passes through anything it cannot parse instead of blanking it', () {
      // A legacy value the candidate can still read is better than an empty
      // field that looks like data loss.
      expect(MonthYearPicker.format('sometime 2019'), 'sometime 2019');
      expect(MonthYearPicker.format('13/2020'), '13/2020');
      expect(MonthYearPicker.format(null), '');
    });
  });

  group('template rules', () {
    test('the phone question uses the split control', () {
      final phone = RoleTemplateCatalogue.universal
          .firstWhere((q) => q.id == 'phone');
      expect(phone.type, QuestionType.phone);
      expect(phone.mapsTo, 'personalInfo.phone');
    });

    test('the onboarding form has no Work Experience page', () {
      // Employment is captured by the role sections themselves — employer,
      // operator, aircraft, hours, recency — so a second free-form job list
      // asked the candidate for the same career twice. The ExperienceEntry
      // model stays, because the CV extractor still fills it.
      for (final role in RoleTemplateCatalogue.templates) {
        final titles = role.sections.map((s) => s.toLowerCase()).toList();
        expect(titles, isNot(contains('work experience')), reason: role.id);
      }
    });

    test('no document upload is ever required', () {
      // A missing certificate should not be able to strand a candidate in a
      // draft they can never submit.
      final blocking = <String>[];
      for (final role in RoleTemplateCatalogue.templates) {
        for (final q in role.questions) {
          if (q.type == QuestionType.file && q.required) {
            blocking.add('${role.id}.${q.id}');
          }
        }
      }
      expect(blocking, isEmpty);
    });
  });
}
