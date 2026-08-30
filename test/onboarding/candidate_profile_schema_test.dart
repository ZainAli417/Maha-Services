import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';
import 'package:job_portal/core/onboarding/models/question.dart';
import 'package:job_portal/core/onboarding/profile_projector.dart';
import 'package:job_portal/core/onboarding/role_templates.dart';

void main() {
  group('CandidateProfile carries everything user_data used to', () {
    // Every field below was previously reachable only through the legacy
    // `user_data` layout. If one stops round-tripping, a candidate loses it on
    // their next save and nobody notices until a recruiter opens the profile.
    final full = CandidateProfile(
      uid: 'u1',
      personalInfo: const PersonalInfo(
        fullName: 'Jane Doe',
        nationality: 'Pakistan',
        objectives: 'Command a widebody fleet.',
        skills: ['CRM', 'Upset recovery'],
      ),
      education: const [
        EducationEntry(
          id: 'e1',
          institution: 'PAF Academy',
          graduationYear: 2012,
          grade: '3.8 CGPA',
        ),
      ],
      professionalStatus: 'retired',
      expectedRetirementDate: '2024-06-30',
      publications: const ['Fatigue management in long-haul ops'],
      awards: const ['Sitara-e-Basalat'],
      references: const ['Air Cdre R. Khan'],
      documents: const [
        ProfileDocument(name: 'Logbook.pdf', url: 'https://x/1'),
        ProfileDocument(
          name: 'Service letter.pdf',
          url: 'https://x/2',
          category: DocumentCategory.experience,
        ),
        ProfileDocument(
          name: 'ATPL.pdf',
          url: 'https://x/3',
          category: DocumentCategory.certification,
        ),
      ],
    );

    test('survives a round trip through Firestore JSON', () {
      final back = CandidateProfile.fromJson('u1', full.toJson());

      expect(back.personalInfo.nationality, 'Pakistan');
      expect(back.personalInfo.objectives, 'Command a widebody fleet.');
      expect(back.personalInfo.skills, ['CRM', 'Upset recovery']);
      expect(back.education.single.grade, '3.8 CGPA');
      expect(back.professionalStatus, 'retired');
      expect(back.expectedRetirementDate, '2024-06-30');
      expect(back.publications, hasLength(1));
      expect(back.awards, hasLength(1));
      expect(back.references, hasLength(1));
      expect(back.documents, hasLength(3));
    });

    test('splits documents by category', () {
      expect(full.documentsIn(DocumentCategory.general).single.name,
          'Logbook.pdf');
      expect(full.documentsIn(DocumentCategory.experience).single.name,
          'Service letter.pdf');
      expect(full.documentsIn(DocumentCategory.certification).single.name,
          'ATPL.pdf');
    });

    test('reads the education grade written under the old key', () {
      // Documents already in Firestore spell it `marksOrCgpa`. Reading both
      // costs one line; failing to read it loses the value on first save.
      final e = EducationEntry.fromJson({'id': 'x', 'marksOrCgpa': '82%'});
      expect(e.grade, '82%');
    });
  });

  group('ProfileProjector', () {
    test('a citizenship answer also settles nationality', () {
      final template = RoleTemplateCatalogue.templates
          .firstWhere((t) => t.questions.any(
              (q) => q.mapsTo == 'personalInfo.citizenship'));
      final q = template.questions
          .firstWhere((q) => q.mapsTo == 'personalInfo.citizenship');

      final projected =
          ProfileProjector.project(template, {q.id: ['Pakistan', 'Canada']});

      expect(projected.personal.citizenship, ['Pakistan', 'Canada']);
      expect(projected.personal.nationality, 'Pakistan');
    });

    test('file answers are projected into the document list', () {
      // Onboarding stores an attachment in `answers`, but the admin document
      // panel and the profile manager read `documents`. Without this
      // projection an uploaded licence is invisible to both.
      final template = RoleTemplateCatalogue.templates.firstWhere(
          (t) => t.questions.any((q) => q.type == QuestionType.file));
      final fileQ =
          template.questions.firstWhere((q) => q.type == QuestionType.file);

      final docs = ProfileProjector.documents(template, {
        fileQ.id: {
          'name': 'licence.pdf',
          'url': 'https://x/licence.pdf',
          'contentType': 'application/pdf',
        },
      });

      expect(docs, hasLength(1));
      expect(docs.single.name, 'licence.pdf');
      expect(docs.single.category, DocumentCategory.general);
    });

    test('an attachment with no url is not projected', () {
      final template = RoleTemplateCatalogue.templates.firstWhere(
          (t) => t.questions.any((q) => q.type == QuestionType.file));
      final fileQ =
          template.questions.firstWhere((q) => q.type == QuestionType.file);

      expect(
        ProfileProjector.documents(template, {
          fileQ.id: {'name': 'pending.pdf'},
        }),
        isEmpty,
      );
    });
  });
}
