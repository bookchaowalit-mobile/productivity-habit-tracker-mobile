import 'package:flutter/material.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'support/failing_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an old checkbox callback records the action date after midnight',
      (tester) async {
    var now = DateTime(2026, 10, 15, 23, 59, 58);
    await StorageService.saveHabits([
      Habit(id: 'read', name: 'Read', schedule: {4, 5})
    ]);
    await withClock(Clock(() => now), () async {
      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();
      final oldCallback = tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile))
          .onChanged!;
      now = DateTime(2026, 10, 16, 0, 0, 1);
      // No timer/frame has run: this is the callback from yesterday's build.
      oldCallback(true);
      await tester.pumpAndSettle();
      expect((await StorageService.getHabits()).single.completions,
          {'2026-10-16'});
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('yesterday callback cannot check off an unscheduled new day',
      (tester) async {
    var now = DateTime(2026, 10, 15, 23, 59, 58);
    await StorageService.saveHabits([
      Habit(id: 'read', name: 'Read', schedule: {4})
    ]);
    await withClock(Clock(() => now), () async {
      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();
      final oldCallback = tester
          .widget<CheckboxListTile>(find.byType(CheckboxListTile))
          .onChanged!;
      now = DateTime(2026, 10, 16, 0, 0, 1);
      oldCallback(true);
      await tester.pumpAndSettle();
      expect((await StorageService.getHabits()).single.completions, isEmpty);
      expect(find.text('No habits scheduled today.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets('foreground Today refreshes at the local midnight boundary',
      (tester) async {
    var now = DateTime(2026, 10, 15, 23, 59, 58);
    await StorageService.saveHabits([
      Habit(
          id: 'read',
          name: 'Read',
          schedule: {4, 5},
          completions: {'2026-10-15'}),
      Habit(id: 'walk', name: 'Friday walk', schedule: {5}),
    ]);
    await withClock(Clock(() => now), () async {
      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();
      expect(find.text('Friday walk'), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      now = DateTime(2026, 10, 16, 0, 0, 1);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Friday walk'), findsOneWidget);
      expect(find.text('0 of 2 completed today'), findsOneWidget);
      expect(
          tester
              .widgetList<Checkbox>(find.byType(Checkbox))
              .every((box) => box.value == false),
          isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  for (final (label, name) in [
    ('emoji', List.filled(41, '😀').join()),
    ('combining marks', List.filled(80, 'e\u0301').join())
  ]) {
    testWidgets('the form saves $label names', (tester) async {
      await tester.pumpWidget(const HabitTrackerApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add habit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), name);
      await tester.tap(find.text('Save habit'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect((await StorageService.getHabits()).single.name, name);
    });
  }

  testWidgets('small phone with large text keeps all habit tabs usable',
      (tester) async {
    tester.view.physicalSize = const Size(960, 1920);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await StorageService.saveHabits([
      Habit(
          id: 'read',
          name: 'Read ten pages and write a brief daily reflection',
          schedule: {1, 2, 3, 4, 5, 6, 7}),
    ]);
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('All habits'));
    await tester.pumpAndSettle();
    expect(find.text('Mon, Tue, Wed, Thu, Fri, Sat, Sun'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text('Total check-offs'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Add habit'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilterChip, 'Sun'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed saves report an error and leave today unchanged',
      (tester) async {
    SharedPreferencesStorePlatform.instance = FailingPreferences();
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add habit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Read');
    await tester.tap(find.text('Save habit'));
    await tester.pumpAndSettle();
    expect(find.text('Read'), findsNothing);
    expect(find.text('No habits scheduled today.'), findsOneWidget);
    expect(find.text('Habits could not be saved. Please try again.'),
        findsOneWidget);
  });

  testWidgets('create, check off, restart and uncheck a habit', (tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    expect(find.text('No habits scheduled today.'), findsOneWidget);
    await tester.tap(find.byTooltip('Add habit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Read ten pages');
    await tester.tap(find.text('Save habit'));
    await tester.pumpAndSettle();
    expect(find.text('Read ten pages'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    expect(find.text('Read ten pages'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
  });

  testWidgets('add habit validates name and weekday selection', (tester) async {
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add habit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save habit'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a habit name.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Read');
    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      await tester.tap(find.widgetWithText(FilterChip, day));
    }
    await tester.tap(find.text('Save habit'));
    await tester.pumpAndSettle();
    expect(find.text('Choose at least one day.'), findsOneWidget);
  });

  testWidgets('unreadable habits show an error and prevent new writes',
      (tester) async {
    SharedPreferences.setMockInitialValues({'habit_tracker_habits': '{broken'});
    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Saved habits could not be read'), findsOneWidget);
    expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull);
    expect(
        (await SharedPreferences.getInstance())
            .getString('habit_tracker_habits'),
        '{broken');
  });
}
