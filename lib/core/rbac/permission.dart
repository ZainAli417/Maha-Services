/// Fine-grained capabilities gated by role.
///
/// Centralizing these lets the admin portal (and any UI) check a capability
/// rather than hard-code role-string comparisons.
enum Permission {
  // Admin portal
  viewAdminPortal,
  viewAnalytics,
  viewAuditLogs,
  manageQuestionnaires,

  // User management
  manageUsers,
  createUsers,
  assignRoles, // assign non-admin roles
  assignAdminRoles, // assign admin / super-admin
  manageAdmins, // edit other admin-tier users
  suspendUsers,
  deleteUsers,
  restoreUsers,
  viewUserDocuments,
  resetUserProfile,

  // Recruiter-tier
  manageRecruiterRequests,
  postJobs,
  manageOwnJobs,
  viewCandidateProfiles,
  submitCandidateHandover,

  // Job-seeker
  applyToJobs,
  saveJobs,

  // Everyone (authenticated)
  manageOwnProfile,
  useAiTools,
}
