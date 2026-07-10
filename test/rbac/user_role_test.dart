import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/rbac/user_role.dart';

void main() {
  group('UserRole.fromFirestore', () {
    test('parses job-seeker aliases', () {
      for (final s in [
        'Job Seeker',
        'job seeker',
        'JOBSEEKER',
        'job_seeker',
        'candidate',
        '  Candidate  ',
      ]) {
        expect(UserRole.fromFirestore(s), UserRole.jobSeeker, reason: s);
      }
    });

    test('parses recruiter aliases', () {
      for (final s in ['Recruiter', 'recruiter', 'employer', 'EMPLOYER']) {
        expect(UserRole.fromFirestore(s), UserRole.recruiter, reason: s);
      }
    });

    test('parses recruitment-agent aliases', () {
      for (final s in [
        'Recruitment Agent',
        'recruitment agent',
        'recruitment_agent',
        'recruitmentagent',
        'agent',
      ]) {
        expect(
            UserRole.fromFirestore(s), UserRole.recruitmentAgent, reason: s);
      }
    });

    test('parses admin and super-admin aliases distinctly', () {
      expect(UserRole.fromFirestore('admin'), UserRole.admin);
      expect(UserRole.fromFirestore('ADMIN'), UserRole.admin);
      for (final s in ['superadmin', 'super admin', 'super_admin']) {
        expect(UserRole.fromFirestore(s), UserRole.superAdmin, reason: s);
      }
    });

    test('returns null for unknown/empty/null', () {
      expect(UserRole.fromFirestore(null), isNull);
      expect(UserRole.fromFirestore(''), isNull);
      expect(UserRole.fromFirestore('   '), isNull);
      expect(UserRole.fromFirestore('pilot'), isNull);
    });
  });

  group('canonical round-trip', () {
    test('fromFirestore(toFirestore()) is identity for every role', () {
      for (final role in UserRole.values) {
        expect(UserRole.fromFirestore(role.toFirestore()), role,
            reason: role.name);
      }
    });

    test('queryAliases contain the canonical stored string', () {
      for (final role in UserRole.values) {
        expect(role.queryAliases, contains(role.toFirestore()),
            reason: role.name);
      }
    });

    test('every queryAlias parses back to its own role', () {
      for (final role in UserRole.values) {
        for (final alias in role.queryAliases) {
          expect(UserRole.fromFirestore(alias), role, reason: '$role/$alias');
        }
      }
    });
  });

  group('tier groupings & routing', () {
    test('admin tier', () {
      expect(UserRole.superAdmin.isAdminTier, isTrue);
      expect(UserRole.admin.isAdminTier, isTrue);
      expect(UserRole.recruiter.isAdminTier, isFalse);
      expect(UserRole.jobSeeker.isAdminTier, isFalse);
    });

    test('recruiter tier includes agent', () {
      expect(UserRole.recruiter.isRecruiterTier, isTrue);
      expect(UserRole.recruitmentAgent.isRecruiterTier, isTrue);
      expect(UserRole.admin.isRecruiterTier, isFalse);
    });

    test('home routes', () {
      expect(UserRole.superAdmin.homeRoute, '/admin_dashboard');
      expect(UserRole.admin.homeRoute, '/admin_dashboard');
      expect(UserRole.recruiter.homeRoute, '/recruiter-dashboard');
      expect(UserRole.recruitmentAgent.homeRoute, '/recruiter-dashboard');
      expect(UserRole.jobSeeker.homeRoute, '/dashboard');
    });

    test('legacyRuntimeString matches the pre-refactor router strings', () {
      expect(UserRole.superAdmin.legacyRuntimeString, 'admin');
      expect(UserRole.admin.legacyRuntimeString, 'admin');
      expect(UserRole.recruiter.legacyRuntimeString, 'recruiter');
      expect(UserRole.recruitmentAgent.legacyRuntimeString, 'recruiter');
      expect(UserRole.jobSeeker.legacyRuntimeString, 'Job Seeker');
    });
  });
}
