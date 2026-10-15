import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/main.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'support/failing_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
