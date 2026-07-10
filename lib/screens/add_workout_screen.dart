import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../services/storage_service.dart';

class AddWorkoutScreen extends StatefulWidget {
  final String? presetGroup;
  const AddWorkoutScreen({super.key, this.presetGroup});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final _nameController = TextEditingController();
  String _selectedGroup = 'Chest';
  final List<ExerciseSet> _sets = [ExerciseSet(weight: 0, reps: 10)];
  final _notesController = TextEditingController();
  int _durationMinutes = 30;
  final _uuid = const Uuid();

  static const _groups = ['Chest', 'Back', 'Legs', 'Arms', 'Shoulders', 'Core', 'Full Body', 'Cardio'];
  static const _groupColors = {
    'Chest': Color(0xFFFF6B6B), 'Back': Color(0xFF4ECDC4), 'Legs': Color(0xFFFFE66D),
    'Arms': Color(0xFFA8E6CF), 'Shoulders': Color(0xFFFF8B94), 'Core': Color(0xFFB8A9C9),
    'Full Body': Color(0xFF00D4AA), 'Cardio': Color(0xFFFF9F43),
  };

  @override
  void initState() {
    super.initState();
    if (widget.presetGroup != null) _selectedGroup = widget.presetGroup!;
  }

  void _addSet() {
    final last = _sets.isNotEmpty ? _sets.last : ExerciseSet(weight: 0, reps: 10);
    setState(() => _sets.add(ExerciseSet(weight: last.weight, reps: last.reps)));
  }

  void _removeSet(int idx) {
    if (_sets.length > 1) setState(() => _sets.removeAt(idx));
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a workout name')));
      return;
    }
    final workout = Workout(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      muscleGroup: _selectedGroup,
      sets: _sets,
      date: DateTime.now(),
      durationSeconds: _durationMinutes * 60,
      notes: _notesController.text.trim(),
    );
    await StorageService.addWorkout(workout);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _groupColors[_selectedGroup] ?? const Color(0xFF00D4AA);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
        actions: [TextButton(onPressed: _save, child: Text('Save', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Workout Name', style: TextStyle(color: Color(0xFF484F58), fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'e.g. Push Day',
              hintStyle: const TextStyle(color: Color(0xFF484F58)),
              filled: true, fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Muscle Group', style: TextStyle(color: Color(0xFF484F58), fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _groups.map((g) {
              final selected = _selectedGroup == g;
              return ChoiceChip(
                label: Text(g, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 13)),
                selected: selected,
                selectedColor: _groupColors[g],
                backgroundColor: const Color(0xFF161B22),
                onSelected: (_) => setState(() => _selectedGroup = g),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Duration (minutes)', style: TextStyle(color: Color(0xFF484F58), fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(onPressed: () { if (_durationMinutes > 5) setState(() => _durationMinutes -= 5); }, icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF00D4AA))),
            Expanded(child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)), child: Text('$_durationMinutes min', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
            IconButton(onPressed: () => setState(() => _durationMinutes += 5), icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00D4AA))),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Sets', style: TextStyle(color: Color(0xFF484F58), fontSize: 14)),
            const Spacer(),
            TextButton.icon(onPressed: _addSet, icon: const Icon(Icons.add, color: Color(0xFF00D4AA), size: 18), label: const Text('Add Set', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 13))),
          ]),
          const SizedBox(height: 8),
          ...List.generate(_sets.length, (i) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Text('#${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 16),
              Expanded(child: Row(children: [
                Expanded(child: _setField('Weight', _sets[i].weight, (v) => setState(() => _sets[i] = ExerciseSet(weight: v, reps: _sets[i].reps)))),
                const SizedBox(width: 8),
                Expanded(child: _setField('Reps', _sets[i].reps, (v) => setState(() => _sets[i] = ExerciseSet(weight: _sets[i].weight, reps: v)))),
              ])),
              const SizedBox(width: 8),
              IconButton(onPressed: () => _removeSet(i), icon: const Icon(Icons.close, color: Color(0xFF484F58), size: 20)),
            ]),
          )),
          const SizedBox(height: 20),
          const Text('Notes', style: TextStyle(color: Color(0xFF484F58), fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'How did it feel?',
              hintStyle: const TextStyle(color: Color(0xFF484F58)),
              filled: true, fillColor: const Color(0xFF161B22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
            child: GestureDetector(onTap: _save, child: Text('Save Workout', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _setField(String label, int value, ValueChanged<int> onChanged) {
    return TextField(
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: label, hintStyle: const TextStyle(color: Color(0xFF484F58)),
        filled: true, fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      controller: TextEditingController(text: value.toString()),
      onChanged: (v) { final n = int.tryParse(v); if (n != null && n >= 0) onChanged(n); },
    );
  }
}
