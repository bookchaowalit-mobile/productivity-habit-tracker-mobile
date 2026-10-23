import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/observability/sentry_setup.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('sentryEnabled', () {
    test('is off when no DSN was passed at build time', () {
      expect(sentryEnabled(''), isFalse);
      expect(sentryEnabled('   '), isFalse);
    });

    test('is on when a DSN is present', () {
      expect(sentryEnabled('https://key@o0.ingest.sentry.io/1'), isTrue);
    });
  });

  test('options report errors only and never send default PII', () {
    final options = SentryFlutterOptions();
    configureSentryOptions(options, 'https://key@o0.ingest.sentry.io/1');

    expect(options.dsn, 'https://key@o0.ingest.sentry.io/1');
    expect(options.sendDefaultPii, isFalse);
    expect(options.tracesSampleRate, isNull);
    expect(options.tracesSampler, isNull);
    expect(options.maxBreadcrumbs, 0);
    expect(options.enableAutoSessionTracking, isFalse);
    expect(options.attachScreenshot, isFalse);
    // ignore: experimental_member_use
    expect(options.attachViewHierarchy, isFalse);
    expect(options.beforeSend, isNotNull);
  });

  test(
      'scrubEvent strips request, user, breadcrumbs and extra but keeps the error',
      () {
    final event = SentryEvent(
      message: SentryMessage('Habit save failed'),
      exceptions: [SentryException(type: 'StateError', value: 'boom')],
      request: SentryRequest(url: 'https://example.com/?habit=Read'),
      user: SentryUser(id: 'u1', email: 'someone@example.com'),
      breadcrumbs: [Breadcrumb(message: 'typed habit name: Read')],
      // ignore: deprecated_member_use
      extra: {'habitName': 'Read'},
    );

    final scrubbed = scrubEvent(event);

    expect(scrubbed.request, isNull);
    expect(scrubbed.user, isNull);
    expect(scrubbed.breadcrumbs, anyOf(isNull, isEmpty));
    // ignore: deprecated_member_use
    expect(scrubbed.extra, anyOf(isNull, isEmpty));
    expect(scrubbed.message?.formatted, 'Habit save failed');
    expect(scrubbed.exceptions?.single.type, 'StateError');
  });

  test('runWithSentry runs the app directly when the DSN is empty', () async {
    var ran = false;
    await runWithSentry(() async => ran = true, dsn: '');
    expect(ran, isTrue);
    expect(Sentry.isEnabled, isFalse);
  });
}
