import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Job_Seeker/jobs_application_provider.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';

void main() {
  // The full shape a candidate document carries, contact details included.
  Map<String, dynamic> profile() => CandidateProfile(
        uid: 'u1',
        personalInfo: const PersonalInfo(
          fullName: 'Jane Doe',
          email: 'jane@example.com',
          secondaryEmail: 'jane.alt@example.com',
          phone: '+971500000000',
          dateOfBirth: '1990-04-12',
          socialLinks: ['linkedin.com/in/janedoe'],
          nationality: 'United Arab Emirates',
          location: CandidateLocation(
              city: 'Dubai', country: 'United Arab Emirates'),
          summary: 'Airline pilot with 4500 hours.',
          profilePicUrl: 'https://example.com/pic.jpg',
          skills: ['A320', 'ATPL'],
        ),
        experience: const [
          ExperienceEntry(id: 'e1', title: 'First Officer', company: 'Emirates'),
        ],
        education: const [EducationEntry(id: 'd1', institution: 'EAU')],
        certifications: const [
          CertificationEntry(id: 'c1', name: 'CRM Recurrent'),
        ],
        // The raw answer map holds every response, contact questions included.
        answers: const {
          'email': 'jane@example.com',
          'phone': '+971500000000',
          'totalTime': 4500,
        },
      ).toJson();

  group('application snapshot redaction', () {
    test('strips every field that could contact the candidate directly', () {
      final scrubbed = JobApplicationsProvider.withoutContactDetails(profile());
      final blob = scrubbed.toString();

      for (final leak in const [
        'jane@example.com',
        'jane.alt@example.com',
        '+971500000000',
        '1990-04-12',
        'linkedin.com/in/janedoe',
      ]) {
        expect(blob.contains(leak), isFalse,
            reason: '"$leak" survived into the recruiter-readable snapshot');
      }
    });

    test('drops the raw answer map, which carries contact answers too', () {
      // personalInfo is scrubbed key by key, but `answers` is the candidate's
      // unfiltered response to every question. The recruiter-facing rendering
      // of those answers is `role_profile`, built with the same exclusions.
      final scrubbed = JobApplicationsProvider.withoutContactDetails(profile());
      expect(scrubbed.containsKey('answers'), isFalse);
    });

    test('keeps everything a recruiter needs to screen and shortlist', () {
      final scrubbed = JobApplicationsProvider.withoutContactDetails(profile());
      final personal = scrubbed['personalInfo'] as Map;

      expect(personal['fullName'], 'Jane Doe');
      expect(personal['nationality'], 'United Arab Emirates');
      expect((personal['location'] as Map)['city'], 'Dubai');
      expect(personal['summary'], 'Airline pilot with 4500 hours.');
      expect(personal['profilePicUrl'], isNotEmpty);
      expect(personal['skills'], ['A320', 'ATPL']);

      // Non-personal sections pass through untouched.
      expect(scrubbed['experience'], hasLength(1));
      expect(scrubbed['education'], hasLength(1));
      expect(scrubbed['certifications'], hasLength(1));
    });

    test('the redacted copy still parses as a profile', () {
      // The recruiter side reads it back through CandidateProfile.fromJson, so
      // scrubbing must not leave a shape the model chokes on.
      final scrubbed = JobApplicationsProvider.withoutContactDetails(profile());
      final parsed = CandidateProfile.fromJson('u1', scrubbed);

      expect(parsed.personalInfo.fullName, 'Jane Doe');
      expect(parsed.personalInfo.email, isEmpty);
      expect(parsed.personalInfo.phone, isEmpty);
      expect(parsed.experience, hasLength(1));
    });

    test('degrades safely on a missing or malformed document', () {
      expect(JobApplicationsProvider.withoutContactDetails(null), isEmpty);
      expect(JobApplicationsProvider.withoutContactDetails('nonsense'), isEmpty);
      expect(
        JobApplicationsProvider.withoutContactDetails({'targetRole': {}}),
        {'targetRole': {}},
      );
    });

    test('does not mutate the source document', () {
      final source = profile();
      JobApplicationsProvider.withoutContactDetails(source);
      expect((source['personalInfo'] as Map)['email'], 'jane@example.com');
      expect(source.containsKey('answers'), isTrue);
    });
  });
}
