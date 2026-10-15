import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';

const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _schedule = <int>{1, 2, 3, 4, 5, 6, 7};
  bool _missingSchedule = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final validName = _formKey.currentState!.validate();
    setState(() => _missingSchedule = _schedule.isEmpty);
    if (!validName || _schedule.isEmpty) return;
    Navigator.pop(context,
        Habit(id: const Uuid().v4(), name: _name.text, schedule: _schedule));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add habit')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: 80,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Habit name', hintText: 'Read ten pages'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a habit name.'
                    : null,
              ),
              const SizedBox(height: 24),
              const Text('Repeat on'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  return FilterChip(
                    label: Text(weekdayLabels[index]),
                    selected: _schedule.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _schedule.add(day);
                      } else {
                        _schedule.remove(day);
                      }
                      _missingSchedule = _schedule.isEmpty;
                    }),
                  );
                }),
              ),
              if (_missingSchedule)
                Text('Choose at least one day.',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 24),
              FilledButton(onPressed: _save, child: const Text('Save habit')),
            ],
          ),
        ),
      );
}
