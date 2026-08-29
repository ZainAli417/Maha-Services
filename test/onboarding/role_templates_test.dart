import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/onboarding/models/aviation_role.dart';
import 'package:job_portal/core/onboarding/models/question.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';

void main() {
  final templates = RoleTemplateCatalogue.templates;

  group('RoleTemplateCatalogue', () {
    test('covers both seeded industries', () {
      final industries = templates.map((t) => t.industry).toSet();
      expect(industries, contains(RoleTemplateCatalogue.aviation.title));
      expect(industries, contains(RoleTemplateCatalogue.engineering.title));
    });

    test('role ids are globally unique', () {
      final ids = templates.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('question ids are unique within every template', () {
      for (final t in templates) {
        final ids = t.questions.map((q) => q.id).toList();
        expect(ids.toSet().length, ids.length, reason: t.id);
      }
    });

    test('every template asks the universal personal questions', () {
      final universalIds =
          RoleTemplateCatalogue.universal.map((q) => q.id).toSet();
      for (final t in templates) {
        final ids = t.questions.map((q) => q.id).toSet();
        expect(ids.containsAll(universalIds), isTrue, reason: t.id);
      }
    });

    test('every select question carries options', () {
      for (final t in templates) {
        for (final q in t.questions) {
          if (q.type.isSelect) {
            expect(q.options, isNotEmpty, reason: '${t.id}/${q.id}');
          }
        }
      }
    });

    test('every conditional question points at a question in its own template',
        () {
      for (final t in templates) {
        final ids = t.questions.map((q) => q.id).toSet();
        for (final q in t.questions) {
          if (q.dependsOnId == null) continue;
          expect(ids, contains(q.dependsOnId), reason: '${t.id}/${q.id}');
        }
      }
    });

    test('conditional values are drawn from the controlling question options',
        () {
      for (final t in templates) {
        final byId = {for (final q in t.questions) q.id: q};
        for (final q in t.questions) {
          final depId = q.dependsOnId;
          if (depId == null) continue;
          final dep = byId[depId]!;
          if (dep.options.isEmpty) continue;
          for (final value in q.dependsOnValues) {
            expect(dep.options, contains(value),
                reason: '${t.id}/${q.id} depends on an option $depId does not '
                    'offer: "$value"');
          }
        }
      }
    });

    test('a conditional question is never required-and-invisible-by-default',
        () {
      // A required question behind a condition only blocks submission once its
      // condition is met, which the provider enforces via isVisible().
      for (final t in templates) {
        for (final q in t.questions) {
          if (!q.required || q.dependsOnId == null) continue;
          expect(q.dependsOnValues.isNotEmpty || q.dependsOnValue != null,
              isTrue,
              reason: '${t.id}/${q.id} is required behind an unbounded '
                  'condition');
        }
      }
    });

    // Scoped to the authored templates: the legacy aviation roles folded in
    // from AviationCatalogue keep their original question banks until each is
    // rewritten against a specification.
    test('structured controls dominate in the authored templates', () {
      for (final t in RoleTemplateCatalogue.detailed) {
        final free = t.questions
            .where((q) =>
                q.type == QuestionType.text || q.type == QuestionType.longText)
            .length;
        expect(free / t.questions.length, lessThan(0.35),
            reason: '${t.id} leans too hard on free text ($free of '
                '${t.questions.length})');
      }
    });

    test('mapsTo paths are all recognised', () {
      const known = {
        'personalInfo.fullName',
        'personalInfo.email',
        'personalInfo.phone',
        'personalInfo.summary',
        'personalInfo.profilePicUrl',
        'personalInfo.location.city',
        'personalInfo.location.country',
        'personalInfo.citizenship',
        'personalInfo.workAuthorization',
        'personalInfo.dateOfBirth',
        'personalInfo.secondaryEmail',
        'personalInfo.socialLinks',
        'roleSpecificData.licensesAndRatings',
        'roleSpecificData.licenseAuthority',
        'roleSpecificData.licenseNumber',
        'roleSpecificData.licenseExpiry',
        'roleSpecificData.typeRatingsOrAircraftTypes',
        'roleSpecificData.technicalCompetencies',
        'roleSpecificData.toolsAndSystems',
      };
      for (final t in templates) {
        for (final q in t.questions) {
          final path = q.mapsTo;
          if (path == null) continue;
          final ok = known.contains(path) ||
              path.startsWith(
                  'roleSpecificData.flightHoursOrExperienceMetrics.');
          expect(ok, isTrue, reason: '${t.id}/${q.id} -> $path');
        }
      }
    });

    test('the three specified roles keep their specification sections', () {
      final pilot = RoleTemplateCatalogue.byId('airline_pilot')!;
      expect(
        pilot.sections,
        containsAll(<String>[
          'Employer & Organization',
          'Aircraft Flown & Ratings',
          'Licensing & Certifications',
          'Flight Hours',
          'Mission & Sector Experience',
          'Recency & Compliance',
          'Documents',
        ]),
      );

      final mechanic = RoleTemplateCatalogue.byId('aircraft_mechanic')!;
      expect(
        mechanic.sections,
        containsAll(<String>[
          'Trades & Specializations',
          'Certifications & Licenses',
          'Aircraft & Facility Experience',
          'Experience & Compliance',
        ]),
      );

      final safety = RoleTemplateCatalogue.byId('safety_officer')!;
      expect(
        safety.sections,
        containsAll(<String>[
          'Role & Background',
          'Safety Specializations',
          'Certifications & Credentials',
          'Operational Environment',
          'Experience & Leadership',
        ]),
      );
    });

    test('templates survive a JSON round-trip unchanged', () {
      for (final t in templates) {
        final restored = AviationRole.fromJson(t.toJson());
        expect(restored.id, t.id);
        expect(restored.industry, t.industry);
        expect(restored.questions.length, t.questions.length);
        for (var i = 0; i < t.questions.length; i++) {
          final a = t.questions[i];
          final b = restored.questions[i];
          expect(b.id, a.id);
          expect(b.type, a.type);
          expect(b.options, a.options);
          expect(b.mapsTo, a.mapsTo);
          expect(b.dependsOnValues, a.dependsOnValues);
          expect(b.span, a.span);
          expect(b.allowCustom, a.allowCustom);
        }
      }
    });
  });
}
