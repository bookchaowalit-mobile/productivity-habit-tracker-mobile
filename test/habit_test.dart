import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/models/habit.dart';

void main() {
  final thursday = DateTime(2026, 10, 15);
  test('habit schedule selects weekdays and normalizes the name', () {
    final habit = Habit(id: 'read', name: ' Read ', schedule: {1, 4});
    expect(habit.name, 'Read');
    expect(habit.isScheduledOn(thursday), isTrue);
    expect(habit.isScheduledOn(DateTime(2026, 10, 16)), isFalse);
  });

  test('invalid names and empty or invalid schedules are rejected', () {
    expect(() => Habit(id: 'a', name: ' ', schedule: {1}), throwsArgumentError);
    expect(
        () => Habit(id: 'a', name: 'Read', schedule: {}), throwsArgumentError);
    expect(
        () => Habit(id: 'a', name: 'Read', schedule: {8}), throwsArgumentError);
  });

  test('check-off is a reversible calendar-date operation', () {
    final habit = Habit(id: 'read', name: 'Read', schedule: {4});
    final checked = habit.toggleCompletion(DateTime(2026, 10, 15, 23));
    expect(habit.isCompletedOn(thursday), isFalse);
    expect(checked.isCompletedOn(thursday), isTrue);
    expect(checked.completions, {'2026-10-15'});
    expect(checked.toggleCompletion(thursday).completions, isEmpty);
  });

  test(
      'streak skips unscheduled days and includes yesterday before today is done',
      () {
    final habit = Habit(
        id: 'read',
        name: 'Read',
        schedule: {1, 3, 5},
        completions: {'2026-10-09', '2026-10-12', '2026-10-14'});
    expect(habit.currentStreak(thursday), 3);
    expect(habit.currentStreak(DateTime(2026, 10, 16)), 3);
    expect(habit.currentStreak(DateTime(2026, 10, 17)), 0);
  });

  test('streak crosses month boundaries and ignores future completions', () {
    final habit = Habit(
        id: 'read',
        name: 'Read',
        schedule: {1, 2, 3, 4, 5, 6, 7},
        completions: {'2026-09-29', '2026-09-30', '2026-10-01', '2026-10-03'});
    expect(habit.currentStreak(DateTime(2026, 10, 1)), 3);
    expect(habit.currentStreak(DateTime(2026, 10, 2)), 3);
    expect(habit.currentStreak(DateTime(2026, 10, 4)), 1);
  });

  test('JSON round trip preserves schedule and completions', () {
    final habit = Habit(
        id: 'read',
        name: 'Read',
        schedule: {1, 4},
        completions: {'2026-10-15'});
    final restored = Habit.fromJson(habit.toJson());
    expect(restored.toJson(), {
      'id': 'read',
      'name': 'Read',
      'schedule': [1, 4],
      'completions': ['2026-10-15'],
    });
  });
}
