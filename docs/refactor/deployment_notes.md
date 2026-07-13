# Production Deployment Notes

## Order of operations
1. `firebase deploy --only firestore:indexes` — wait for the `audit_logs`
   composite index to finish building (Firebase console → Indexes).
2. `firebase deploy --only firestore:rules`.
3. Deploy the web app.
4. As an admin: **Questionnaires → Seed defaults** (one-time; writes
   `questionnaire_config/active`).

## Why rules must go out before/with the app
- The app now reads `questionnaire_config` (any authed user) and writes
  `audit_logs` (admins) — both require the new matchers.
- Recruitment-agent / super-admin accounts only get correct access once
  `isRecruiter()` / `isAdmin()` / `isSuperAdmin()` are live.
- Rules are **additive**, so deploying them ahead of the app is safe.

## Creating a super admin
Set `users/{uid}.role = 'superadmin'` (or `admin/{uid}.level = 'super'`).
Only super admins can assign admin / super-admin roles from the portal
(`Permission.assignAdminRoles`).

## Backend / external services — unchanged
The Node backend (`backend.taasgrid.com`), CV parsing, ATS, AI matching, and
the `job_alert_queue` Cloud Function are untouched.

## Post-deploy smoke
Run `docs/refactor/smoke_checklist.md` (all roles) and
`docs/refactor/regression_checklist.md`.

## Known deferrals (tracked, not done in this pass)
- **UI modernization sweep (F)** — screen restyles onto the new theme tokens +
  shared components. Deferred because it needs visual QA on a running app;
  the design system (`lib/core/theme`, `lib/core/widgets`) is in place for it.
- **Sidebar unification (A6)**, **token-delegation sweep (A7)**, **file/folder
  renames incl. `lib/SignUp ` (A8)** — pure refactors of working screens;
  high churn, no user-facing change, best done with visual QA.
- **Firestore rules catch-all narrowing** — the privileged
  `match /{allPaths=**}` admin override remains; narrowing it should be done
  against the rules emulator with a test suite.
- **True cursor pagination for user management** — current build caps the
  stream at 300 with a visible notice (bounds reads); full startAfter paging
  with server-side search is a follow-up.
