---
title: "SPEC-001 — Shared CI, Sentry crash reports and a CI release APK"
status: implemented
tags: [spec, sdd, tdd, ci, sentry, security, mobile]
created: 2026-10-22
updated: 2026-10-22
description: "Move CI to the shared security scan, report crashes to Sentry without personal data, and keep a labelled release-mode APK from every main build."
---

# SPEC-001 — Shared CI, Sentry crash reports and a CI release APK

Standard: ADR-0004 (TDD + SDD). Plan: Big Loop Plan 2026-10-21, Tier B batch (b-tier-b).

## Document control

| Field | Value |
|---|---|
| Spec ID / version | SPEC-001 / 1.0 |
| Status | implemented |
| Repository | bookchaowalit-mobile/productivity-habit-tracker-mobile |
| Owner (maker) | Claude Code (b-tier-b session) |
| Approver | Owner (bookchaowalit) |

## 1. Problem and intent

- **Problem:** `build.yml` ran analyze and test and then built a **debug** APK that it threw away. There was no
  security scan, no crash reporting, no PRODUCT.md and no measurement plan.
- **Outcome:** CI checks format, analyze and tests on Flutter 3.44.9, runs the shared security scan, and on `main`
  builds a release-mode APK that is kept as an artifact with its SHA-256. Release builds report unhandled errors to
  Sentry with personal data removed.

## 2. Workflow mapping (`.github/workflows/build.yml` → `ci.yml`)

| Job | Before | After |
|---|---|---|
| validate | pub get, analyze, test (Flutter 3.44.9) | pub get `--enforce-lockfile`, `dart format` check, analyze, test |
| build | `flutter build apk --debug`, no artifact | `build-android-release`: `flutter build apk --release --dart-define=SENTRY_DSN=…`, renamed `habit-tracker-<sha>-ci-release-NOT-FOR-STORE.apk`, SHA-256 in the job summary, `actions/upload-artifact` (30 days) |
| security | — | shared `security.yml` v1.1.1 (`87dc5e1`): gitleaks, Semgrep, OSV-Scanner on `pubspec.lock`, Trivy |

Actions are pinned to commit SHAs.

## 3. Behaviour — scenarios

| AC | Given / When / Then | Test |
|---|---|---|
| AC-01 | Given no DSN at build time, Sentry stays off and the app starts normally | `test/sentry_setup_test.dart` (`sentryEnabled`, `runWithSentry … DSN is empty`) |
| AC-02 | Given a DSN, options are errors only: `sendDefaultPii` false, no tracing, no sessions, no breadcrumbs, no screenshots or view hierarchy | `test/sentry_setup_test.dart` (options) |
| AC-03 | Before sending, request, user, breadcrumbs and extra are removed; the message and exception stay | `test/sentry_setup_test.dart` (`scrubEvent`) |
| AC-04 | Existing habit behaviour is unchanged | 23 existing tests in `habit_test.dart`, `storage_service_test.dart`, `widget_test.dart` |
| AC-05 | A push to `main` produces a release-mode APK artifact with a SHA-256 | `build-android-release` job (run linked in §6) |

**Red first (local, Flutter 3.44.9 in a scratch SDK):** with only the signatures in place
(`lib/observability/sentry_setup.dart` returning defaults), `flutter test test/sentry_setup_test.dart` ended
`+1 -4: Some tests failed.` (`sentryEnabled('')` was true, `dsn` was null, `request` was kept, `appRunner` never ran).
After the implementation: `flutter analyze` no issues, `flutter test` **28 passed**, `dart format` clean.

## 4. Interfaces and data

| Area | Change |
|---|---|
| dependencies | `sentry_flutter` ^10.1.0 (adds `sentry` 10.1.0); lockfile updated |
| code | `lib/observability/sentry_setup.dart` (pure options + scrubber + `runWithSentry`); `lib/main.dart` runs the app through it |
| CI secret | `SENTRY_DSN` (GitHub Actions secret, set by the owner) is passed only to the release build |
| data | Habit names never leave the device. Sentry receives stack traces, device/OS and release only |

## 5. UI review

No screen, copy or layout changed. `main()` now wraps `runApp` and the widget tests (including the 320 px / 130 %
text-scale case) still pass. Flutter web is not a target of this repo, so no browser screenshots apply.
Device check of the CI APK is not done here (no emulator); owner action below.

## 6. Out of scope, deploy state and owner actions

- **Deploy state:** not released to any store; no live URL. The CI APK is signed with the Android debug key and is
  not a store build.
- **Owner actions:** (1) create an Android upload keystore and keep it in Infisical if a Play release is wanted, then
  switch `buildTypes.release` to it; (2) install the CI APK on a device once and confirm a test crash reaches Sentry.
- **Follow-ups:** Maestro smoke flow on the APK (roadmap htm-g3); product analytics waits for owner decision D4.
