import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../models/workout.dart';
import '../../data/exercise_library.dart';
import '../../providers/workout_provider.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  final MuscleGroup? initialMuscle;
  final bool selectionMode;
  final Function(ExerciseDefinition)? onSelect;

  const ExerciseLibraryScreen({
    super.key,
    this.initialMuscle,
    this.selectionMode = false,
    this.onSelect,
  });

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchController = TextEditingController();
  MuscleGroup? _selectedMuscle;
  Equipment? _selectedEquipment;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedMuscle = widget.initialMuscle;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExerciseDefinition> _getFilteredExercises(List<ExerciseDefinition> customExercises) {
    // Combine library exercises with custom exercises
    var exercises = [...ExerciseLibrary.exercises, ...customExercises];

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      exercises = exercises.where((e) =>
        e.name.toLowerCase().contains(query) ||
        e.primaryMuscle.displayName.toLowerCase().contains(query)
      ).toList();
    }

    if (_selectedMuscle != null) {
      exercises = exercises.where((e) =>
        e.primaryMuscle == _selectedMuscle ||
        e.secondaryMuscles.contains(_selectedMuscle)
      ).toList();
    }

    if (_selectedEquipment != null) {
      exercises = exercises.where((e) => e.equipment == _selectedEquipment).toList();
    }

    // Sort custom exercises first
    exercises.sort((a, b) {
      if (a.isCustom && !b.isCustom) return -1;
      if (!a.isCustom && b.isCustom) return 1;
      return a.name.compareTo(b.name);
    });

    return exercises;
  }

  @override
  Widget build(BuildContext context) {
    final customExercisesAsync = ref.watch(customExercisesProvider);
    final customExercises = customExercisesAsync.valueOrNull ?? [];
    final exercises = _getFilteredExercises(customExercises);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectionMode ? 'Select Exercise' : 'Exercise Library'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCustomExerciseDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Custom Exercise'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Muscles',
                  isSelected: _selectedMuscle == null,
                  onTap: () => setState(() => _selectedMuscle = null),
                ),
                const SizedBox(width: 8),
                ...MuscleGroup.values.where((m) => m != MuscleGroup.cardio).take(8).map((muscle) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: muscle.displayName,
                      isSelected: _selectedMuscle == muscle,
                      onTap: () => setState(() {
                        _selectedMuscle = _selectedMuscle == muscle ? null : muscle;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Equipment filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Equipment',
                  isSelected: _selectedEquipment == null,
                  onTap: () => setState(() => _selectedEquipment = null),
                  secondary: true,
                ),
                const SizedBox(width: 8),
                ...Equipment.values.map((equipment) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: equipment.displayName,
                      isSelected: _selectedEquipment == equipment,
                      onTap: () => setState(() {
                        _selectedEquipment = _selectedEquipment == equipment ? null : equipment;
                      }),
                      secondary: true,
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${exercises.length} exercises',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercises.isEmpty
                ? _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return _ExerciseTile(
                        exercise: exercise,
                        onTap: () {
                          if (widget.selectionMode && widget.onSelect != null) {
                            widget.onSelect!(exercise);
                            Navigator.pop(context);
                          } else {
                            _showExerciseDetails(context, exercise);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomExerciseDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateCustomExerciseSheet(
        onExerciseCreated: (exercise) {
          ref.read(customExerciseNotifierProvider.notifier).addCustomExercise(exercise);
        },
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, ExerciseDefinition exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        exercise.primaryMuscle.displayName,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow('Primary Muscle', exercise.primaryMuscle.displayName),
            if (exercise.secondaryMuscles.isNotEmpty)
              _DetailRow(
                'Secondary Muscles',
                exercise.secondaryMuscles.map((m) => m.displayName).join(', '),
              ),
            _DetailRow('Equipment', exercise.equipment.displayName),
            _DetailRow('Type', exercise.type.name.toUpperCase()),
            if (exercise.instructions != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Instructions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions!,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  if (widget.onSelect != null) {
                    widget.onSelect!(exercise);
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add to Workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool secondary;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (secondary ? AppColors.accent : AppColors.primary)
              : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (secondary ? AppColors.accent : AppColors.primary)
                : AppColors.surfaceLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final ExerciseDefinition exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(exercise.primaryMuscle.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${exercise.primaryMuscle.displayName} • ${exercise.equipment.displayName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _CreateCustomExerciseSheet extends StatefulWidget {
  final Function(ExerciseDefinition) onExerciseCreated;

  const _CreateCustomExerciseSheet({required this.onExerciseCreated});

  @override
  State<_CreateCustomExerciseSheet> createState() => _CreateCustomExerciseSheetState();
}

class _CreateCustomExerciseSheetState extends State<_CreateCustomExerciseSheet> {
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  MuscleGroup _primaryMuscle = MuscleGroup.chest;
  final Set<MuscleGroup> _secondaryMuscles = {};
  Equipment _equipment = Equipment.barbell;
  ExerciseType _exerciseType = ExerciseType.strength;

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _createExercise() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }

    final exercise = ExerciseDefinition(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      primaryMuscle: _primaryMuscle,
      secondaryMuscles: _secondaryMuscles.toList(),
      equipment: _equipment,
      type: _exerciseType,
      instructions: _instructionsController.text.trim().isNotEmpty
          ? _instructionsController.text.trim()
          : null,
      isCustom: true,
    );

    widget.onExerciseCreated(exercise);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_circle, color: AppColors.accent),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Create Custom Exercise',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Exercise Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g., Bulgarian Split Squat',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Primary Muscle
            const Text(
              'Primary Muscle',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.map((muscle) {
                final isSelected = _primaryMuscle == muscle;
                return GestureDetector(
                  onTap: () => setState(() => _primaryMuscle = muscle),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      '${muscle.emoji} ${muscle.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Secondary Muscles
            const Text(
              'Secondary Muscles (optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MuscleGroup.values.where((m) => m != _primaryMuscle).map((muscle) {
                final isSelected = _secondaryMuscles.contains(muscle);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isSelected) {
                      _secondaryMuscles.remove(muscle);
                    } else {
                      _secondaryMuscles.add(muscle);
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      muscle.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Equipment
            const Text(
              'Equipment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Equipment.values.map((equipment) {
                final isSelected = _equipment == equipment;
                return GestureDetector(
                  onTap: () => setState(() => _equipment = equipment),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      equipment.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Exercise Type
            const Text(
              'Exercise Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ExerciseType.values.map((type) {
                final isSelected = _exerciseType == type;
                return GestureDetector(
                  onTap: () => setState(() => _exerciseType = type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                      ),
                    ),
                    child: Text(
                      type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Instructions
            TextField(
              controller: _instructionsController,
              decoration: InputDecoration(
                labelText: 'Instructions (optional)',
                hintText: 'Describe how to perform this exercise...',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createExercise,
                icon: const Icon(Icons.check),
                label: const Text('Create Exercise'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
