import 'package:flutter_test/flutter_test.dart';
import 'package:job_portal/core/rbac/permission.dart';
import 'package:job_portal/core/rbac/role_permissions.dart';
import 'package:job_portal/core/rbac/user_role.dart';

void main() {
  group('rolePermissions', () {
    test('every role has an entry', () {
      for (final role in UserRole.values) {
        expect(rolePermissions.containsKey(role), isTrue, reason: role.name);
      }
    });

    test('recruiter and recruitment-agent share an identical permission set',
        () {
      // Guards the "identical for now" contract — divergence must be deliberate.
      expect(
        rolePermissions[UserRole.recruiter],
        equals(rolePermissions[UserRole.recruitmentAgent]),
      );
    });

    test('admin permissions are a subset of super-admin', () {
      final admin = rolePermissions[UserRole.admin]!;
      final superAdmin = rolePermissions[UserRole.superAdmin]!;
      expect(superAdmin.containsAll(admin), isTrue);
    });

    test('only super-admin can assign admin roles / manage admins', () {
      expect(can(UserRole.superAdmin, Permission.assignAdminRoles), isTrue);
      expect(can(UserRole.superAdmin, Permission.manageAdmins), isTrue);
      expect(can(UserRole.admin, Permission.assignAdminRoles), isFalse);
      expect(can(UserRole.admin, Permission.manageAdmins), isFalse);
    });

    test('job seeker has no admin permissions', () {
      expect(can(UserRole.jobSeeker, Permission.viewAdminPortal), isFalse);
      expect(can(UserRole.jobSeeker, Permission.manageUsers), isFalse);
      expect(can(UserRole.jobSeeker, Permission.applyToJobs), isTrue);
    });

    test('recruiter can post jobs but not manage users', () {
      expect(can(UserRole.recruiter, Permission.postJobs), isTrue);
      expect(can(UserRole.recruiter, Permission.manageUsers), isFalse);
    });

    test('null role holds no permissions', () {
      expect(can(null, Permission.applyToJobs), isFalse);
    });
  });
}
