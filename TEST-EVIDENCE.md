# Habit domain verification — BOO-213

Verified locally on 15 October 2026 using Flutter 3.44.9 / Dart 3.12.2.
CI now pins the same SDK as Goal Tracker; no remote workflow was triggered.

## Automated checks

| Command | Local result |
|---|---|
| `flutter pub get` | Passed with committed lockfile |
| `dart format --output=none --set-exit-if-changed lib test` | Passed |
| `flutter analyze --no-pub` | Passed, no issues found |
| `flutter test --no-pub` | Passed, 15 tests |
| `rg -n 'workout\|Workout\|ExerciseSet\|muscleGroup' lib` | No matches |
| `flutter build apk --debug --no-pub` | Blocked: Android SDK is not installed |

No APK, emulator, Maestro, store-release or remote-CI success is claimed.
Resolve the implementation commit with `git log -1 --format=%H -- lib test`.

## Behavior covered

- Habit name validation, selected weekday schedules, JSON round trip, and
  reversible completion by local calendar date.
- Streaks skip rest days, allow today's unfinished habit to retain the previous
  streak, cross month boundaries, and ignore future completion dates.
- Create/check-off/reload persistence through the shared_preferences mock.
- Unreadable saved habits block writes and display a retry action.
- Rejected writes report an error, leave Today unchanged, and reload the
  preferences cache so failed data cannot appear after a retry.
- The widget journey creates a habit, checks it off, restarts the app, verifies
  persistence, and unchecks it.
- Today, All habits, Stats and the add form remain usable on a 320-pixel-wide
  phone at 130% text scale, with a long habit name.

Tests replace only the native preferences boundary with the package's in-memory
store (and a rejecting store for failure cases). Domain, storage service and
widgets run as implemented. The original fitness data key remains untouched;
it is intentionally not reinterpreted as habit data.

The test-first runs failed because the habit APIs did not exist. A later
regression test reproduced the preferences cache retaining a rejected write;
reloading after rejection fixed it. A mutation check also confirmed that
omitting the completion update fails the check-off test. All production code
was restored before final verification.
