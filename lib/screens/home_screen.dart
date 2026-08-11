import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/storage_service.dart';
import 'add_workout_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Workout> _workouts = [];
  WeeklyStats? _stats;
  bool _loading = true;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final workouts = await StorageService.getWorkouts();
    final stats = StorageService.computeStats(workouts);
    setState(() { _workouts = workouts; _stats = stats; _loading = false; });
  }

  static const _muscleColors = {
    'Chest': Color(0xFFFF6B6B), 'Back': Color(0xFF4ECDC4), 'Legs': Color(0xFFFFE66D),
    'Arms': Color(0xFFA8E6CF), 'Shoulders': Color(0xFFFF8B94), 'Core': Color(0xFFB8A9C9),
    'Full Body': Color(0xFF00D4AA), 'Cardio': Color(0xFFFF9F43),
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))));

    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [_buildHome(), _buildHistory(), _stats != null ? StatsScreen(stats: _stats!, workouts: _workouts) : const SizedBox()],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Color(0xFF161B22), border: Border(top: BorderSide(color: Color(0xFF21262D)))),
        child: SafeArea(
          child: Row(
            children: [
              _navItem(0, Icons.fitness_center, 'Home'),
              _navItem(1, Icons.history, 'History'),
              _navItem(2, Icons.bar_chart, 'Stats'),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddWorkoutScreen())); _loadData(); },
        backgroundColor: const Color(0xFF00D4AA),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _currentTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: active ? const Color(0xFF00D4AA) : const Color(0xFF484F58), size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: active ? const Color(0xFF00D4AA) : const Color(0xFF484F58), fontSize: 12, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ]),
        ),
      ),
    );
  }

  Widget _buildHome() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            title: const Text('Habit Tracker', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            background: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xFF00D4AA), Color(0xFF0D1117)],
              )),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            if (_stats != null) ...[
              Row(children: [
                _statCard('${_stats!.workoutsThisWeek}', 'Workouts', Icons.fitness_center),
                const SizedBox(width: 12),
                _statCard('${_stats!.streak}', 'Day Streak', Icons.local_fire_department),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _statCard('${_stats!.totalVolume}', 'Volume (kg)', Icons.speed),
                const SizedBox(width: 12),
                _statCard('${_stats!.totalMinutes}', 'Minutes', Icons.timer),
              ]),
              const SizedBox(height: 24),
              const Text('Quick Start', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _quickStartGrid(),
              const SizedBox(height: 24),
              const Text('Recent Workouts', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...(_workouts.take(5).map((w) => _workoutCard(w))),
              if (_workouts.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No workouts yet.\nTap + to log your first workout!', style: TextStyle(color: Color(0xFF484F58), fontSize: 16), textAlign: TextAlign.center))),
            ],
          ])),
        ),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF00D4AA), size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Color(0xFF484F58), fontSize: 12)),
      ]),
    ));
  }

  Widget _quickStartGrid() {
    final templates = [
      ('Chest', Icons.fitness_center, _muscleColors['Chest']!),
      ('Back', Icons.accessibility_new, _muscleColors['Back']!),
      ('Legs', Icons.directions_run, _muscleColors['Legs']!),
      ('Arms', Icons.accessibility, _muscleColors['Arms']!),
      ('Shoulders', Icons.fitness_center, _muscleColors['Shoulders']!),
      ('Core', Icons.self_improvement, _muscleColors['Core']!),
    ];
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 1,
      children: templates.map((t) => GestureDetector(
        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => AddWorkoutScreen(presetGroup: t.$1))); _loadData(); },
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16), border: Border.all(color: t.$3.withValues(alpha: 0.3))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(t.$2, color: t.$3, size: 32),
            const SizedBox(height: 8),
            Text(t.$1, style: const TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        ),
      )).toList(),
    );
  }

  Widget _workoutCard(Workout w) {
    final color = _muscleColors[w.muscleGroup] ?? const Color(0xFF00D4AA);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 4, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(w.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('${w.muscleGroup} • ${w.totalSets} sets • ${w.durationSeconds ~/ 60} min', style: const TextStyle(color: Color(0xFF484F58), fontSize: 13)),
        ])),
        Text(_formatDate(w.date), style: const TextStyle(color: Color(0xFF484F58), fontSize: 12)),
      ]),
    );
  }

  Widget _buildHistory() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(title: Text('History'), pinned: true, backgroundColor: Color(0xFF0D1117)),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(delegate: SliverChildListDelegate([
            if (_workouts.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(60), child: Text('No workout history', style: TextStyle(color: Color(0xFF484F58)))))
            else
              ...(_workouts.map((w) => _workoutCard(w))),
          ])),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    if (d.year == now.year && d.month == now.month && d.day == now.day - 1) return 'Yesterday';
    return '${d.day}/${d.month}';
  }
}
