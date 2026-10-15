import 'package:characters/characters.dart';

class Habit {
  static const maxNameLength = 80;

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter a habit name.';
    if (name.characters.length > maxNameLength) {
      return 'Use at most 80 characters.';
    }
    return null;
  }

  final String id;
  final String name;
  final Set<int> schedule;
  final Set<String> completions;

  Habit({
    required this.id,
    required String name,
    required Set<int> schedule,
    Set<String> completions = const {},
  })  : name = name.trim(),
        schedule = Set.unmodifiable(schedule),
        completions = Set.unmodifiable(completions) {
    if (id.isEmpty || validateName(this.name) != null) {
      throw ArgumentError('A habit needs an id and a name of 1–80 characters.');
    }
    if (schedule.isEmpty || schedule.any((day) => day < 1 || day > 7)) {
      throw ArgumentError('Choose at least one weekday (Monday=1, Sunday=7).');
    }
    for (final date in completions) {
      final parsed = DateTime.tryParse(date);
      if (parsed == null || dateKey(parsed) != date) {
        throw const FormatException('Invalid habit completion date.');
      }
    }
  }

  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool isScheduledOn(DateTime date) => schedule.contains(date.weekday);
  bool isCompletedOn(DateTime date) => completions.contains(dateKey(date));

  Habit toggleCompletion(DateTime date) {
    if (!isScheduledOn(date)) {
      throw ArgumentError('This habit is not scheduled for that day.');
    }
    final next = {...completions};
    final key = dateKey(date);
    if (!next.remove(key)) next.add(key);
    return Habit(id: id, name: name, schedule: schedule, completions: next);
  }

  int currentStreak(DateTime now) {
    var date = DateTime(now.year, now.month, now.day);
    // Today's unfinished habit does not end yesterday's streak until tomorrow.
    if (isScheduledOn(date) && !isCompletedOn(date)) {
      date = DateTime(date.year, date.month, date.day - 1);
    }
    var streak = 0;
    while (true) {
      if (isScheduledOn(date)) {
        if (!isCompletedOn(date)) break;
        streak++;
      }
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return streak;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'schedule': schedule.toList()..sort(),
        'completions': completions.toList()..sort(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        schedule: (json['schedule'] as List).cast<int>().toSet(),
        completions: (json['completions'] as List).cast<String>().toSet(),
      );
}
