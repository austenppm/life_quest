import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../models/workout.dart';
import '../../data/exercise_library.dart';
import '../../providers/workout_provider.dart';
import 'exercise_library_screen.dart';
import 'workout_logging_screen.dart';

class WorkoutTemplatesScreen extends ConsumerWidget {
  const WorkoutTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(workoutTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Templates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Template',
            onPressed: () => _showCreateTemplateSheet(context),
          ),
        ],
      ),
      body: templates.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) {
          if (data.isEmpty) {
            return _EmptyTemplates(
              onCreate: () => _showCreateTemplateSheet(context),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final template = data[index];
              return _TemplateTile(
                template: template,
                onStart: () => _startFromTemplate(context, ref, template),
                onEdit: () => _editTemplate(context, template),
                onDelete: () => _deleteTemplate(context, ref, template),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateTemplateSheet(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateTemplateScreen(),
      ),
    );
  }

  void _startFromTemplate(BuildContext context, WidgetRef ref, WorkoutTemplate template) {
    ref.read(workoutNotifierProvider.notifier).incrementTemplateUsage(template.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutLoggingScreen(template: template),
      ),
    );
  }

  void _editTemplate(BuildContext context, WorkoutTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateTemplateScreen(editTemplate: template),
      ),
    );
  }

  void _deleteTemplate(BuildContext context, WidgetRef ref, WorkoutTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(workoutNotifierProvider.notifier).deleteTemplate(template.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyTemplates({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_add,
              size: 80,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Templates Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create workout templates to quickly start your favorite routines',
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  final WorkoutTemplate template;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateTile({
    required this.template,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '~${template.estimatedMinutes} min',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.repeat, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${template.timesUsed}x used',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exercises list
          if (template.exercises.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${template.exercises.length} exercises',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...template.exercises.take(3).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.exerciseName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '${e.targetSets}x${e.targetReps}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (template.exercises.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+${template.exercises.length - 3} more',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Target muscles
          if (template.targetMuscles.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: template.targetMuscles.map((m) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${m.emoji} ${m.displayName}',
                    style: const TextStyle(fontSize: 11),
                  ),
                )).toList(),
              ),
            ),
          ],

          // Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Create/Edit Template Screen
class CreateTemplateScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? editTemplate;

  const CreateTemplateScreen({super.key, this.editTemplate});

  @override
  ConsumerState<CreateTemplateScreen> createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends ConsumerState<CreateTemplateScreen> {
  final _nameController = TextEditingController();
  final _exercises = <TemplateExercise>[];
  final _targetMuscles = <MuscleGroup>{};
  int _estimatedMinutes = 60;

  @override
  void initState() {
    super.initState();
    if (widget.editTemplate != null) {
      _nameController.text = widget.editTemplate!.name;
      _exercises.addAll(widget.editTemplate!.exercises);
      _targetMuscles.addAll(widget.editTemplate!.targetMuscles);
      _estimatedMinutes = widget.editTemplate!.estimatedMinutes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTemplate != null ? 'Edit Template' : 'New Template'),
        actions: [
          TextButton(
            onPressed: _saveTemplate,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Template Name',
                hintText: 'e.g., Push Day, Leg Day',
              ),
            ),
            const SizedBox(height: 24),

            // Estimated duration
            Row(
              children: [
                const Text(
                  'Estimated Duration',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$_estimatedMinutes min',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _estimatedMinutes.toDouble(),
              min: 15,
              max: 180,
              divisions: 33,
              onChanged: (v) => setState(() => _estimatedMinutes = v.round()),
            ),
            const SizedBox(height: 24),

            // Target muscles
            const Text(
              'Target Muscles',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.where((m) => m != MuscleGroup.cardio).map((muscle) {
                final isSelected = _targetMuscles.contains(muscle);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _targetMuscles.remove(muscle);
                      } else {
                        _targetMuscles.add(muscle);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      '${muscle.emoji} ${muscle.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? AppColors.primary : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Exercises
            Row(
              children: [
                const Text(
                  'Exercises',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_exercises.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: const Center(
                  child: Text(
                    'No exercises added yet\nTap "Add" to add exercises',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return _TemplateExerciseTile(
                    key: ValueKey(exercise.exerciseId + index.toString()),
                    exercise: exercise,
                    onEdit: () => _editExercise(index),
                    onDelete: () {
                      setState(() => _exercises.removeAt(index));
                    },
                  );
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _addExercise() async {
    final result = await Navigator.push<ExerciseDefinition>(
      context,
      MaterialPageRoute(
        builder: (_) => const ExerciseLibraryScreen(selectionMode: true),
      ),
    );

    if (result != null) {
      _showExerciseDetailsDialog(result);
    }
  }

  void _showExerciseDetailsDialog(ExerciseDefinition exercise, {int? editIndex}) {
    int sets = editIndex != null ? _exercises[editIndex].targetSets : 3;
    int reps = editIndex != null ? _exercises[editIndex].targetReps : 10;
    int rest = editIndex != null ? _exercises[editIndex].restSeconds : 90;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(exercise.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NumberRow(
                label: 'Sets',
                value: sets,
                onChanged: (v) => setDialogState(() => sets = v),
                min: 1,
                max: 10,
              ),
              const SizedBox(height: 12),
              _NumberRow(
                label: 'Reps',
                value: reps,
                onChanged: (v) => setDialogState(() => reps = v),
                min: 1,
                max: 50,
              ),
              const SizedBox(height: 12),
              _NumberRow(
                label: 'Rest (sec)',
                value: rest,
                onChanged: (v) => setDialogState(() => rest = v),
                min: 30,
                max: 300,
                step: 15,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final templateExercise = TemplateExercise(
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                  targetSets: sets,
                  targetReps: reps,
                  restSeconds: rest,
                );

                setState(() {
                  if (editIndex != null) {
                    _exercises[editIndex] = templateExercise;
                  } else {
                    _exercises.add(templateExercise);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(editIndex != null ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editExercise(int index) {
    final exercise = _exercises[index];
    final definition = ExerciseLibrary.exercises.firstWhere(
      (e) => e.id == exercise.exerciseId,
      orElse: () => ExerciseDefinition(
        id: exercise.exerciseId,
        name: exercise.exerciseName,
        primaryMuscle: MuscleGroup.fullBody,
      ),
    );
    _showExerciseDetailsDialog(definition, editIndex: index);
  }

  void _saveTemplate() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name')),
      );
      return;
    }

    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise')),
      );
      return;
    }

    if (widget.editTemplate != null) {
      // Update existing template
      ref.read(workoutNotifierProvider.notifier).updateTemplate(
        templateId: widget.editTemplate!.id,
        name: _nameController.text.trim(),
        exercises: _exercises,
        estimatedMinutes: _estimatedMinutes,
        targetMuscles: _targetMuscles.toList(),
      );
    } else {
      // Create new template
      ref.read(workoutNotifierProvider.notifier).createTemplate(
        name: _nameController.text.trim(),
        exercises: _exercises,
        estimatedMinutes: _estimatedMinutes,
        targetMuscles: _targetMuscles.toList(),
      );
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.editTemplate != null ? 'Template updated' : 'Template saved'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _TemplateExerciseTile extends StatelessWidget {
  final TemplateExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TemplateExerciseTile({
    super.key,
    required this.exercise,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${exercise.targetSets} sets × ${exercise.targetReps} reps • ${exercise.restSeconds}s rest',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: onEdit,
            color: AppColors.textMuted,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: onDelete,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  const _NumberRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min
              ? () => onChanged((value - step).clamp(min, max))
              : null,
        ),
        SizedBox(
          width: 50,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max
              ? () => onChanged((value + step).clamp(min, max))
              : null,
        ),
      ],
    );
  }
}
