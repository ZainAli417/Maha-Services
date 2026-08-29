import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/Screens/Job_Seeker/widgets/profile_timeline.dart';
import 'package:job_portal/core/onboarding/models/candidate_profile.dart';

void main() {
  CandidateProfile profileWith({
    List<ExperienceEntry> experience = const [],
    List<EducationEntry> education = const [],
    List<CertificationEntry> certifications = const [],
    List<LicenseEntry> licences = const [],
  }) =>
      CandidateProfile(
        uid: 'u1',
        experience: experience,
        education: education,
        certifications: certifications,
        roleSpecificData: RoleSpecificData(licensesAndRatings: licences),
      );

  group('ProfileTimeline.buildMilestones', () {
    test('puts the current role first, then history newest-first', () {
      final milestones = ProfileTimeline.buildMilestones(profileWith(
        experience: const [
          ExperienceEntry(
              id: '1',
              title: 'Cadet',
              company: 'Academy',
              startDate: '01/2014',
              endDate: '12/2015'),
          ExperienceEntry(
              id: '2',
              title: 'Captain',
              company: 'Emirates',
              startDate: '01/2022',
              isCurrent: true),
          ExperienceEntry(
              id: '3',
              title: 'First Officer',
              company: 'Emirates',
              startDate: '01/2016',
              endDate: '12/2021'),
        ],
      ));

      expect(milestones.map((m) => m.title).toList(),
          ['Captain', 'First Officer', 'Cadet']);
      expect(milestones.first.isCurrent, isTrue);
      expect(milestones.first.rangeLabel, '01/2022 — Present');
    });

    test('interleaves education and certifications by date', () {
      final milestones = ProfileTimeline.buildMilestones(profileWith(
        experience: const [
          ExperienceEntry(
              id: '1',
              title: 'First Officer',
              company: 'Emirates',
              startDate: '01/2018',
              endDate: '06/2020'),
        ],
        education: const [
          EducationEntry(
              id: 'e1', institution: 'EAU', graduationYear: 2016),
        ],
        certifications: const [
          CertificationEntry(
              id: 'c1', name: 'CRM Recurrent', issueDate: '03/2023'),
        ],
      ));

      expect(milestones.map((m) => m.kind).toList(), [
        MilestoneKind.certification,
        MilestoneKind.experience,
        MilestoneKind.education,
      ]);
    });

    test('licences sort below dated history rather than to the top', () {
      final milestones = ProfileTimeline.buildMilestones(profileWith(
        education: const [
          EducationEntry(id: 'e1', institution: 'EAU', graduationYear: 2016),
        ],
        licences: const [
          LicenseEntry(title: 'ATPL', issuingAuthority: 'GCAA'),
        ],
      ));
      expect(milestones.last.kind, MilestoneKind.licence);
    });

    test('flags expired and expiring credentials', () {
      final now = DateTime.now();
      String my(DateTime d) =>
          '${d.month.toString().padLeft(2, '0')}/${d.year}';

      final milestones = ProfileTimeline.buildMilestones(profileWith(
        licences: [
          LicenseEntry(
              title: 'Lapsed medical',
              expiryDate: my(DateTime(now.year - 2, now.month))),
          LicenseEntry(
              title: 'Medical due soon',
              expiryDate: my(DateTime(now.year, now.month + 1))),
          LicenseEntry(
              title: 'Medical in good standing',
              expiryDate: my(DateTime(now.year + 3, now.month))),
        ],
      ));

      final byTitle = {for (final m in milestones) m.title: m};
      expect(byTitle['Lapsed medical']!.isExpired, isTrue);
      expect(byTitle['Lapsed medical']!.isExpiringSoon, isFalse);
      expect(byTitle['Medical due soon']!.isExpiringSoon, isTrue);
      expect(byTitle['Medical due soon']!.isExpired, isFalse);
      expect(byTitle['Medical in good standing']!.isExpired, isFalse);
      expect(byTitle['Medical in good standing']!.isExpiringSoon, isFalse);
    });

    test('a licence valid through the end of this month is not expired', () {
      final now = DateTime.now();
      final milestones = ProfileTimeline.buildMilestones(profileWith(
        licences: [
          LicenseEntry(
            title: 'Medical',
            expiryDate:
                '${now.month.toString().padLeft(2, '0')}/${now.year}',
          ),
        ],
      ));
      expect(milestones.single.isExpired, isFalse);
    });

    test('is empty for a profile with no history', () {
      expect(ProfileTimeline.buildMilestones(profileWith()), isEmpty);
    });
  });
}
