# Release signing (Android upload key)

Created 2026-10-24 (session oa-remainder, owner instruction). The keystore and its passwords
exist **only** in Infisical; nothing is in Git.

| Item | Value |
|---|---|
| Application id | `com.bookchaowalit.habittracker` |
| Keystore type / key | PKCS12, RSA 4096, alias `upload`, valid 9125 days (25 years) |
| Certificate SHA-256 | `1C:BA:3E:CE:9B:3D:0A:AA:A6:7A:36:3D:02:09:51:B0:46:46:6A:BD:1D:93:48:BE:DF:A9:E7:7A:FC:53:FC:7E` |
| Infisical folder | `/android` |
| Keystore (base64) | `ANDROID_HABIT_TRACKER_UPLOAD_KEYSTORE_B64` |
| Store password | `ANDROID_HABIT_TRACKER_UPLOAD_STORE_PASSWORD` |
| Key password | `ANDROID_HABIT_TRACKER_UPLOAD_KEY_PASSWORD` (same value as the store password, as PKCS12 requires) |
| Alias | `ANDROID_HABIT_TRACKER_UPLOAD_KEY_ALIAS` (`upload`) |

This is the **upload** key. With Play App Signing, Google holds the app signing key; register
this certificate as the upload certificate when the app is created in Play Console (an owner
step: it needs the Play developer account). If the upload key is lost or leaks, ask Play
support to reset the upload key; do not reuse it for another app.

## Gradle

**Not wired yet:** `android/app/build.gradle.kts` still signs `release` with the debug key (Flutter template). Before using this key, change it to read `android/key.properties` and fail closed without it, as `productivity-goal-tracker-mobile` does. Until then no release build uses the upload key.

## Build a signed bundle locally

Write the files outside the repository and never print the values:

```bash
source ~/.config/solo-empire/environment.sh
mkdir -p ~/.android-upload && chmod 700 ~/.android-upload
infisical run --projectId "$INFISICAL_PROJECT_ID" --env dev --path /android --silent -- bash -c '
  umask 077
  printf %s "$ANDROID_HABIT_TRACKER_UPLOAD_KEYSTORE_B64" | base64 -d > ~/.android-upload/habit_tracker.jks
  printf "storeFile=%s\nstorePassword=%s\nkeyPassword=%s\nkeyAlias=%s\n" \
    ~/.android-upload/habit_tracker.jks "$ANDROID_HABIT_TRACKER_UPLOAD_STORE_PASSWORD" \
    "$ANDROID_HABIT_TRACKER_UPLOAD_KEY_PASSWORD" "$ANDROID_HABIT_TRACKER_UPLOAD_KEY_ALIAS" > android/key.properties'
flutter build appbundle --release
```

`android/key.properties`, `*.jks` and `*.keystore` are git-ignored. CI still builds an unsigned
bundle: wiring these secrets into CI is a separate change.
