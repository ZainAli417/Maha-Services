import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Job_Seeker/jobs_application_provider.dart';

void main() {
  // The full shape a candidate document carries, contact details included.
  Map<String, dynamic> userData() => {
        'personalProfile': {
          'name': 'Jane Doe',
          'fullName': 'Jane Doe',
          'email': 'jane@example.com',
          'secondary_email': 'jane.alt@example.com',
          'contactNumber': '+971500000000',
          'phone': '+971500000000',
          'dob': '1990-04-12',
          'socialLinks': ['linkedin.com/in/janedoe'],
          'nationality': 'United Arab Emirates',
          'location': 'Dubai, United Arab Emirates',
          'summary': 'Airline pilot with 4500 hours.',
          'profilePicUrl': 'https://example.com/pic.jpg',
          'skills': ['A320', 'ATPL'],
        },
        'professionalExperience': [
          {'organization': 'Emirates', 'role': 'First Officer'},
        ],
        'educationalProfile': [
          {'institutionName': 'EAU'},
        ],
        'certifications': [
          {'name': 'CRM Recurrent'},
        ],
      };

  group('application snapshot redaction', () {
    test('strips every field that could contact the candidate directly', () {
      final scrubbed =
          JobApplicationsProvider.withoutContactDetails(userData());
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

    test('keeps everything a recruiter needs to screen and shortlist', () {
      final scrubbed =
          JobApplicationsProvider.withoutContactDetails(userData());
      final personal = scrubbed['personalProfile'] as Map;

      expect(personal['name'], 'Jane Doe');
      expect(personal['nationality'], 'United Arab Emirates');
      expect(personal['location'], 'Dubai, United Arab Emirates');
      expect(personal['summary'], 'Airline pilot with 4500 hours.');
      expect(personal['profilePicUrl'], isNotEmpty);
      expect(personal['skills'], ['A320', 'ATPL']);

      // Non-personal sections pass through untouched.
      expect(scrubbed['professionalExperience'], hasLength(1));
      expect(scrubbed['educationalProfile'], hasLength(1));
      expect(scrubbed['certifications'], hasLength(1));
    });

    test('handles the snake_case personal_profile variant', () {
      final scrubbed = JobApplicationsProvider.withoutContactDetails({
        'personal_profile': {
          'name': 'Jane',
          'email': 'jane@example.com',
          'contact_number': '+971500000000',
        },
      });
      final personal = scrubbed['personal_profile'] as Map;
      expect(personal['name'], 'Jane');
      expect(personal.containsKey('email'), isFalse);
      expect(personal.containsKey('contact_number'), isFalse);
    });

    test('degrades safely on a missing or malformed document', () {
      expect(JobApplicationsProvider.withoutContactDetails(null), isEmpty);
      expect(JobApplicationsProvider.withoutContactDetails('nonsense'), isEmpty);
      expect(
        JobApplicationsProvider.withoutContactDetails({'user_profile': {}}),
        {'user_profile': {}},
      );
    });

    test('does not mutate the source document', () {
      final source = userData();
      JobApplicationsProvider.withoutContactDetails(source);
      expect((source['personalProfile'] as Map)['email'], 'jane@example.com');
    });
  });
}
