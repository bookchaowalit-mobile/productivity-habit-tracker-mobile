class Workout {
  final String id;
  final String name;
  final String muscleGroup;
  final List<ExerciseSet> sets;
  final DateTime date;
  final int durationSeconds;
  final String notes;

  Workout({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.date,
    required this.durationSeconds,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'muscleGroup': muscleGroup,
    'sets': sets.map((s) => s.toJson()).toList(),
    'date': date.toIso8601String(), 'durationSeconds': durationSeconds, 'notes': notes,
  };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'], name: json['name'], muscleGroup: json['muscleGroup'],
    sets: (json['sets'] as List).map((s) => ExerciseSet.fromJson(s)).toList(),
    date: DateTime.parse(json['date']), durationSeconds: json['durationSeconds'],
    notes: json['notes'] ?? '',
  );

  int get totalVolume => sets.fold(0, (sum, s) => sum + (s.weight * s.reps));
  int get totalSets => sets.length;
}

class ExerciseSet {
  final int weight;
  final int reps;
  final bool completed;

  ExerciseSet({required this.weight, required this.reps, this.completed = false});

  Map<String, dynamic> toJson() => {'weight': weight, 'reps': reps, 'completed': completed};
  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
    weight: json['weight'], reps: json['reps'], completed: json['completed'] ?? false,
  );
}

class WorkoutTemplate {
  final String name;
  final String muscleGroup;
  final String icon;
  final List<String> exercises;

  WorkoutTemplate({required this.name, required this.muscleGroup, required this.icon, required this.exercises});
}

class WeeklyStats {
  final int workoutsThisWeek;
  final int totalVolume;
  final int totalMinutes;
  final int streak;
  final Map<String, int> muscleGroupDistribution;

  WeeklyStats({
    required this.workoutsThisWeek,
    required this.totalVolume,
    required this.totalMinutes,
    required this.streak,
    required this.muscleGroupDistribution,
  });
}
