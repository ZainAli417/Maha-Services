# Regression Checklist

Verify existing behavior is preserved after the RBAC / admin / signup /
onboarding work. Run against a staging project with the new rules + indexes
deployed.

## Auth & routing (highest risk — B/D/E touched this)
- [ ] Existing job seeker logs in → lands on `/dashboard` (not forced into onboarding).
- [ ] Existing recruiter logs in → `/recruiter-dashboard`.
- [ ] Existing admin logs in via `/admin` → admin portal.
- [ ] Super-admin (role `superadmin`) can reach `/admin` (previously mis-routed).
- [ ] Recruitment Agent (role `Recruitment Agent`) logs in via Recruiter toggle → recruiter dashboard.
- [ ] Suspended user is signed out automatically.
- [ ] Deleted user (`account_status: deleted`) is signed out.
- [ ] Logged-out deep link to a guarded route → `/login`.
- [ ] Refresh on `/recruiter-dashboard` while logged in stays put (no ping-pong).

## Signup (D)
- [ ] "Join as Candidate" / hero "I'm a Candidate" → candidate copy, no role toggle.
- [ ] "I'm a Recruiter" → recruiter copy.
- [ ] Direct `/register` → defaults to candidate copy.
- [ ] Recruiter signup still creates recruiter + users doc, lands on recruiter dashboard.
- [ ] Candidate signup → onboarding wizard (new) → profile builder → dashboard.
- [ ] Candidate can Skip onboarding → still reaches profile builder.

## Admin portal (C)
- [ ] User list loads (now capped at 300 with a notice when exceeded).
- [ ] Search / role filter / status filter still work (including new "deleted").
- [ ] Edit user (name/level) still saves.
- [ ] Create user still works (now audited, creates collection doc).
- [ ] Suspend / activate toggles status.
- [ ] Convert role (Candidate↔Recruiter↔Agent) updates users.role + creates collection doc.
- [ ] Soft delete → user shows Deleted; Restore brings them back.
- [ ] View profile panel shows account/verification/documents.
- [ ] Bulk select → bulk suspend/activate/delete works.
- [ ] Analytics counts match Firebase console (aggregate `.count()`).
- [ ] Recruiter Requests screen unchanged.
- [ ] Audit Logs section lists actions, filter + pagination work.
- [ ] Questionnaires: Seed defaults, edit a question, Publish; onboarding reflects edits.

## Unchanged surfaces (should be byte-identical behavior)
- [ ] Post a job (quill editor), job listings, applicants, shortlisting, AI matching.
- [ ] Job hub browse/apply/save, applied-jobs tracker, saved jobs.
- [ ] Profile editing + completeness % (now single source of truth — value may shift once if the two old scorers disagreed).
- [ ] CV upload/parse, ATS analyzer, CV generator.
- [ ] Forgot password, change password.

## Build gates
- [ ] `flutter analyze` — 0 issues.
- [ ] `flutter test` — all pass.
- [ ] `flutter build web` — succeeds.
