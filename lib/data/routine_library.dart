import '../models/workout.dart';

/// Pre-made workout routines library (like Hevy's routine library)
class RoutineLibrary {
  /// All pre-made routines
  static final List<PreMadeRoutine> routines = [
    // Push Pull Legs
    _pushDay,
    _pullDay,
    _legDay,
    // Upper Lower
    _upperBody,
    _lowerBody,
    // Full Body
    _fullBodyA,
    _fullBodyB,
    // Specialty
    _chestAndTriceps,
    _backAndBiceps,
    _shouldersAndArms,
    _coreWorkout,
    _cardioHiit,
    // Beginner
    _beginnerFullBody,
    _beginnerUpperLower,
  ];

  static final _pushDay = PreMadeRoutine(
    id: 'ppl_push',
    name: 'Push Day (PPL)',
    description: 'Chest, shoulders, and triceps focused workout',
    category: RoutineCategory.pushPullLegs,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 60,
    targetMuscles: [MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps],
    exercises: [
      PreMadeExercise(name: 'Bench Press', sets: 4, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Incline Dumbbell Press', sets: 3, reps: '10-12', restSeconds: 90),
      PreMadeExercise(name: 'Overhead Press', sets: 4, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Lateral Raises', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Tricep Pushdowns', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Overhead Tricep Extension', sets: 3, reps: '10-12', restSeconds: 60),
    ],
  );

  static final _pullDay = PreMadeRoutine(
    id: 'ppl_pull',
    name: 'Pull Day (PPL)',
    description: 'Back and biceps focused workout',
    category: RoutineCategory.pushPullLegs,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 60,
    targetMuscles: [MuscleGroup.back, MuscleGroup.biceps, MuscleGroup.forearms],
    exercises: [
      PreMadeExercise(name: 'Deadlift', sets: 4, reps: '5-6', restSeconds: 180),
      PreMadeExercise(name: 'Pull-ups', sets: 4, reps: '6-10', restSeconds: 120),
      PreMadeExercise(name: 'Barbell Rows', sets: 4, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Face Pulls', sets: 3, reps: '15-20', restSeconds: 60),
      PreMadeExercise(name: 'Barbell Curls', sets: 3, reps: '10-12', restSeconds: 60),
      PreMadeExercise(name: 'Hammer Curls', sets: 3, reps: '10-12', restSeconds: 60),
    ],
  );

  static final _legDay = PreMadeRoutine(
    id: 'ppl_legs',
    name: 'Leg Day (PPL)',
    description: 'Quads, hamstrings, and glutes focused workout',
    category: RoutineCategory.pushPullLegs,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 70,
    targetMuscles: [MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.calves],
    exercises: [
      PreMadeExercise(name: 'Squats', sets: 4, reps: '6-8', restSeconds: 180),
      PreMadeExercise(name: 'Romanian Deadlift', sets: 4, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Leg Press', sets: 3, reps: '10-12', restSeconds: 120),
      PreMadeExercise(name: 'Walking Lunges', sets: 3, reps: '12 each', restSeconds: 90),
      PreMadeExercise(name: 'Leg Curls', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Calf Raises', sets: 4, reps: '15-20', restSeconds: 60),
    ],
  );

  static final _upperBody = PreMadeRoutine(
    id: 'ul_upper',
    name: 'Upper Body',
    description: 'Complete upper body workout for upper/lower split',
    category: RoutineCategory.upperLower,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 60,
    targetMuscles: [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps],
    exercises: [
      PreMadeExercise(name: 'Bench Press', sets: 4, reps: '6-8', restSeconds: 120),
      PreMadeExercise(name: 'Barbell Rows', sets: 4, reps: '6-8', restSeconds: 120),
      PreMadeExercise(name: 'Overhead Press', sets: 3, reps: '8-10', restSeconds: 90),
      PreMadeExercise(name: 'Lat Pulldown', sets: 3, reps: '10-12', restSeconds: 90),
      PreMadeExercise(name: 'Dumbbell Curls', sets: 3, reps: '10-12', restSeconds: 60),
      PreMadeExercise(name: 'Tricep Dips', sets: 3, reps: '10-12', restSeconds: 60),
    ],
  );

  static final _lowerBody = PreMadeRoutine(
    id: 'ul_lower',
    name: 'Lower Body',
    description: 'Complete lower body workout for upper/lower split',
    category: RoutineCategory.upperLower,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 55,
    targetMuscles: [MuscleGroup.quads, MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.calves],
    exercises: [
      PreMadeExercise(name: 'Squats', sets: 4, reps: '6-8', restSeconds: 180),
      PreMadeExercise(name: 'Romanian Deadlift', sets: 4, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Bulgarian Split Squats', sets: 3, reps: '10 each', restSeconds: 90),
      PreMadeExercise(name: 'Leg Curls', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Leg Extensions', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Standing Calf Raises', sets: 4, reps: '15-20', restSeconds: 60),
    ],
  );

  static final _fullBodyA = PreMadeRoutine(
    id: 'fb_a',
    name: 'Full Body A',
    description: 'Compound-focused full body workout',
    category: RoutineCategory.fullBody,
    difficulty: RoutineDifficulty.beginner,
    estimatedMinutes: 50,
    targetMuscles: [MuscleGroup.fullBody],
    exercises: [
      PreMadeExercise(name: 'Squats', sets: 3, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Bench Press', sets: 3, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Barbell Rows', sets: 3, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Overhead Press', sets: 3, reps: '8-10', restSeconds: 90),
      PreMadeExercise(name: 'Romanian Deadlift', sets: 3, reps: '10-12', restSeconds: 90),
      PreMadeExercise(name: 'Plank', sets: 3, reps: '30-60s', restSeconds: 60),
    ],
  );

  static final _fullBodyB = PreMadeRoutine(
    id: 'fb_b',
    name: 'Full Body B',
    description: 'Variation day for full body program',
    category: RoutineCategory.fullBody,
    difficulty: RoutineDifficulty.beginner,
    estimatedMinutes: 50,
    targetMuscles: [MuscleGroup.fullBody],
    exercises: [
      PreMadeExercise(name: 'Deadlift', sets: 3, reps: '5-6', restSeconds: 180),
      PreMadeExercise(name: 'Incline Dumbbell Press', sets: 3, reps: '10-12', restSeconds: 90),
      PreMadeExercise(name: 'Pull-ups', sets: 3, reps: 'AMRAP', restSeconds: 120),
      PreMadeExercise(name: 'Dumbbell Lunges', sets: 3, reps: '10 each', restSeconds: 90),
      PreMadeExercise(name: 'Lateral Raises', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Bicycle Crunches', sets: 3, reps: '20', restSeconds: 60),
    ],
  );

  static final _chestAndTriceps = PreMadeRoutine(
    id: 'chest_tri',
    name: 'Chest & Triceps',
    description: 'Focused chest and triceps workout',
    category: RoutineCategory.bodyPart,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 50,
    targetMuscles: [MuscleGroup.chest, MuscleGroup.triceps],
    exercises: [
      PreMadeExercise(name: 'Bench Press', sets: 4, reps: '6-8', restSeconds: 120),
      PreMadeExercise(name: 'Incline Dumbbell Press', sets: 3, reps: '8-10', restSeconds: 90),
      PreMadeExercise(name: 'Cable Flyes', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Dips', sets: 3, reps: '8-12', restSeconds: 90),
      PreMadeExercise(name: 'Skull Crushers', sets: 3, reps: '10-12', restSeconds: 60),
      PreMadeExercise(name: 'Tricep Pushdowns', sets: 3, reps: '12-15', restSeconds: 60),
    ],
  );

  static final _backAndBiceps = PreMadeRoutine(
    id: 'back_bi',
    name: 'Back & Biceps',
    description: 'Focused back and biceps workout',
    category: RoutineCategory.bodyPart,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 55,
    targetMuscles: [MuscleGroup.back, MuscleGroup.biceps],
    exercises: [
      PreMadeExercise(name: 'Pull-ups', sets: 4, reps: '6-10', restSeconds: 120),
      PreMadeExercise(name: 'Barbell Rows', sets: 4, reps: '8-10', restSeconds: 120),
      PreMadeExercise(name: 'Seated Cable Rows', sets: 3, reps: '10-12', restSeconds: 90),
      PreMadeExercise(name: 'Lat Pulldown', sets: 3, reps: '10-12', restSeconds: 90),
      PreMadeExercise(name: 'Barbell Curls', sets: 3, reps: '10-12', restSeconds: 60),
      PreMadeExercise(name: 'Incline Dumbbell Curls', sets: 3, reps: '10-12', restSeconds: 60),
    ],
  );

  static final _shouldersAndArms = PreMadeRoutine(
    id: 'shoulders_arms',
    name: 'Shoulders & Arms',
    description: 'Complete shoulder and arm workout',
    category: RoutineCategory.bodyPart,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 50,
    targetMuscles: [MuscleGroup.shoulders, MuscleGroup.biceps, MuscleGroup.triceps],
    exercises: [
      PreMadeExercise(name: 'Overhead Press', sets: 4, reps: '6-8', restSeconds: 120),
      PreMadeExercise(name: 'Lateral Raises', sets: 4, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Rear Delt Flyes', sets: 3, reps: '12-15', restSeconds: 60),
      PreMadeExercise(name: 'Barbell Curls', sets: 3, reps: '10-12', restSeconds: 60),
      PreMadeExercise(name: 'Skull Crushers', sets: 3, reps: '10-12', restSeconds: 60),
      PreMadeExercise(name: 'Hammer Curls', sets: 3, reps: '10-12', restSeconds: 60),
    ],
  );

  static final _coreWorkout = PreMadeRoutine(
    id: 'core',
    name: 'Core Workout',
    description: 'Comprehensive core and abs routine',
    category: RoutineCategory.specialty,
    difficulty: RoutineDifficulty.beginner,
    estimatedMinutes: 25,
    targetMuscles: [MuscleGroup.abs, MuscleGroup.obliques],
    exercises: [
      PreMadeExercise(name: 'Plank', sets: 3, reps: '45-60s', restSeconds: 45),
      PreMadeExercise(name: 'Bicycle Crunches', sets: 3, reps: '20', restSeconds: 30),
      PreMadeExercise(name: 'Leg Raises', sets: 3, reps: '15', restSeconds: 45),
      PreMadeExercise(name: 'Russian Twists', sets: 3, reps: '20', restSeconds: 30),
      PreMadeExercise(name: 'Dead Bug', sets: 3, reps: '10 each', restSeconds: 30),
      PreMadeExercise(name: 'Mountain Climbers', sets: 3, reps: '30s', restSeconds: 30),
    ],
  );

  static final _cardioHiit = PreMadeRoutine(
    id: 'hiit',
    name: 'HIIT Cardio',
    description: 'High intensity interval training',
    category: RoutineCategory.specialty,
    difficulty: RoutineDifficulty.intermediate,
    estimatedMinutes: 25,
    targetMuscles: [MuscleGroup.cardio, MuscleGroup.fullBody],
    exercises: [
      PreMadeExercise(name: 'Jumping Jacks', sets: 1, reps: '60s', restSeconds: 15),
      PreMadeExercise(name: 'Burpees', sets: 4, reps: '10', restSeconds: 30),
      PreMadeExercise(name: 'Mountain Climbers', sets: 4, reps: '30s', restSeconds: 20),
      PreMadeExercise(name: 'Jump Squats', sets: 4, reps: '15', restSeconds: 30),
      PreMadeExercise(name: 'High Knees', sets: 4, reps: '30s', restSeconds: 20),
      PreMadeExercise(name: 'Box Jumps', sets: 3, reps: '12', restSeconds: 45),
    ],
  );

  static final _beginnerFullBody = PreMadeRoutine(
    id: 'beginner_fb',
    name: 'Beginner Full Body',
    description: 'Perfect starting point for gym beginners',
    category: RoutineCategory.beginner,
    difficulty: RoutineDifficulty.beginner,
    estimatedMinutes: 40,
    targetMuscles: [MuscleGroup.fullBody],
    exercises: [
      PreMadeExercise(name: 'Goblet Squats', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Dumbbell Bench Press', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Lat Pulldown', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Dumbbell Shoulder Press', sets: 3, reps: '12', restSeconds: 60),
      PreMadeExercise(name: 'Leg Press', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Plank', sets: 3, reps: '30s', restSeconds: 45),
    ],
  );

  static final _beginnerUpperLower = PreMadeRoutine(
    id: 'beginner_ul',
    name: 'Beginner Upper/Lower',
    description: 'Simple upper body workout for beginners',
    category: RoutineCategory.beginner,
    difficulty: RoutineDifficulty.beginner,
    estimatedMinutes: 35,
    targetMuscles: [MuscleGroup.chest, MuscleGroup.back, MuscleGroup.shoulders],
    exercises: [
      PreMadeExercise(name: 'Machine Chest Press', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Seated Cable Rows', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Machine Shoulder Press', sets: 3, reps: '12', restSeconds: 60),
      PreMadeExercise(name: 'Lat Pulldown', sets: 3, reps: '12', restSeconds: 90),
      PreMadeExercise(name: 'Bicep Curl Machine', sets: 2, reps: '15', restSeconds: 45),
      PreMadeExercise(name: 'Tricep Pushdowns', sets: 2, reps: '15', restSeconds: 45),
    ],
  );

  /// Get routines by category
  static List<PreMadeRoutine> getByCategory(RoutineCategory category) {
    return routines.where((r) => r.category == category).toList();
  }

  /// Get routines by difficulty
  static List<PreMadeRoutine> getByDifficulty(RoutineDifficulty difficulty) {
    return routines.where((r) => r.difficulty == difficulty).toList();
  }

  /// Get routines targeting specific muscle
  static List<PreMadeRoutine> getByTargetMuscle(MuscleGroup muscle) {
    return routines.where((r) => r.targetMuscles.contains(muscle)).toList();
  }
}

/// Category of routine/program
enum RoutineCategory {
  pushPullLegs('Push/Pull/Legs', 'Classic 3-day split'),
  upperLower('Upper/Lower', '4-day split'),
  fullBody('Full Body', 'Train everything each session'),
  bodyPart('Body Part Split', 'Focus on specific muscles'),
  specialty('Specialty', 'Core, cardio, and more'),
  beginner('Beginner', 'New to the gym');

  final String displayName;
  final String description;
  const RoutineCategory(this.displayName, this.description);
}

/// Difficulty level
enum RoutineDifficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  final String displayName;
  const RoutineDifficulty(this.displayName);
}

/// A pre-made routine from the library
class PreMadeRoutine {
  final String id;
  final String name;
  final String description;
  final RoutineCategory category;
  final RoutineDifficulty difficulty;
  final int estimatedMinutes;
  final List<MuscleGroup> targetMuscles;
  final List<PreMadeExercise> exercises;

  const PreMadeRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.estimatedMinutes,
    required this.targetMuscles,
    required this.exercises,
  });

  /// Convert to a WorkoutTemplate for the user
  WorkoutTemplate toTemplate(String userId) {
    return WorkoutTemplate(
      id: '',
      userId: userId,
      name: name,
      exercises: exercises.map((e) => TemplateExercise(
        name: e.name,
        targetSets: e.sets,
        targetReps: e.reps,
        restSeconds: e.restSeconds,
      )).toList(),
      estimatedMinutes: estimatedMinutes,
      targetMuscles: targetMuscles,
      createdAt: DateTime.now(),
    );
  }
}

/// An exercise within a pre-made routine
class PreMadeExercise {
  final String name;
  final int sets;
  final String reps; // Can be "8-10", "AMRAP", "30s", etc.
  final int restSeconds;

  const PreMadeExercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });
}
