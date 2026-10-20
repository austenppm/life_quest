import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_theme.dart';
import '../../models/workout.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';

class WorkoutLogScreen extends ConsumerStatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  ConsumerState<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends ConsumerState<WorkoutLogScreen> {
  final _exercises = <Map<String, dynamic>>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Log Workout'),
        actions: [
          TextButton(
            onPressed: _saveWorkout,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Exercises',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_exercises.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 48,
                      color: AppColors.textMuted.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No exercises added yet',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                  ],
                ),
              )
            else
              ..._exercises.asMap().entries.map((entry) => _ExerciseCard(
                    index: entry.key,
                    exercise: entry.value,
                    onRemove: () {
                      setState(() => _exercises.removeAt(entry.key));
                    },
                  )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddExerciseSheet(
        onAdd: (exercise) {
          setState(() => _exercises.add(exercise));
        },
      ),
    );
  }

  void _saveWorkout() {
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Convert exercise maps to Exercise models
    final exercises = _exercises.map((e) => Exercise(
          id: const Uuid().v4(),
          name: e['name'] ?? 'Exercise',
          sets: List.generate(
            e['sets'] ?? 3,
            (_) => ExerciseSet(reps: e['reps'] ?? 10, isCompleted: true),
          ),
        )).toList();

    final workout = Workout(
      id: const Uuid().v4(),
      userId: user.uid,
      name: 'Workout',
      date: DateTime.now(),
      durationMinutes: 0,
      exercises: exercises,
    );

    ref.read(workoutNotifierProvider.notifier).saveWorkout(workout);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Workout saved!'),
        backgroundColor: AppColors.success,
      ),
    );
    context.pop();
  }
}

class _ExerciseCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> exercise;
  final VoidCallback onRemove;

  const _ExerciseCard({
    required this.index,
    required this.exercise,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise['name'] ?? 'Exercise',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${exercise['sets']} sets × ${exercise['reps']} reps',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddExerciseSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const _AddExerciseSheet({required this.onAdd});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _nameController = TextEditingController();
  int _sets = 3;
  int _reps = 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Exercise',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Exercise Name',
              hintText: 'e.g., Bench Press',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sets'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_sets > 1) setState(() => _sets--);
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_sets', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          onPressed: () => setState(() => _sets++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reps'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_reps > 1) setState(() => _reps--);
                          },
                          icon: const Icon(Icons.remove),
                        ),
                        Text('$_reps', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          onPressed: () => setState(() => _reps++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  widget.onAdd({
                    'name': _nameController.text,
                    'sets': _sets,
                    'reps': _reps,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
