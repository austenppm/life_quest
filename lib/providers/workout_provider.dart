import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/workout.dart';
import 'auth_provider.dart';

// Workouts stream provider
final workoutsProvider = StreamProvider<List<Workout>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('workouts')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Workout.fromFirestore(doc)).toList());
});

// Recent workouts (last 7 days)
final recentWorkoutsProvider = Provider<List<Workout>>((ref) {
  final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  return workouts.where((w) => w.date.isAfter(weekAgo)).toList();
});

// Workout templates stream provider
final workoutTemplatesProvider = StreamProvider<List<WorkoutTemplate>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('workoutTemplates')
      .orderBy('timesUsed', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => WorkoutTemplate.fromFirestore(doc)).toList());
});

// Workout statistics
final workoutStatsProvider = Provider<WorkoutStats>((ref) {
  final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];

  if (workouts.isEmpty) {
    return const WorkoutStats(
      totalWorkouts: 0,
      totalMinutes: 0,
      totalVolume: 0,
      workoutsThisWeek: 0,
      currentStreak: 0,
    );
  }

  final now = DateTime.now();
  final weekStart = now.subtract(Duration(days: now.weekday - 1));

  int workoutsThisWeek = 0;
  double totalVolume = 0;
  int totalMinutes = 0;

  for (final workout in workouts) {
    totalMinutes += workout.durationMinutes;

    if (workout.date.isAfter(weekStart)) {
      workoutsThisWeek++;
    }

    for (final exercise in workout.exercises) {
      for (final set in exercise.sets) {
        totalVolume += set.volume;
      }
    }
  }

  // Calculate streak
  int streak = 0;
  DateTime checkDate = DateTime(now.year, now.month, now.day);

  while (true) {
    final hasWorkout = workouts.any((w) =>
        w.date.year == checkDate.year &&
        w.date.month == checkDate.month &&
        w.date.day == checkDate.day);

    if (hasWorkout) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else if (checkDate.day == now.day) {
      // Today doesn't have a workout yet, check yesterday
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  return WorkoutStats(
    totalWorkouts: workouts.length,
    totalMinutes: totalMinutes,
    totalVolume: totalVolume,
    workoutsThisWeek: workoutsThisWeek,
    currentStreak: streak,
  );
});

class WorkoutStats {
  final int totalWorkouts;
  final int totalMinutes;
  final double totalVolume;
  final int workoutsThisWeek;
  final int currentStreak;

  const WorkoutStats({
    required this.totalWorkouts,
    required this.totalMinutes,
    required this.totalVolume,
    required this.workoutsThisWeek,
    required this.currentStreak,
  });
}

// Exercise history for a specific exercise
final exerciseHistoryProvider = Provider.family<List<ExerciseHistory>, String>((ref, exerciseName) {
  final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];
  final history = <ExerciseHistory>[];

  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      if (exercise.name.toLowerCase() == exerciseName.toLowerCase()) {
        double maxWeight = 0;
        int totalReps = 0;
        double totalVolume = 0;

        for (final set in exercise.sets) {
          if (set.weight != null && set.weight! > maxWeight) {
            maxWeight = set.weight!;
          }
          totalReps += set.reps;
          totalVolume += set.volume;
        }

        history.add(ExerciseHistory(
          date: workout.date,
          maxWeight: maxWeight,
          totalReps: totalReps,
          totalVolume: totalVolume,
          sets: exercise.sets.length,
        ));
      }
    }
  }

  history.sort((a, b) => a.date.compareTo(b.date));
  return history;
});

class ExerciseHistory {
  final DateTime date;
  final double maxWeight;
  final int totalReps;
  final double totalVolume;
  final int sets;

  const ExerciseHistory({
    required this.date,
    required this.maxWeight,
    required this.totalReps,
    required this.totalVolume,
    required this.sets,
  });
}

