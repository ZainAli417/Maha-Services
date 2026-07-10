# Refactor Baseline (P0)

Captured before the refactor program begins. Every increment must keep
`flutter analyze` at or below this baseline and keep `flutter build web` green.

- **Date captured:** 2026-07-10
- **Branch:** maha_dev
- **`flutter analyze`:** `No issues found!` (0 issues) — ran in ~15.6s
- **Flutter:** run via `/root/flutter/bin/flutter` (root warning is benign in this env)

## Notes
- The pending UI redesign of `admin_recruiter_request_management.dart`
  (+712/−169, white theme + metric cards + search/filter, no logic changes)
  is committed as part of P0.
- No unit tests existed at baseline; `test/` is introduced during the RBAC and
  onboarding phases.
