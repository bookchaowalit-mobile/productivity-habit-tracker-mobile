import 'package:flutter/material.dart';
import '../models/workout.dart';

class StatsScreen extends StatelessWidget {
  final WeeklyStats stats;
  final List<Workout> workouts;
  const StatsScreen({super.key, required this.stats, required this.workouts});

  static const _muscleColors = {
    'Chest': Color(0xFFFF6B6B), 'Back': Color(0xFF4ECDC4), 'Legs': Color(0xFFFFE66D),
    'Arms': Color(0xFFA8E6CF), 'Shoulders': Color(0xFFFF8B94), 'Core': Color(0xFFB8A9C9),
    'Full Body': Color(0xFF00D4AA), 'Cardio': Color(0xFFFF9F43),
  };

  @override
  Widget build(BuildContext context) {
    final maxMg = stats.muscleGroupDistribution.values.fold(0, (a, b) => a > b ? a : b);

    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('Stats'), pinned: true, backgroundColor: Color(0xFF0D1117)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            // Overview cards
            Row(children: [
              _bigStat('${stats.workoutsThisWeek}', 'This Week', const Color(0xFF00D4AA)),
              const SizedBox(width: 12),
              _bigStat('${stats.streak}', 'Day Streak', const Color(0xFFFF6B6B)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _bigStat('${stats.totalVolume}', 'Volume (kg)', const Color(0xFF4ECDC4)),
              const SizedBox(width: 12),
              _bigStat('${stats.totalMinutes}', 'Minutes', const Color(0xFFFFE66D)),
            ]),
            const SizedBox(height: 24),
            // Muscle group distribution
            const Text('Muscle Group Distribution', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                ...stats.muscleGroupDistribution.entries.map((e) {
                  final pct = maxMg > 0 ? (e.value / maxMg) * 100 : 0.0;
                  final color = _muscleColors[e.key] ?? const Color(0xFF00D4AA);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      SizedBox(width: 80, child: Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 14))),
                      Expanded(child: Container(
                        height: 8,
                        decoration: BoxDecoration(color: const Color(0xFF0D1117), borderRadius: BorderRadius.circular(4)),
                        child: FractionallySizedBox(widthFactor: pct / 100, child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
                      )),
                      const SizedBox(width: 12),
                      Text('${e.value}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                    ]),
                  );
                }),
                if (stats.muscleGroupDistribution.isEmpty)
                  const Padding(padding: EdgeInsets.all(20), child: Text('No data yet', style: TextStyle(color: Color(0xFF484F58)))),
              ]),
            ),
            const SizedBox(height: 24),
            // All-time stats
            const Text('All-Time', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _statRow('Total Workouts', '${workouts.length}'),
                _statRow('Total Volume', '${workouts.fold(0, (s, w) => s + w.totalVolume)} kg'),
                _statRow('Total Time', '${workouts.fold(0, (s, w) => s + w.durationSeconds) ~/ 60} min'),
                _statRow('Total Sets', '${workouts.fold(0, (s, w) => s + w.totalSets)}'),
                if (workouts.isNotEmpty) ...[
                  _statRow('Avg Duration', '${workouts.fold(0, (s, w) => s + w.durationSeconds) ~/ workouts.length ~/ 60} min'),
                  _statRow('Avg Volume', '${workouts.fold(0, (s, w) => s + w.totalVolume) ~/ workouts.length} kg'),
                ],
              ]),
            ),
            const SizedBox(height: 40),
          ])),
        ),
      ],
    );
  }

  Widget _bigStat(String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF484F58), fontSize: 14)),
      ]),
    ));
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 15)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
