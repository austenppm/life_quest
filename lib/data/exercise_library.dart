import '../models/workout.dart';

/// Library of predefined exercises
class ExerciseLibrary {
  static const List<ExerciseDefinition> exercises = [
    // CHEST
    ExerciseDefinition(
      id: 'bench_press',
      name: 'Bench Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.barbell,
      instructions: 'Lie on bench, grip bar slightly wider than shoulders, lower to chest, press up.',
    ),
    ExerciseDefinition(
      id: 'incline_bench_press',
      name: 'Incline Bench Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.shoulders, MuscleGroup.triceps],
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'dumbbell_press',
      name: 'Dumbbell Press',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'dumbbell_fly',
      name: 'Dumbbell Fly',
      primaryMuscle: MuscleGroup.chest,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'push_ups',
      name: 'Push Ups',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps, MuscleGroup.shoulders],
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'cable_crossover',
      name: 'Cable Crossover',
      primaryMuscle: MuscleGroup.chest,
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 'chest_dips',
      name: 'Chest Dips',
      primaryMuscle: MuscleGroup.chest,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.bodyweight,
    ),

    // BACK
    ExerciseDefinition(
      id: 'deadlift',
      name: 'Deadlift',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.hamstrings, MuscleGroup.glutes, MuscleGroup.forearms],
      equipment: Equipment.barbell,
      instructions: 'Stand with feet hip-width, grip bar, keep back straight, lift by extending hips and knees.',
    ),
    ExerciseDefinition(
      id: 'pull_ups',
      name: 'Pull Ups',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'chin_ups',
      name: 'Chin Ups',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'barbell_row',
      name: 'Barbell Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps, MuscleGroup.forearms],
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'dumbbell_row',
      name: 'Dumbbell Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'lat_pulldown',
      name: 'Lat Pulldown',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 'seated_cable_row',
      name: 'Seated Cable Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 't_bar_row',
      name: 'T-Bar Row',
      primaryMuscle: MuscleGroup.back,
      secondaryMuscles: [MuscleGroup.biceps],
      equipment: Equipment.barbell,
    ),

    // SHOULDERS
    ExerciseDefinition(
      id: 'overhead_press',
      name: 'Overhead Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.barbell,
      instructions: 'Stand with feet shoulder-width, press bar overhead, lower to chin level.',
    ),
    ExerciseDefinition(
      id: 'dumbbell_shoulder_press',
      name: 'Dumbbell Shoulder Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'lateral_raise',
      name: 'Lateral Raise',
      primaryMuscle: MuscleGroup.shoulders,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'front_raise',
      name: 'Front Raise',
      primaryMuscle: MuscleGroup.shoulders,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'rear_delt_fly',
      name: 'Rear Delt Fly',
      primaryMuscle: MuscleGroup.shoulders,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'face_pulls',
      name: 'Face Pulls',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.back],
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 'arnold_press',
      name: 'Arnold Press',
      primaryMuscle: MuscleGroup.shoulders,
      secondaryMuscles: [MuscleGroup.triceps],
      equipment: Equipment.dumbbell,
    ),

    // BICEPS
    ExerciseDefinition(
      id: 'barbell_curl',
      name: 'Barbell Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'dumbbell_curl',
      name: 'Dumbbell Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'hammer_curl',
      name: 'Hammer Curl',
      primaryMuscle: MuscleGroup.biceps,
      secondaryMuscles: [MuscleGroup.forearms],
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'preacher_curl',
      name: 'Preacher Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'cable_curl',
      name: 'Cable Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 'concentration_curl',
      name: 'Concentration Curl',
      primaryMuscle: MuscleGroup.biceps,
      equipment: Equipment.dumbbell,
    ),

    // TRICEPS
    ExerciseDefinition(
      id: 'tricep_pushdown',
      name: 'Tricep Pushdown',
      primaryMuscle: MuscleGroup.triceps,
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 'skull_crushers',
      name: 'Skull Crushers',
      primaryMuscle: MuscleGroup.triceps,
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'overhead_tricep_extension',
      name: 'Overhead Tricep Extension',
      primaryMuscle: MuscleGroup.triceps,
      equipment: Equipment.dumbbell,
    ),
    ExerciseDefinition(
      id: 'tricep_dips',
      name: 'Tricep Dips',
      primaryMuscle: MuscleGroup.triceps,
      secondaryMuscles: [MuscleGroup.chest],
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'close_grip_bench_press',
      name: 'Close Grip Bench Press',
      primaryMuscle: MuscleGroup.triceps,
      secondaryMuscles: [MuscleGroup.chest],
      equipment: Equipment.barbell,
    ),

    // LEGS - QUADS
    ExerciseDefinition(
      id: 'squat',
      name: 'Squat',
      primaryMuscle: MuscleGroup.quads,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
      equipment: Equipment.barbell,
      instructions: 'Stand with bar on upper back, feet shoulder-width, squat down until thighs parallel, stand up.',
    ),
    ExerciseDefinition(
      id: 'front_squat',
      name: 'Front Squat',
      primaryMuscle: MuscleGroup.quads,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'leg_press',
      name: 'Leg Press',
      primaryMuscle: MuscleGroup.quads,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.hamstrings],
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'leg_extension',
      name: 'Leg Extension',
      primaryMuscle: MuscleGroup.quads,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'lunges',
      name: 'Lunges',
      primaryMuscle: MuscleGroup.quads,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'bulgarian_split_squat',
      name: 'Bulgarian Split Squat',
      primaryMuscle: MuscleGroup.quads,
      secondaryMuscles: [MuscleGroup.glutes],
      equipment: Equipment.dumbbell,
    ),

    // LEGS - HAMSTRINGS
    ExerciseDefinition(
      id: 'romanian_deadlift',
      name: 'Romanian Deadlift',
      primaryMuscle: MuscleGroup.hamstrings,
      secondaryMuscles: [MuscleGroup.glutes, MuscleGroup.lowerBack],
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'leg_curl',
      name: 'Leg Curl',
      primaryMuscle: MuscleGroup.hamstrings,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'good_mornings',
      name: 'Good Mornings',
      primaryMuscle: MuscleGroup.hamstrings,
      secondaryMuscles: [MuscleGroup.lowerBack],
      equipment: Equipment.barbell,
    ),

    // LEGS - GLUTES
    ExerciseDefinition(
      id: 'hip_thrust',
      name: 'Hip Thrust',
      primaryMuscle: MuscleGroup.glutes,
      secondaryMuscles: [MuscleGroup.hamstrings],
      equipment: Equipment.barbell,
    ),
    ExerciseDefinition(
      id: 'glute_bridge',
      name: 'Glute Bridge',
      primaryMuscle: MuscleGroup.glutes,
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'cable_kickback',
      name: 'Cable Kickback',
      primaryMuscle: MuscleGroup.glutes,
      equipment: Equipment.cable,
    ),

    // LEGS - CALVES
    ExerciseDefinition(
      id: 'standing_calf_raise',
      name: 'Standing Calf Raise',
      primaryMuscle: MuscleGroup.calves,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'seated_calf_raise',
      name: 'Seated Calf Raise',
      primaryMuscle: MuscleGroup.calves,
      equipment: Equipment.machine,
    ),

    // ABS
    ExerciseDefinition(
      id: 'crunches',
      name: 'Crunches',
      primaryMuscle: MuscleGroup.abs,
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'plank',
      name: 'Plank',
      primaryMuscle: MuscleGroup.abs,
      type: ExerciseType.strength,
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'leg_raises',
      name: 'Leg Raises',
      primaryMuscle: MuscleGroup.abs,
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'cable_crunch',
      name: 'Cable Crunch',
      primaryMuscle: MuscleGroup.abs,
      equipment: Equipment.cable,
    ),
    ExerciseDefinition(
      id: 'russian_twist',
      name: 'Russian Twist',
      primaryMuscle: MuscleGroup.obliques,
      equipment: Equipment.bodyweight,
    ),
    ExerciseDefinition(
      id: 'ab_wheel',
      name: 'Ab Wheel Rollout',
      primaryMuscle: MuscleGroup.abs,
      equipment: Equipment.other,
    ),

    // CARDIO
    ExerciseDefinition(
      id: 'treadmill',
      name: 'Treadmill',
      primaryMuscle: MuscleGroup.cardio,
      type: ExerciseType.cardio,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'stationary_bike',
      name: 'Stationary Bike',
      primaryMuscle: MuscleGroup.cardio,
      type: ExerciseType.cardio,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'rowing_machine',
      name: 'Rowing Machine',
      primaryMuscle: MuscleGroup.cardio,
      secondaryMuscles: [MuscleGroup.back],
      type: ExerciseType.cardio,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'elliptical',
      name: 'Elliptical',
      primaryMuscle: MuscleGroup.cardio,
      type: ExerciseType.cardio,
      equipment: Equipment.machine,
    ),
    ExerciseDefinition(
      id: 'jump_rope',
      name: 'Jump Rope',
      primaryMuscle: MuscleGroup.cardio,
      secondaryMuscles: [MuscleGroup.calves],
      type: ExerciseType.cardio,
      equipment: Equipment.other,
    ),
    ExerciseDefinition(
      id: 'burpees',
      name: 'Burpees',
      primaryMuscle: MuscleGroup.fullBody,
      type: ExerciseType.cardio,
      equipment: Equipment.bodyweight,
    ),
  ];

  /// Get exercises by muscle group
  static List<ExerciseDefinition> getByMuscle(MuscleGroup muscle) {
    return exercises.where((e) =>
      e.primaryMuscle == muscle || e.secondaryMuscles.contains(muscle)
    ).toList();
  }

  /// Get exercises by equipment type
  static List<ExerciseDefinition> getByEquipment(Equipment equipment) {
    return exercises.where((e) => e.equipment == equipment).toList();
  }

  /// Search exercises by name
  static List<ExerciseDefinition> search(String query) {
    final lowercaseQuery = query.toLowerCase();
    return exercises.where((e) =>
      e.name.toLowerCase().contains(lowercaseQuery) ||
      e.primaryMuscle.displayName.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Get exercise by ID
  static ExerciseDefinition? getById(String id) {
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get all muscle groups with exercise counts
  static Map<MuscleGroup, int> getMuscleGroupCounts() {
    final counts = <MuscleGroup, int>{};
    for (final muscle in MuscleGroup.values) {
      counts[muscle] = getByMuscle(muscle).length;
    }
    return counts;
  }
}