// Personal records provider
final personalRecordsProvider = Provider<Map<String, PersonalRecord>>((ref) {
  final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];
  final records = <String, PersonalRecord>{};

  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      final name = exercise.name.toLowerCase();

      for (final set in exercise.sets) {
        if (set.weight == null || set.reps == 0) continue;

        final currentRecord = records[name];
        final oneRepMax = set.weight! * (1 + set.reps / 30); // Epley formula

        if (currentRecord == null || oneRepMax > currentRecord.estimatedOneRepMax) {
          records[name] = PersonalRecord(
            exerciseName: exercise.name,
            weight: set.weight!,
            reps: set.reps,
            estimatedOneRepMax: oneRepMax,
            date: workout.date,
          );
        }
      }
    }
  }

  return records;
});

class PersonalRecord {
  final String exerciseName;
  final double weight;
  final int reps;
  final double estimatedOneRepMax;
  final DateTime date;

  const PersonalRecord({
    required this.exerciseName,
    required this.weight,
    required this.reps,
    required this.estimatedOneRepMax,
    required this.date,
  });
}

// Workout notifier for CRUD operations
class WorkoutNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;

  WorkoutNotifier(this._userId) : super(const AsyncValue.data(null));

  Future<void> saveWorkout(Workout workout) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .doc(workout.id)
          .set(workout.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workouts')
          .doc(workoutId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Template methods
  Future<void> createTemplate({
    required String name,
    required List<TemplateExercise> exercises,
    int estimatedMinutes = 60,
    List<MuscleGroup> targetMuscles = const [],
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final template = WorkoutTemplate(
        id: const Uuid().v4(),
        userId: _userId,
        name: name,
        exercises: exercises,
        estimatedMinutes: estimatedMinutes,
        targetMuscles: targetMuscles,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutTemplates')
          .doc(template.id)
          .set(template.toFirestore());

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutTemplates')
          .doc(templateId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTemplate({
    required String templateId,
    required String name,
    required List<TemplateExercise> exercises,
    int estimatedMinutes = 60,
    List<MuscleGroup> targetMuscles = const [],
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutTemplates')
          .doc(templateId)
          .update({
        'name': name,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'estimatedMinutes': estimatedMinutes,
        'targetMuscles': targetMuscles.map((m) => m.name).toList(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> incrementTemplateUsage(String templateId) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('workoutTemplates')
          .doc(templateId)
          .update({'timesUsed': FieldValue.increment(1)});
    } catch (_) {}
  }
}

final workoutNotifierProvider =
    StateNotifierProvider<WorkoutNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return WorkoutNotifier(user?.uid);
});

// Custom exercises provider
final customExercisesProvider = StreamProvider<List<ExerciseDefinition>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('customExercises')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return ExerciseDefinition(
              id: doc.id,
              name: data['name'] ?? '',
              primaryMuscle: MuscleGroup.values.firstWhere(
                (m) => m.name == data['primaryMuscle'],
                orElse: () => MuscleGroup.chest,
              ),
              secondaryMuscles: (data['secondaryMuscles'] as List<dynamic>?)
                      ?.map((m) => MuscleGroup.values.firstWhere(
                            (mg) => mg.name == m,
                            orElse: () => MuscleGroup.chest,
                          ))
                      .toList() ??
                  [],
              equipment: Equipment.values.firstWhere(
                (e) => e.name == data['equipment'],
                orElse: () => Equipment.barbell,
              ),
              type: ExerciseType.values.firstWhere(
                (t) => t.name == data['type'],
                orElse: () => ExerciseType.strength,
              ),
              instructions: data['instructions'],
              isCustom: true,
            );
          }).toList());
});

// Custom exercise notifier for CRUD operations
class CustomExerciseNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;

  CustomExerciseNotifier(this._userId) : super(const AsyncValue.data(null));

  Future<void> addCustomExercise(ExerciseDefinition exercise) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('customExercises')
          .doc(exercise.id)
          .set({
        'name': exercise.name,
        'primaryMuscle': exercise.primaryMuscle.name,
        'secondaryMuscles': exercise.secondaryMuscles.map((m) => m.name).toList(),
        'equipment': exercise.equipment.name,
        'type': exercise.type.name,
        'instructions': exercise.instructions,
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCustomExercise(String exerciseId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('customExercises')
          .doc(exerciseId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final customExerciseNotifierProvider =
    StateNotifierProvider<CustomExerciseNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return CustomExerciseNotifier(user?.uid);
});
