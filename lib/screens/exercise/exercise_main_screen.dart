import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../models/workout.dart';
import '../../data/exercise_library.dart';
import '../../providers/workout_provider.dart';
import 'exercise_library_screen.dart';
import 'workout_logging_screen.dart';
import 'workout_templates_screen.dart';
import 'exercise_progress_screen.dart';

class ExerciseMainScreen extends ConsumerWidget {
  const ExerciseMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Workout History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExerciseProgressScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Start Section
            _SectionHeader(title: 'Quick Start'),
            const SizedBox(height: 12),
            _QuickStartCard(
              onStartEmpty: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WorkoutLoggingScreen(),
                  ),
                );
              },
              onBrowseExercises: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ExerciseLibraryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Templates Section
            _SectionHeader(
              title: 'My Templates',
              action: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WorkoutTemplatesScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ),
            const SizedBox(height: 12),
            _EmptyTemplatesCard(),
            const SizedBox(height: 24),

            // Muscle Groups
            _SectionHeader(title: 'Browse by Muscle'),
            const SizedBox(height: 12),
            _MuscleGroupsGrid(),
            const SizedBox(height: 24),

            // Recent Workouts
            _SectionHeader(
              title: 'Recent Workouts',
              action: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExerciseProgressScreen(),
                    ),
                  );
                },
                child: const Text('See All'),
              ),
            ),
            const SizedBox(height: 12),
            _EmptyWorkoutsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkoutLoggingScreen(),
            ),
          );
        },
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Workout'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final VoidCallback onStartEmpty;
  final VoidCallback onBrowseExercises;

  const _QuickStartCard({
    required this.onStartEmpty,
    required this.onBrowseExercises,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Start Training',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log your workout and track progress',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onStartEmpty,
                  icon: const Icon(Icons.add),
                  label: const Text('Empty Workout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onBrowseExercises,
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Exercises'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTemplatesCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          Icon(
            Icons.library_add,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No templates yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Save your favorite workouts as templates',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WorkoutTemplatesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Template'),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final muscleGroups = [
      MuscleGroup.chest,
      MuscleGroup.back,
      MuscleGroup.shoulders,
      MuscleGroup.biceps,
      MuscleGroup.triceps,
      MuscleGroup.quads,
      MuscleGroup.hamstrings,
      MuscleGroup.abs,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: muscleGroups.length,
      itemBuilder: (context, index) {
        final muscle = muscleGroups[index];
        final exerciseCount = ExerciseLibrary.getByMuscle(muscle).length;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExerciseLibraryScreen(initialMuscle: muscle),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  muscle.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  muscle.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$exerciseCount',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyWorkoutsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No workouts yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start your first workout to see your progress',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
