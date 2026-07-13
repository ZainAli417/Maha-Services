# Firestore Migration Plan

All schema changes are **additive and backward-compatible** — no existing
document is rewritten by a migration, and every new field is optional/nullable.

## New / changed collections & fields

### `users/{uid}` (existing) — new optional fields
| Field | Type | Written by | Purpose |
|---|---|---|---|
| `rawRole` | — | (not stored) | Parsed at runtime only; no write |
| `role_updated_at` | timestamp | admin role conversion | audit/UX |
| `deleted_at` | timestamp | admin soft delete | restore support |
| `deleted_by` | string (uid) | admin soft delete | audit |
| `email_verified` | bool | admin verification | verification workflow |
| `documents_verified` | bool | admin verification | verification workflow |
| `onboarding` | map `{roleId, answers, stepIndex, completed, updatedAt}` | onboarding wizard (self) | resume + captured answers |
| `onboarding_completed` | bool | onboarding wizard (self) | completion flag |
| `account_status` | now also `'deleted'` | admin | soft-delete state (was active/suspended) |
| `role` | now also `'Recruitment Agent'` / `'superadmin'` | admin | new RBAC roles |

Existing role strings (`Job Seeker`, `recruiter`, `admin`, …) are unchanged —
`UserRole.fromFirestore` parses every historical alias, so **no backfill is
required**.

### `audit_logs/{autoId}` (new)
`{ actorUid, actorEmail, action, targetType, targetId, targetLabel, details, timestamp }`
Append-only (rules forbid update/delete).

### `questionnaire_config/active` (new)
`{ roles: [ AviationRole… ], seedVersion, updatedAt }` — single document holding
the full onboarding catalogue (well under the 1 MB doc limit). Absent until an
admin seeds; the app falls back to the built-in `AviationCatalogue` so
onboarding works before seeding.

## Deploy order (maintainer)
1. **Indexes** first: `firebase deploy --only firestore:indexes`
   (adds the `audit_logs (action ASC, timestamp DESC)` composite index).
2. **Rules**: `firebase deploy --only firestore:rules`
   (additive — new `audit_logs` / `questionnaire_config` matchers, expanded
   `isRecruiter`/`isAdmin`, `isSuperAdmin`, hardened `userImmutableFieldsUnchanged`).
3. **App**: build & deploy web.
4. **Seed questionnaire**: sign in as admin → Questionnaires → *Seed defaults*
   (writes `questionnaire_config/active`; thereafter fully editable in-app).

## Rollback
- Rules/indexes: redeploy the previous `firestore.rules` / `firestore.indexes.json`.
- App: all new fields are ignored by the old build, so an app rollback is safe.
- No destructive migration exists to reverse.
