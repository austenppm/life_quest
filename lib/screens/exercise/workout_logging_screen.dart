import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../theme/app_theme.dart';
import '../../models/workout.dart';
import '../../data/exercise_library.dart';
import '../../providers/workout_provider.dart';
import '../../providers/auth_provider.dart';
import 'exercise_library_screen.dart';

class WorkoutLoggingScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? template;

  const WorkoutLoggingScreen({super.key, this.template});

  @override
  ConsumerState<WorkoutLoggingScreen> createState() => _WorkoutLoggingScreenState();
}

class _WorkoutLoggingScreenState extends ConsumerState<WorkoutLoggingScreen> {
  final List<_LoggedExercise> _exercises = [];
  final _nameController = TextEditingController();
  DateTime _startTime = DateTime.now();
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

  // Rest timer
  Timer? _restTimer;
  int _restSecondsRemaining = 0;
  int _defaultRestSeconds = 90;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
    if (widget.template != null) {
      _loadTemplate(widget.template!);
    }
  }

  void _loadTemplate(WorkoutTemplate template) {
    _nameController.text = template.name;
    for (final exercise in template.exercises) {
      final def = ExerciseLibrary.getById(exercise.exerciseId);
      if (def != null) {
        _exercises.add(_LoggedExercise(
          definition: def,
          sets: List.generate(
            exercise.targetSets,
            (_) => ExerciseSet(reps: exercise.targetReps),
          ),
        ));
      }
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_startTime);
      });
    });
  }

  void _startRestTimer() {
    setState(() {
      _isResting = true;
      _restSecondsRemaining = _defaultRestSeconds;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _restSecondsRemaining--;
        if (_restSecondsRemaining <= 0) {
          _stopRestTimer();
          HapticFeedback.heavyImpact();
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = 0;
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _restTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseLibraryScreen(
          selectionMode: true,
          onSelect: (exercise) {
            setState(() {
              _exercises.add(_LoggedExercise(
                definition: exercise,
                sets: [const ExerciseSet()],
              ));
            });
          },
        ),
      ),
    );
  }

  void _finishWorkout() {
    final totalSets = _exercises.fold(0, (sum, e) => sum + e.sets.length);
    final completedSets = _exercises.fold(
      0,
      (sum, e) => sum + e.sets.where((s) => s.isCompleted).length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${_formatDuration(_elapsed)}'),
            Text('Exercises: ${_exercises.length}'),
            Text('Sets: $completedSets / $totalSets'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => _saveAndExit(),
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndExit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      Navigator.pop(context);
      Navigator.pop(context);
      return;
    }

    try {
      // Convert logged exercises to Exercise models
      final exercises = _exercises.map((logged) => Exercise(
        id: const Uuid().v4(),
        name: logged.definition.name,
        type: logged.definition.type,
        muscleGroup: logged.definition.primaryMuscle.name,
        sets: logged.sets,
      )).toList();

      // Create workout object
      final workout = Workout(
        id: const Uuid().v4(),
        userId: user.uid,
        name: _nameController.text.isEmpty ? 'Workout' : _nameController.text,
        date: _startTime,
        durationMinutes: _elapsed.inMinutes,
        exercises: exercises,
      );

      // Save to Firebase
      await ref.read(workoutNotifierProvider.notifier).saveWorkout(workout);

      // Increment template usage if using a template
      if (widget.template != null) {
        await ref.read(workoutNotifierProvider.notifier).incrementTemplateUsage(widget.template!.id);
      }

      if (mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pop(context); // Close workout screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nameController.text.isEmpty ? 'Workout' : _nameController.text,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              _formatDuration(_elapsed),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('Finish'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest timer banner
          if (_isResting)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rest Timer',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_restSecondsRemaining}s remaining',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            _restSecondsRemaining = (_restSecondsRemaining - 15).clamp(0, 999);
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            _restSecondsRemaining += 15;
                          });
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: _stopRestTimer,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Exercises list
          Expanded(
            child: _exercises.isEmpty
                ? _EmptyState(onAddExercise: _addExercise)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _exercises.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return _AddExerciseButton(onTap: _addExercise);
                      }
                      return _ExerciseCard(
                        exercise: _exercises[index],
                        onAddSet: () {
                          setState(() {
                            _exercises[index].sets.add(const ExerciseSet());
                          });
                        },
                        onRemoveSet: (setIndex) {
                          setState(() {
                            _exercises[index].sets.removeAt(setIndex);
                          });
                        },
                        onSetCompleted: (setIndex) {
                          setState(() {
                            _exercises[index].sets[setIndex] = _exercises[index]
                                .sets[setIndex]
                                .copyWith(isCompleted: true);
                          });
                          _startRestTimer();
                        },
                        onSetUpdated: (setIndex, set) {
                          setState(() {
                            _exercises[index].sets[setIndex] = set;
                          });
                        },
                        onRemove: () {
                          setState(() {
                            _exercises.removeAt(index);
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoggedExercise {
  final ExerciseDefinition definition;
  List<ExerciseSet> sets;

  _LoggedExercise({
    required this.definition,
    required this.sets,
  });
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddExercise;

  const _EmptyState({required this.onAddExercise});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No exercises yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add exercises to start your workout',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddExerciseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 80),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Add Exercise',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _LoggedExercise exercise;
  final VoidCallback onAddSet;
  final Function(int) onRemoveSet;
  final Function(int) onSetCompleted;
  final Function(int, ExerciseSet) onSetUpdated;
  final VoidCallback onRemove;

  const _ExerciseCard({
    required this.exercise,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onSetCompleted,
    required this.onSetUpdated,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  exercise.definition.primaryMuscle.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.definition.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        exercise.definition.primaryMuscle.displayName,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.delete, color: AppColors.error),
                            title: const Text('Remove Exercise'),
                            onTap: () {
                              Navigator.pop(context);
                              onRemove();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Sets header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                SizedBox(width: 40, child: Text('SET', style: TextStyle(fontSize: 10, color: AppColors.textMuted))),
                Expanded(child: Center(child: Text('WEIGHT', style: TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                Expanded(child: Center(child: Text('REPS', style: TextStyle(fontSize: 10, color: AppColors.textMuted)))),
                SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Sets list
          ...exercise.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return _SetRow(
              setNumber: index + 1,
              set: set,
              onComplete: () => onSetCompleted(index),
              onUpdate: (updatedSet) => onSetUpdated(index, updatedSet),
              onRemove: () => onRemoveSet(index),
            );
          }),

          // Add set button
          TextButton.icon(
            onPressed: onAddSet,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Set'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setNumber;
  final ExerciseSet set;
  final VoidCallback onComplete;
  final Function(ExerciseSet) onUpdate;
  final VoidCallback onRemove;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.onComplete,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _updateSet() {
    widget.onUpdate(widget.set.copyWith(
      weight: double.tryParse(_weightController.text),
      reps: int.tryParse(_repsController.text) ?? 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.set.isCompleted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.success.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 32,
            child: Text(
              '${widget.setNumber}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCompleted ? AppColors.success : AppColors.textMuted,
              ),
            ),
          ),

          // Weight input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: 'kg',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                ),
                onChanged: (_) => _updateSet(),
              ),
            ),
          ),

          // Reps input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  hintText: 'reps',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.card,
                ),
                onChanged: (_) => _updateSet(),
              ),
            ),
          ),

          // Complete button
          GestureDetector(
            onTap: isCompleted ? null : widget.onComplete,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.success : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check,
                color: isCompleted ? Colors.white : AppColors.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
