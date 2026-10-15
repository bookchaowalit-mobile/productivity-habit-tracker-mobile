import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/services/storage_service.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'support/failing_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('failed writes do not leave phantom habits in preferences cache',
      () async {
    SharedPreferencesStorePlatform.instance = FailingPreferences();
    final habit = Habit(id: 'read', name: 'Read', schedule: {4});
    await expectLater(StorageService.saveHabits([habit]), throwsStateError);
    expect(await StorageService.getHabits(), isEmpty);
  });

  test('habit create and check-off survive a preferences round trip', () async {
    final habit = Habit(id: 'read', name: 'Read', schedule: {4});
    await StorageService.saveHabits([habit]);
    final loaded = await StorageService.getHabits();
    await StorageService.saveHabits(
        [loaded.single.toggleCompletion(DateTime(2026, 10, 15))]);
    final reloaded = await StorageService.getHabits();
    expect(reloaded.single.name, 'Read');
    expect(reloaded.single.isCompletedOn(DateTime(2026, 10, 15)), isTrue);
  });

  test('unreadable saved habits throw without replacing the original value',
      () async {
    SharedPreferences.setMockInitialValues({'habit_tracker_habits': '{broken'});
    await expectLater(StorageService.getHabits(), throwsFormatException);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('habit_tracker_habits'), '{broken');
  });

  test('legacy fitness data is left untouched and not interpreted as habits',
      () async {
    SharedPreferences.setMockInitialValues(
        {'habit_tracker_workouts': '[{"name":"old"}]'});
    expect(await StorageService.getHabits(), isEmpty);
    await StorageService.saveHabits([
      Habit(id: 'read', name: 'Read', schedule: {4})
    ]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('habit_tracker_workouts'), '[{"name":"old"}]');
  });
}
