import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/onboarding/cv_extraction_service.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';
import 'package:job_portal/core/onboarding/models/question.dart';
import 'package:job_portal/core/onboarding/profile_projector.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';

void main() {
  final pilot = RoleTemplateCatalogue.byId('airline_pilot')!;

  group('ProfileProjector', () {
    test('projects answers onto the structured profile sections', () {
      final projected = ProfileProjector.project(pilot, {
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'phone': '+971500000000',
        'city': 'Dubai',
        'country': 'United Arab Emirates',
        'citizenship': ['United Arab Emirates', 'United Kingdom'],
        'work_authorization': ['Permanent Resident'],
        'total_hours': 4500,
        'pic_hours': 2200,
        'issuing_authority': ['GCAA (UAE)'],
        'license_level': 'ATPL (Airline Transport)',
        'license_number': 'UAE-12345',
        'class_ratings': ['Multi-Engine Land (MEL)', 'Instrument Rating (IR)'],
        'fixed_wing_types': ['A320', 'B738'],
        'employer_type': 'Airline',
        'employer_name': 'Emirates',
      });

      expect(projected.personal.fullName, 'Jane Doe');
      expect(projected.personal.location.city, 'Dubai');
      expect(projected.personal.location.country, 'United Arab Emirates');
      expect(projected.personal.citizenship.length, 2);
      expect(projected.personal.workAuthorization, ['Permanent Resident']);

      final role = projected.roleData;
      expect(role.experienceMetrics['totalTime'], 4500);
      expect(role.experienceMetrics['pic'], 2200);
      expect(role.aircraftTypes, ['A320', 'B738']);

      // One licence entry per selected rating, all sharing the authority and
      // number captured by their sibling fields.
      final titles = role.licensesAndRatings.map((l) => l.title).toList();
      expect(titles, contains('ATPL (Airline Transport)'));
      expect(titles, contains('Multi-Engine Land (MEL)'));
      expect(titles, contains('Instrument Rating (IR)'));
      for (final l in role.licensesAndRatings) {
        expect(l.issuingAuthority, 'GCAA (UAE)');
        expect(l.licenseNumber, 'UAE-12345');
      }

      // Unmapped answers survive under attributes, keyed by question id.
      expect(role.attributes['employer_type'], 'Airline');
      expect(role.attributes['employer_name'], 'Emirates');
    });

    test('the Personal Information section captures every contact field the '
        'recruiter list and generated CV read back', () {
      final section = pilot.questionsIn('Personal Information');
      final byMapsTo = {for (final q in section) q.mapsTo: q};
      for (final path in const [
        'personalInfo.fullName',
        'personalInfo.email',
        'personalInfo.secondaryEmail',
        'personalInfo.phone',
        'personalInfo.dateOfBirth',
        'personalInfo.location.city',
        'personalInfo.location.country',
        'personalInfo.socialLinks',
        'personalInfo.summary',
      ]) {
        expect(byMapsTo.containsKey(path), isTrue,
            reason: 'Personal Information is missing $path');
      }
    });

    test('projects and reads back the contact fields', () {
      final answers = {
        'full_name': 'Jane Doe',
        'email': 'jane@example.com',
        'secondary_email': 'jane.doe@personal.com',
        'phone': '+971500000000',
        'date_of_birth': '1990-04-12T00:00:00.000',
        'social_links': ['linkedin.com/in/janedoe'],
      };
      final projected = ProfileProjector.project(pilot, answers);

      expect(projected.personal.secondaryEmail, 'jane.doe@personal.com');
      expect(projected.personal.dateOfBirth, '1990-04-12T00:00:00.000');
      expect(projected.personal.socialLinks, ['linkedin.com/in/janedoe']);

      final stored = CandidateProfile(
        uid: 'u1',
        personalInfo: projected.personal,
        roleSpecificData: projected.roleData,
      );
      final rehydrated = ProfileProjector.hydrate(pilot, stored);
      expect(rehydrated['secondary_email'], 'jane.doe@personal.com');
      expect(rehydrated['date_of_birth'], '1990-04-12T00:00:00.000');
      expect(rehydrated['social_links'], ['linkedin.com/in/janedoe']);
    });

    test('drops blank values instead of writing empty sections', () {
      final projected = ProfileProjector.project(pilot, {
        'full_name': '   ',
        'total_hours': null,
        'class_ratings': <String>[],
        'employer_name': '',
      });
      expect(projected.personal.fullName, '');
      expect(projected.roleData.experienceMetrics, isEmpty);
      expect(projected.roleData.licensesAndRatings, isEmpty);
      expect(projected.roleData.attributes, isEmpty);
    });

    test('filters "None" out of licence projections', () {
      final projected = ProfileProjector.project(pilot, {
        'instructor_ratings': ['None'],
      });
      expect(projected.roleData.licensesAndRatings, isEmpty);
    });

    test('hydrate rebuilds the answer map from a stored profile', () {
      final answers = {
        'full_name': 'Jane Doe',
        'total_hours': 4500,
        'employer_type': 'Airline',
      };
      final projected = ProfileProjector.project(pilot, answers);
      // Simulates a document whose raw answers were lost — only the projected
      // sections survive.
      final stored = CandidateProfile(
        uid: 'u1',
        personalInfo: projected.personal,
        roleSpecificData: projected.roleData,
      );

      final rehydrated = ProfileProjector.hydrate(pilot, stored);
      expect(rehydrated['full_name'], 'Jane Doe');
      expect(rehydrated['total_hours'], 4500);
      expect(rehydrated['employer_type'], 'Airline');
    });

    test('a full round-trip through Firestore JSON preserves the profile', () {
      final projected = ProfileProjector.project(pilot, {
        'full_name': 'Jane Doe',
        'total_hours': 4500,
        'fixed_wing_types': ['A320'],
      });
      final profile = CandidateProfile(
        uid: 'u1',
        targetRole: TargetRole(
            industry: pilot.industry, roleId: pilot.id, roleTitle: pilot.title),
        onboardingStatus: OnboardingStatus.completed,
        personalInfo: projected.personal,
        roleSpecificData: projected.roleData,
        experience: const [
          ExperienceEntry(
            id: 'exp1',
            title: 'First Officer',
            company: 'Emirates',
            startDate: '01/2019',
            isCurrent: true,
            responsibilities: ['Line operations'],
          ),
        ],
        education: const [
          EducationEntry(
              id: 'edu1', institution: 'EAU', graduationYear: 2016),
        ],
        answers: const {'full_name': 'Jane Doe'},
      );

      final json = profile.toJson()
        // toJson stamps a server timestamp sentinel; a read back from Firestore
        // would carry a real Timestamp instead.
        ..remove('lastUpdated');
      final restored = CandidateProfile.fromJson('u1', json);

      expect(restored.targetRole.roleId, pilot.id);
      expect(restored.onboardingStatus, OnboardingStatus.completed);
      expect(restored.personalInfo.fullName, 'Jane Doe');
      expect(restored.roleSpecificData.experienceMetrics['totalTime'], 4500);
      expect(restored.roleSpecificData.aircraftTypes, ['A320']);
      expect(restored.experience.single.title, 'First Officer');
      expect(restored.experience.single.isCurrent, isTrue);
      expect(restored.education.single.graduationYear, 2016);
      expect(restored.answers['full_name'], 'Jane Doe');
    });
  });

  group('CvExtractionService.coerceAnswer', () {
    OnboardingQuestion q(QuestionType type,
            {List<String> options = const [],
            bool allowCustom = false,
            num? min,
            num? max,
            int? maxSelect}) =>
        OnboardingQuestion(
          id: 'x',
          label: 'x',
          type: type,
          options: options,
          allowCustom: allowCustom,
          min: min,
          max: max,
          maxSelect: maxSelect,
        );

    test('parses numbers out of noisy strings and enforces bounds', () {
      final field = q(QuestionType.number, min: 0, max: 40000);
      expect(CvExtractionService.coerceAnswer(field, '4,500 hours'), 4500);
      expect(CvExtractionService.coerceAnswer(field, 4500.5), 4500.5);
      expect(CvExtractionService.coerceAnswer(field, '99,000'), isNull);
      expect(CvExtractionService.coerceAnswer(field, 'about a lot'), isNull);
    });

    test('snaps select values onto the option list', () {
      final field = q(QuestionType.singleSelect,
          options: const ['ATPL (Airline Transport)', 'CPL (Commercial)']);
      expect(CvExtractionService.coerceAnswer(field, 'ATP'),
          'ATPL (Airline Transport)');
      expect(CvExtractionService.coerceAnswer(field, 'atpl (airline transport)'),
          'ATPL (Airline Transport)');
      expect(CvExtractionService.coerceAnswer(field, 'Glider rating'), isNull);
    });

    test('resolves a bare acronym to the option that spells it out', () {
      expect(
        CvExtractionService.matchOption(
            const ['Instrument Rating (IR)', 'Multi-Engine Land (MEL)'], 'IR'),
        'Instrument Rating (IR)',
      );
    });

    test('refuses an ambiguous token rather than guessing', () {
      expect(
        CvExtractionService.matchOption(
          const ['Multi-Engine Land (MEL)', 'Single-Engine Land (SEL)'],
          'Land',
        ),
        isNull,
      );
    });

    test('keeps off-list values only when the field allows custom entries', () {
      final strict = q(QuestionType.searchMultiSelect,
          options: const ['A320'], allowCustom: false);
      final loose = q(QuestionType.searchMultiSelect,
          options: const ['A320'], allowCustom: true);
      expect(CvExtractionService.coerceAnswer(strict, ['A320', 'ZZZZ']),
          ['A320']);
      expect(CvExtractionService.coerceAnswer(loose, ['A320', 'ZZZZ']),
          ['A320', 'ZZZZ']);
    });

    test('honours maxSelect', () {
      final field = q(QuestionType.multiSelect,
          options: const ['a', 'b', 'c'], maxSelect: 2);
      expect(CvExtractionService.coerceAnswer(field, ['a', 'b', 'c']),
          ['a', 'b']);
    });

    test('normalises month/year from several written forms', () {
      final field = q(QuestionType.monthYear);
      expect(CvExtractionService.coerceAnswer(field, '3/2024'), '03/2024');
      expect(CvExtractionService.coerceAnswer(field, 'March 2024'), '03/2024');
      expect(CvExtractionService.coerceAnswer(field, '2024-03-11'), '03/2024');
      expect(CvExtractionService.coerceAnswer(field, '2024'), '01/2024');
      expect(CvExtractionService.coerceAnswer(field, '13/2024'), isNull);
    });

    test('builds the yes/no declaration shape', () {
      final field = q(QuestionType.yesNoDetail);
      expect(CvExtractionService.coerceAnswer(field, 'no'),
          {'value': false, 'details': ''});
      expect(
        CvExtractionService.coerceAnswer(
            field, {'value': 'yes', 'details': 'FAA 2019'}),
        {'value': true, 'details': 'FAA 2019'},
      );
      expect(CvExtractionService.coerceAnswer(field, 'maybe'), isNull);
    });

    test('splits tags and drops blanks', () {
      final field = q(QuestionType.tags);
      expect(CvExtractionService.coerceAnswer(field, 'A320neo, , A321LR'),
          ['A320neo', 'A321LR']);
      expect(CvExtractionService.coerceAnswer(field, ''), isNull);
    });
  });

  group('OnboardingQuestion.isAnswered', () {
    test('a "Yes" declaration is unanswered until details are given', () {
      const q = OnboardingQuestion(
        id: 'v',
        label: 'v',
        type: QuestionType.yesNoDetail,
        required: true,
      );
      expect(q.isAnswered({'value': false, 'details': ''}), isTrue);
      expect(q.isAnswered({'value': true, 'details': ''}), isFalse);
      expect(q.isAnswered({'value': true, 'details': 'FAA 2019'}), isTrue);
      expect(q.isAnswered(null), isFalse);
    });

    test('blank strings and empty lists do not count', () {
      const text =
          OnboardingQuestion(id: 't', label: 't', type: QuestionType.text);
      expect(text.isAnswered('   '), isFalse);
      expect(text.isAnswered('a'), isTrue);
      const multi = OnboardingQuestion(
          id: 'm', label: 'm', type: QuestionType.multiSelect);
      expect(multi.isAnswered(<String>[]), isFalse);
      expect(multi.isAnswered(['a']), isTrue);
    });
  });
}
