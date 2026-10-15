import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class StorageService {
  static const habitsKey = 'habit_tracker_habits';

  static Future<List<Habit>> getHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(habitsKey);
    if (saved == null) return [];
    try {
      final entries = jsonDecode(saved) as List;
      return entries
          .map((entry) => Habit.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const FormatException(
          'Saved habits could not be read. Your data has not been changed.');
    }
  }

  static Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = await prefs.setString(habitsKey,
          jsonEncode(habits.map((habit) => habit.toJson()).toList()));
      if (!saved) throw StateError('Habits could not be saved.');
    } catch (_) {
      // The plugin updates its cache before the native write succeeds.
      try {
        await prefs.reload();
      } catch (_) {
        // Preserve the original write error when disk reads also fail.
      }
      rethrow;
    }
  }
}
