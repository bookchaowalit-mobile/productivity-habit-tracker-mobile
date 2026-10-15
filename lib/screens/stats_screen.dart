import 'package:flutter/material.dart';
import '../models/habit.dart';

class StatsScreen extends StatelessWidget {
  final List<Habit> habits;
  final DateTime today;
  const StatsScreen({super.key, required this.habits, required this.today});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          ListTile(
              title: const Text('Habits'), trailing: Text('${habits.length}')),
          ListTile(
              title: const Text('Total check-offs'),
              trailing: Text(
                  '${habits.fold<int>(0, (total, habit) => total + habit.completions.length)}')),
          const Divider(),
          ...habits.map((habit) => ListTile(
                title: Text(habit.name),
                subtitle: Text('${habit.currentStreak(today)} day streak'),
              )),
        ],
      );
}
