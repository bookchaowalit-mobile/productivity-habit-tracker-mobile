# Habit Tracker Mobile (Book)

**Package / app identity:** Habit Tracker (Flutter)  
**Repo:** `bookchaowalit-mobile/bookchaowalit-habit-tracker-mobile`  
**Role:** Mobile release candidate (RC) — portfolio Flutter app, **not** a store-released product yet.

> **Identity note (BD-023):** Product identity is **Habit Tracker**. Nested
> FitPulse template residue (`fitpulse/`, Android `com.bookchaowalit.fitpulse`)
> was removed/renamed. Package id is `com.bookchaowalit.habittracker`.

## Purpose

Track daily habits offline-first on mobile. Intended as a Flutter portfolio
showcase with real local state — not a fitness SaaS.

## Stack

- Flutter (see `pubspec.yaml` / `pubspec.lock`)
- Tests under `test/`
- CI: `.github/workflows/build.yml` (fail-closed analyze/test for RC)

## Run

```bash
flutter pub get
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
