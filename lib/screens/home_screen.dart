import 'dart:async';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/storage_service.dart';
import 'add_habit_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Habit> _habits = [];
  bool _loading = true;
  bool _saving = false;
  String? _loadError;
  int _tab = 0;
  Timer? _dayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDayRefresh();
    _load();
  }

  @override
  void dispose() {
    _dayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recalculate today's schedule after returning across midnight.
    if (state == AppLifecycleState.resumed && mounted) {
      _scheduleDayRefresh();
      setState(() {});
    }
  }

  void _scheduleDayRefresh() {
    _dayTimer?.cancel();
    final now = clock.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _dayTimer = Timer(midnight.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleDayRefresh();
    });
  }

  Future<void> _load() async {
    try {
      final habits = await StorageService.getHabits();
      if (!mounted) return;
      setState(() {
        _habits = habits;
        _loadError = null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Saved habits could not be read. Your data has not been changed.';
        _loading = false;
      });
    }
  }

  Future<void> _save(List<Habit> next) async {
    try {
      await StorageService.saveHabits(next);
      if (mounted) setState(() => _habits = next);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Habits could not be saved. Please try again.')),
        );
      }
    }
  }

  Future<void> _add() async {
    if (_saving || _loading || _loadError != null) return;
    setState(() => _saving = true);
    try {
      final habit = await Navigator.push<Habit>(
          context, MaterialPageRoute(builder: (_) => const AddHabitScreen()));
      if (habit != null && mounted) await _save([..._habits, habit]);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggle(String id) async {
    if (_saving || _loading || _loadError != null) return;
    final today = clock.now();
    _scheduleDayRefresh();
    // A queued tap can come from yesterday's widget before the refresh frame.
    if (!_habits.any((habit) => habit.id == id && habit.isScheduledOn(today))) {
      setState(() {});
      return;
    }
    setState(() => _saving = true);
    try {
      await _save(_habits
          .map(
              (entry) => entry.id == id ? entry.toggleCompletion(today) : entry)
          .toList());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = clock.now();
    final scheduled =
        _habits.where((habit) => habit.isScheduledOn(today)).toList();
    final completed =
        scheduled.where((habit) => habit.isCompletedOn(today)).length;
    return Scaffold(
      appBar: AppBar(title: Text(['Today', 'All habits', 'Habit stats'][_tab])),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ]),
                ))
              : _tab == 2
                  ? StatsScreen(habits: _habits, today: today)
                  : _tab == 1
                      ? _allHabits()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          children: [
                            Text(
                                '$completed of ${scheduled.length} completed today'),
                            const SizedBox(height: 16),
                            if (scheduled.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No habits scheduled today.'),
                              ),
                            ...scheduled.map((habit) => Card(
                                    child: CheckboxListTile(
                                  title: Text(habit.name),
                                  subtitle: Text(
                                      '${habit.currentStreak(today)} day streak'),
                                  value: habit.isCompletedOn(today),
                                  onChanged:
                                      _saving ? null : (_) => _toggle(habit.id),
                                ))),
                          ],
                        ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.today), label: 'Today'),
          NavigationDestination(
              icon: Icon(Icons.checklist), label: 'All habits'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add habit',
        onPressed: _loading || _saving || _loadError != null ? null : _add,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _allHabits() => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (_habits.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Add your first habit with +.')),
          ..._habits.map((habit) => Card(
                  child: ListTile(
                title: Text(habit.name),
                subtitle: Text([
                  for (var day = 1; day <= 7; day++)
                    if (habit.schedule.contains(day)) weekdayLabels[day - 1],
                ].join(', ')),
                trailing: Text('${habit.completions.length} check-offs'),
              ))),
        ],
      );
}
