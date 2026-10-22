# Habit Tracker (mobile) — product truth

## What it is

A Flutter app for building weekly habits on one phone. You create a habit with
a name and the weekdays it is due, check it off on the Today tab, and see your
current streak on the Stats tab. Everything is stored on the device in
`shared_preferences`; there are no accounts, no sync and no backend.

## Who it is for

A single person who wants a private, offline habit checklist without signing
up. It is also a portfolio sample of a small, fully tested Flutter app.

## What works today (verified by `flutter test`)

- Create a habit: name of 1–80 visible characters (emoji and combining marks
  count as one), at least one weekday.
- Today tab: check off a habit scheduled for today; tapping again undoes it.
  The day rolls over at local midnight while the app is open.
- All habits tab: schedules and total check-offs.
- Stats tab: current streak per habit. Rest days are skipped, and an
  unfinished habit today keeps yesterday's streak until the day has passed.
- Data survives an app restart. Unreadable saved data blocks writes and shows a
  retry action; a failed save keeps the previous state on screen.
- Crash reporting: when the build is given a Sentry DSN, unhandled errors are
  sent to Sentry with request, user, breadcrumbs and extra data removed. No
  tracing, no sessions, no screenshots.

## What does not exist

- No reminders or notifications, no editing or deleting a habit, no history
  calendar, no export, no cloud backup, no multi-device sync.
- No product analytics. Sentry errors are the only live signal
  ([KPI plan](docs/measurement/KPI-PLAN.md)).
- No device or emulator test evidence and no Maestro flow yet.

## Distribution and deploy state

- **Not released to any store.** There is no live URL.
- CI (`.github/workflows/ci.yml`) builds a **release-mode APK signed with the
  Android debug key** on every push to `main` and keeps it as a workflow
  artifact named `habit-tracker-apk-ci-NOT-FOR-STORE`. It is for testing on a
  device only. The Play Store would reject it; a store build needs a real
  upload keystore (owner action: create one and keep it in Infisical).
- The portfolio card "habit-tracker" on bookchaowalit.com describes the
  separate web app `bookchaowalit-website/productivity-habit-tracker-web`, not
  this mobile app.

## Evidence

- [TEST-EVIDENCE.md](TEST-EVIDENCE.md) — habit domain verification (BOO-213).
- [specs/001-shared-ci-sentry-release-apk/spec.md](specs/001-shared-ci-sentry-release-apk/spec.md) —
  shared CI, Sentry and the CI release APK.
