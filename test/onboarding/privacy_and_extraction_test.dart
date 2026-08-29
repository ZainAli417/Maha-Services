import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';
import 'package:job_portal/core/onboarding/models/question.dart';
import 'package:job_portal/core/onboarding/role_profile_snapshot.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';

void main() {
  group('CV extraction scope', () {
    test('legal declarations are never sent to the extractor', () {
      for (final t in RoleTemplateCatalogue.templates) {
        for (final q in t.questions) {
          if (q.type != QuestionType.yesNoDetail) continue;
          expect(q.cvExtractable, isFalse,
              reason: '${t.id}/${q.id} is a declaration — a model must never '
                  'infer it from what a CV omits');
        }
      }
    });

    test('availability and preference fields are withheld', () {
      const mustBeWithheld = {
        'notice_period',
        'employment_status',
        'employment_type',
        'preferred_regions',
        'willing_relocate',
        'work_authorization',
        'toolbox_status',
      };
      for (final t in RoleTemplateCatalogue.templates) {
        for (final q in t.questions) {
          if (!mustBeWithheld.contains(q.id)) continue;
          expect(q.cvExtractable, isFalse, reason: '${t.id}/${q.id}');
        }
      }
    });

    test('the facts a CV really does carry are still requested', () {
      final pilot = RoleTemplateCatalogue.byId('airline_pilot')!;
      final byId = {for (final q in pilot.questions) q.id: q};
      for (final id in const [
        'full_name',
        'email',
        'phone',
        'date_of_birth',
        'total_hours',
        'pic_hours',
        'license_level',
        'type_ratings',
        'fixed_wing_types',
        'employer_name',
      ]) {
        expect(byId[id]?.cvExtractable, isTrue, reason: id);
      }
    });

    test('withholding trims the prompt without gutting it', () {
      for (final id in const [
        'airline_pilot',
        'aircraft_mechanic',
        'safety_officer'
      ]) {
        final t = RoleTemplateCatalogue.byId(id)!;
        final sent = t.questions
            .where((q) => q.type != QuestionType.file && q.cvExtractable)
            .length;
        final total =
            t.questions.where((q) => q.type != QuestionType.file).length;
        expect(sent / total, greaterThan(0.6), reason: '$id sends too little');
        expect(sent / total, lessThan(0.95), reason: '$id withholds too little');
      }
    });
  });

  group('contact privacy', () {
    final pilot = RoleTemplateCatalogue.byId('airline_pilot')!;

    CandidateProfile profileWithContact() => CandidateProfile(
          uid: 'u1',
          targetRole: TargetRole(
              industry: pilot.industry,
              roleId: pilot.id,
              roleTitle: pilot.title),
          answers: const {
            'full_name': 'Jane Doe',
            'email': 'jane@example.com',
            'secondary_email': 'jane.alt@example.com',
            'phone': '+971500000000',
            'date_of_birth': '1990-04-12T00:00:00.000',
            'social_links': ['linkedin.com/in/janedoe'],
            'city': 'Dubai',
            'country': 'United Arab Emirates',
            'total_hours': 4500,
            'license_level': 'ATPL (Airline Transport)',
          },
        );

    test('the shared snapshot carries no contact details at all', () {
      final snapshot =
          RoleProfileSnapshot.build(profileWithContact(), pilot);
      final blob = snapshot.toJson().toString();

      for (final leak in const [
        'jane@example.com',
        'jane.alt@example.com',
        '+971500000000',
        'linkedin.com/in/janedoe',
        '1990-04-12',
      ]) {
        expect(blob.contains(leak), isFalse,
            reason: 'contact detail "$leak" leaked into the role profile '
                'snapshot, which recruiters can read');
      }
    });

    test('non-contact answers still travel', () {
      final snapshot =
          RoleProfileSnapshot.build(profileWithContact(), pilot);
      final blob = snapshot.toJson().toString();
      expect(blob.contains('4500'), isTrue);
      expect(blob.contains('ATPL (Airline Transport)'), isTrue);
      // City and country identify where someone can work — not a direct
      // channel to them — so they stay visible.
      expect(blob.contains('Dubai'), isTrue);
    });

    test('every contact path is covered by the redaction set', () {
      final contactFields = pilot.questions.where((q) =>
          q.mapsTo != null &&
          RoleProfileSnapshot.contactPaths.contains(q.mapsTo));
      expect(contactFields.map((q) => q.id).toSet(), {
        'email',
        'secondary_email',
        'phone',
        'date_of_birth',
        'social_links',
      });
    });
  });
}
