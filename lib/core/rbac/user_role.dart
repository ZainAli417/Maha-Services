/// Centralized role model for Maha Services.
///
/// The app historically stored roles as free-text strings in several
/// representations (`users.role`, plus collection-existence). This enum is the
/// single source of truth for parsing those legacy values and for the canonical
/// values new code writes. Canonical strings are chosen so EXISTING production
/// documents keep working with no data migration.
enum UserRole {
  superAdmin,
  admin,
  recruiter,
  recruitmentAgent,
  jobSeeker;

  /// The canonical string written to Firestore by new code.
  ///
  /// These match what the app already writes for the pre-existing roles, so no
  /// backfill is needed. Rules lowercase before comparing, so casing here is
  /// only for human readability.
  String toFirestore() {
    switch (this) {
      case UserRole.superAdmin:
        return 'superadmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.recruiter:
        return 'Recruiter';
      case UserRole.recruitmentAgent:
        return 'Recruitment Agent';
      case UserRole.jobSeeker:
        return 'Job Seeker';
    }
  }

  /// Human-facing label.
  String get displayLabel {
    switch (this) {
      case UserRole.superAdmin:
        return 'Super Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.recruiter:
        return 'Recruiter';
      case UserRole.recruitmentAgent:
        return 'Recruitment Agent';
      case UserRole.jobSeeker:
        return 'Job Seeker';
    }
  }

  /// The legacy runtime string the router historically branched on.
  ///
  /// Used ONLY during the migration window so refactored `_normalizeRole`
  /// call sites produce byte-identical output. Agents collapse to the
  /// recruiter runtime string here.
  String get legacyRuntimeString {
    switch (this) {
      case UserRole.superAdmin:
      case UserRole.admin:
        return 'admin';
      case UserRole.recruiter:
      case UserRole.recruitmentAgent:
        return 'recruiter';
      case UserRole.jobSeeker:
        return 'Job Seeker';
    }
  }

  bool get isAdminTier =>
      this == UserRole.superAdmin || this == UserRole.admin;
  bool get isRecruiterTier =>
      this == UserRole.recruiter || this == UserRole.recruitmentAgent;

  /// Home route for this role after login.
  String get homeRoute {
    if (isAdminTier) return '/admin_dashboard';
    if (isRecruiterTier) return '/recruiter-dashboard';
    return '/dashboard';
  }

  /// Exact-case string variants seen in production for `whereIn` count queries.
  ///
  /// Firestore equality is case-sensitive, so per-role aggregate queries must
  /// enumerate the variants rather than assume one canonical value. Kept well
  /// under the 30-disjunction `whereIn` limit.
  List<String> get queryAliases {
    switch (this) {
      case UserRole.superAdmin:
        return const ['superadmin', 'SuperAdmin', 'Super Admin', 'super_admin'];
      case UserRole.admin:
        return const ['admin', 'Admin', 'ADMIN'];
      case UserRole.recruiter:
        return const ['Recruiter', 'recruiter', 'employer', 'Employer'];
      case UserRole.recruitmentAgent:
        return const [
          'Recruitment Agent',
          'recruitment agent',
          'recruitment_agent',
          'recruitmentagent',
          'agent',
          'Agent',
        ];
      case UserRole.jobSeeker:
        return const [
          'Job Seeker',
          'job seeker',
          'Job seeker',
          'jobseeker',
          'JobSeeker',
          'job_seeker',
          'candidate',
          'Candidate',
        ];
    }
  }

  /// Parse any legacy/alias string to a [UserRole]. Case-insensitive, trimmed.
  /// Returns null for unknown/empty input (caller decides the fallback).
  static UserRole? fromFirestore(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    switch (s) {
      case 'job seeker':
      case 'job_seeker':
      case 'jobseeker':
      case 'candidate':
        return UserRole.jobSeeker;
      case 'recruiter':
      case 'employer':
        return UserRole.recruiter;
      case 'recruitment agent':
      case 'recruitment_agent':
      case 'recruitmentagent':
      case 'agent':
        return UserRole.recruitmentAgent;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
      case 'super admin':
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return null;
    }
  }
}
