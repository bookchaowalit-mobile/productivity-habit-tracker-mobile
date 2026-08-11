import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout.dart';

class StorageService {
  static const String workoutsKey = 'habit_tracker_workouts';
  static const String goalsKey = 'habit_tracker_goals';

  static Future<List<Workout>> getWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(workoutsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((w) => Workout.fromJson(w as Map<String, dynamic>)).toList();
  }

  static Future<void> saveWorkouts(List<Workout> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(workoutsKey, jsonEncode(workouts.map((w) => w.toJson()).toList()));
  }

  static Future<void> addWorkout(Workout workout) async {
    final workouts = await getWorkouts();
    workouts.insert(0, workout);
    await saveWorkouts(workouts);
  }

  static Future<void> deleteWorkout(String id) async {
    final workouts = await getWorkouts();
    workouts.removeWhere((w) => w.id == id);
    await saveWorkouts(workouts);
  }

  static WeeklyStats computeStats(List<Workout> workouts) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final thisWeek = workouts.where((w) => w.date.isAfter(weekAgo)).toList();

    final muscleGroups = <String, int>{};
    for (final w in workouts) {
      muscleGroups[w.muscleGroup] = (muscleGroups[w.muscleGroup] ?? 0) + 1;
    }

    int streak = 0;
    var checkDate = DateTime(now.year, now.month, now.day);
    while (true) {
      final hasWorkout = workouts.any((w) =>
        w.date.year == checkDate.year && w.date.month == checkDate.month && w.date.day == checkDate.day);
      if (hasWorkout) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return WeeklyStats(
      workoutsThisWeek: thisWeek.length,
      totalVolume: thisWeek.fold(0, (sum, w) => sum + w.totalVolume),
      totalMinutes: thisWeek.fold(0, (sum, w) => sum + (w.durationSeconds ~/ 60)),
      streak: streak,
      muscleGroupDistribution: muscleGroups,
    );
  }
}
