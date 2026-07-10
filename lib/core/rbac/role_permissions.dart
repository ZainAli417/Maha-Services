import 'permission.dart';
import 'user_role.dart';

/// Maps each [UserRole] to the set of [Permission]s it holds.
///
/// IMPORTANT: [UserRole.recruiter] and [UserRole.recruitmentAgent] intentionally
/// share the SAME permission set object for now (see [_recruiterTier]). A unit
/// test asserts this equality, so any future divergence is a deliberate,
/// reviewed change rather than an accident.
const Set<Permission> _recruiterTier = {
  Permission.postJobs,
  Permission.manageOwnJobs,
  Permission.viewCandidateProfiles,
  Permission.submitCandidateHandover,
  Permission.manageRecruiterRequests,
  Permission.manageOwnProfile,
  Permission.useAiTools,
};

const Set<Permission> _jobSeekerTier = {
  Permission.applyToJobs,
  Permission.saveJobs,
  Permission.manageOwnProfile,
  Permission.useAiTools,
};

// Everything an admin can do (super admin gets this plus admin management).
const Set<Permission> _adminTier = {
  Permission.viewAdminPortal,
  Permission.viewAnalytics,
  Permission.viewAuditLogs,
  Permission.manageQuestionnaires,
  Permission.manageUsers,
  Permission.createUsers,
  Permission.assignRoles,
  Permission.suspendUsers,
  Permission.deleteUsers,
  Permission.restoreUsers,
  Permission.viewUserDocuments,
  Permission.resetUserProfile,
  Permission.manageRecruiterRequests,
  Permission.viewCandidateProfiles,
};

final Map<UserRole, Set<Permission>> rolePermissions = {
  UserRole.superAdmin: {
    ..._adminTier,
    Permission.assignAdminRoles,
    Permission.manageAdmins,
  },
  UserRole.admin: _adminTier,
  UserRole.recruiter: _recruiterTier,
  UserRole.recruitmentAgent: _recruiterTier,
  UserRole.jobSeeker: _jobSeekerTier,
};

/// Whether [role] holds [permission]. Null role → false.
bool can(UserRole? role, Permission permission) {
  if (role == null) return false;
  return rolePermissions[role]?.contains(permission) ?? false;
}
