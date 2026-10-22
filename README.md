# Habit Tracker Mobile (Book)

**Package / app identity:** Habit Tracker (Flutter)
**Repo:** `bookchaowalit-mobile/productivity-habit-tracker-mobile`
**Role:** Mobile release candidate (RC) — portfolio Flutter app, **not** a store-released product yet.

> **Identity note (BD-023):** Product identity is **Habit Tracker**. Nested
> FitPulse template residue (`fitpulse/`, Android `com.bookchaowalit.fitpulse`)
> was removed/renamed. Package id is `com.bookchaowalit.habittracker`.

## Purpose

Create habits with a name and selected weekdays, check them off on Today,
and see saved schedules and streaks. All data stays in local app preferences;
there are no accounts or backend services.

A streak counts consecutive scheduled days, skipping rest days. An unfinished
habit today keeps the previous streak until that scheduled day has passed.
Checking off a habit again reverses that day's completion. The All habits tab
shows schedules and total check-offs; Stats shows current streaks.

Habit data uses the new `habit_tracker_habits` preferences key. Data from the
previous fitness sample is left untouched under its old key and is not
reinterpreted as habits. Unreadable habit data blocks writes and displays a
retry action; a failed save keeps the previously displayed state.

## Stack

- Flutter 3.44.9 / Dart 3.12.2 (same pin as Goal Tracker)
- Tests under `test/`
- CI: `.github/workflows/ci.yml` (format/analyze/test, shared security scan, release APK artifact on `main`)
- Crash reporting: Sentry, only when built with `--dart-define=SENTRY_DSN=...`
- Product truth: [PRODUCT.md](PRODUCT.md)

## Run

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

## Quality gates

| Gate | Command / artifact |
|---|---|
| Analyze | `flutter analyze` (must pass in CI) |
| Unit tests | `flutter test` |
| Release audit | Solo Empire `mobile_release_gate.py audit` |
| Store release | **Not claimed** until gate + signing complete |

## Related RCs

- clipboard-manager-mobile (Expo)
- goal-tracker-mobile
- invoice-generator-mobile
- portfolio-mobile

## Local verification

See [TEST-EVIDENCE.md](TEST-EVIDENCE.md) for the current commands, source
identity and platform limitations. Unit and widget tests cover habit creation,
weekday schedules, check-off/restart persistence, streak calculations and
unreadable data. Android APK and device verification are separate gates.
