# Maha Services — Refactor Smoke-Test Checklist

Run scoped subsets per increment; run the full list at each phase boundary.

Build gate for every increment:
```
flutter analyze      # issue count must be <= baseline (docs/refactor/baseline.md)
flutter build web    # must succeed
```
Then serve and test in Chrome.

## 1. Public
- [ ] `/` splash renders (hero, features, footer, floating CTAs)
- [ ] Header nav: Home, Find Jobs, For Recruiters all navigate
- [ ] `/pricing` renders
- [ ] Deep-link refresh on `/pricing` works (PathUrlStrategy)

## 2. Signup
- [ ] "Join as Candidate" → candidate signup copy, no role toggle
- [ ] "I'm a Recruiter" → recruiter signup copy
- [ ] Direct `/register` → defaults to candidate
- [ ] Candidate signup → onboarding (post-E6) → profile builder → dashboard
- [ ] Recruiter signup → recruiter dashboard

## 3. Job Seeker
- [ ] Login → dashboard renders with data
- [ ] Job hub search + filter chips
- [ ] Open job detail; apply; appears in applications tracker
- [ ] Save / unsave a job
- [ ] Edit a profile section; completeness % updates
- [ ] Settings screen (job alerts toggle, change password)
- [ ] ATS/CV tools page loads
- [ ] Logout

## 4. Recruiter
- [ ] Login → dashboard KPIs + charts
- [ ] Post a job (quill editor works; job appears in listings)
- [ ] List of applicants for a job
- [ ] Shortlist a candidate; view shortlisted
- [ ] AI matching page loads
- [ ] Archive job → appears in archived
- [ ] Request box submit (candidate handover to admin)
- [ ] Logout

## 5. Recruitment Agent (post-B5)
- [ ] Same capabilities as recruiter (dashboard, post job, applicants)

## 6. Admin
- [ ] `/admin` login (rejects non-admin)
- [ ] Analytics dashboard counts sane vs Firebase console
- [ ] User management: list, search, paginate
- [ ] Convert role (Candidate ↔ Recruiter ↔ Recruitment Agent)
- [ ] Suspend / activate / soft-delete / restore user
- [ ] Recruiter requests: approve + reject
- [ ] Audit logs section (post-C5): filters + pagination
- [ ] Questionnaire management (post-E8): list/edit/add/seed
- [ ] Logout

## 7. Auth edges
- [ ] Forgot-password email flow
- [ ] Wrong-password error state
- [ ] Guarded-route deep link while logged out → `/login`
- [ ] Refresh while logged in on `/recruiter-dashboard` stays put
- [ ] Suspended/deleted user auto-signed-out
- [ ] Router debug logs (`🔀 Router Check`) settle — no redirect ping-pong
