// Crash reporting for release builds. Errors only: no tracing, no sessions,
// no screenshots, and nothing that can carry what the user typed (request,
// user, breadcrumbs, extra). Habit names never leave the device.
import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

/// Set at build time with `--dart-define=SENTRY_DSN=...` (CI release build
/// only). Empty in local, test and debug builds, which keeps Sentry off.
const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

bool sentryEnabled(String dsn) => dsn.trim().isNotEmpty;

void configureSentryOptions(SentryFlutterOptions options, String dsn) {
  options
    ..dsn = dsn.trim()
    ..sendDefaultPii = false
    ..tracesSampleRate = null
    ..tracesSampler = null
    ..maxBreadcrumbs = 0
    ..enableAutoSessionTracking = false
    // View hierarchy capture is off by default (experimental in 9.x).
    ..attachScreenshot = false
    ..beforeSend = scrubEvent;
}

SentryEvent scrubEvent(SentryEvent event, [Hint? hint]) {
  event
    ..request = null
    ..user = null
    ..breadcrumbs = null
    // ignore: deprecated_member_use
    ..extra = null;
  return event;
}

/// Runs [appRunner] inside Sentry when [dsn] is set, otherwise runs it as is.
Future<void> runWithSentry(FutureOr<void> Function() appRunner,
    {String dsn = sentryDsn}) async {
  if (!sentryEnabled(dsn)) {
    await appRunner();
    return;
  }
  await SentryFlutter.init(
    (options) => configureSentryOptions(options, dsn),
    appRunner: appRunner,
  );
}
