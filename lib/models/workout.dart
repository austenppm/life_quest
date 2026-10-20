import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ExerciseType { strength, cardio, flexibility, sport }

/// Muscle groups for categorizing exercises
enum MuscleGroup {
  chest('Chest', '💪'),
  back('Back', '🔙'),
  shoulders('Shoulders', '🎯'),
  biceps('Biceps', '💪'),
  triceps('Triceps', '💪'),
  forearms('Forearms', '🤚'),
  abs('Abs', '🔥'),
  obliques('Obliques', '🔥'),
  lowerBack('Lower Back', '🔙'),
  quads('Quads', '🦵'),
  hamstrings('Hamstrings', '🦵'),
  glutes('Glutes', '🍑'),
  calves('Calves', '🦵'),
  fullBody('Full Body', '🏋️'),
  cardio('Cardio', '❤️');

  final String displayName;
  final String emoji;
  const MuscleGroup(this.displayName, this.emoji);
}

/// Equipment types for exercises
enum Equipment {
  barbell('Barbell'),
  dumbbell('Dumbbell'),
  kettlebell('Kettlebell'),
  machine('Machine'),
  cable('Cable'),
  bodyweight('Bodyweight'),
  bands('Resistance Bands'),
  other('Other');

  final String displayName;
  const Equipment(this.displayName);
}

/// Set types for workout logging
enum SetType {
  warmup('Warmup', 'W'),
  normal('Working', ''),
  dropSet('Drop Set', 'D'),
  failure('To Failure', 'F'),
  superset('Superset', 'S');

  final String displayName;
  final String badge;
  const SetType(this.displayName, this.badge);
}

class Workout extends Equatable {
  final String id;
  final String userId;
  final String? name;
  final DateTime date;
  final int durationMinutes;
  final List<Exercise> exercises;
  final String? notes;
  final int xpEarned;
  final Map<String, int> statsGained;
  final int caloriesBurned;

  const Workout({
    required this.id,
    required this.userId,
    this.name,
    required this.date,
    this.durationMinutes = 0,
    this.exercises = const [],
    this.notes,
    this.xpEarned = 0,
    this.statsGained = const {},
    this.caloriesBurned = 0,
  });

  factory Workout.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Workout(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: data['durationMinutes'] ?? 0,
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) => Exercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: data['notes'],
      xpEarned: data['xpEarned'] ?? 0,
      statsGained: Map<String, int>.from(data['statsGained'] ?? {}),
      caloriesBurned: data['caloriesBurned'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'notes': notes,
      'xpEarned': xpEarned,
      'statsGained': statsGained,
      'caloriesBurned': caloriesBurned,
    };
  }

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  int get totalReps =>
      exercises.fold(0, (sum, e) => sum + e.sets.fold(0, (s, set) => s + set.reps));

  double get totalWeight => exercises.fold(
      0.0, (sum, e) => sum + e.sets.fold(0.0, (s, set) => s + (set.weight ?? 0)));

  Workout copyWith({
    String? name,
    DateTime? date,
    int? durationMinutes,
    List<Exercise>? exercises,
    String? notes,
    int? xpEarned,
    Map<String, int>? statsGained,
    int? caloriesBurned,
  }) {
    return Workout(
      id: id,
      userId: userId,
      name: name ?? this.name,
      date: date ?? this.date,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      xpEarned: xpEarned ?? this.xpEarned,
      statsGained: statsGained ?? this.statsGained,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        date,
        durationMinutes,
        exercises,
        notes,
        xpEarned,
        statsGained,
        caloriesBurned,
      ];
}

class Exercise extends Equatable {
  final String id;
  final String name;
  final ExerciseType type;
  final List<ExerciseSet> sets;
  final String? notes;
  final String? muscleGroup;

  const Exercise({
    required this.id,
    required this.name,
    this.type = ExerciseType.strength,
    this.sets = const [],
    this.notes,
    this.muscleGroup,
  });

  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: ExerciseType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ExerciseType.strength,
      ),
      sets: (map['sets'] as List<dynamic>?)
              ?.map((e) => ExerciseSet.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      notes: map['notes'],
      muscleGroup: map['muscleGroup'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'sets': sets.map((e) => e.toMap()).toList(),
      'notes': notes,
      'muscleGroup': muscleGroup,
    };
  }

  Exercise copyWith({
    String? name,
    ExerciseType? type,
    List<ExerciseSet>? sets,
    String? notes,
    String? muscleGroup,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }

  @override
  List<Object?> get props => [id, name, type, sets, notes, muscleGroup];
}

class ExerciseSet extends Equatable {
  final int reps;
  final double? weight;
  final int? durationSeconds; // For timed exercises
  final double? distance; // For cardio
  final bool isCompleted;
  final SetType setType;
  final int? rpe; // Rate of Perceived Exertion (1-10)
  final String? notes;

  const ExerciseSet({
    this.reps = 0,
    this.weight,
    this.durationSeconds,
    this.distance,
    this.isCompleted = false,
    this.setType = SetType.normal,
    this.rpe,
    this.notes,
  });

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      reps: map['reps'] ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
      durationSeconds: map['durationSeconds'],
      distance: (map['distance'] as num?)?.toDouble(),
      isCompleted: map['isCompleted'] ?? false,
      setType: SetType.values.firstWhere(
        (e) => e.name == map['setType'],
        orElse: () => SetType.normal,
      ),
      rpe: map['rpe'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      'durationSeconds': durationSeconds,
      'distance': distance,
      'isCompleted': isCompleted,
      'setType': setType.name,
      'rpe': rpe,
      'notes': notes,
    };
  }

  /// Calculate volume for this set (weight * reps)
  double get volume => (weight ?? 0) * reps;

  ExerciseSet copyWith({
    int? reps,
    double? weight,
    int? durationSeconds,
    double? distance,
    bool? isCompleted,
    SetType? setType,
    int? rpe,
    String? notes,
  }) {
    return ExerciseSet(
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distance: distance ?? this.distance,
      isCompleted: isCompleted ?? this.isCompleted,
      setType: setType ?? this.setType,
      rpe: rpe ?? this.rpe,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props =>
      [reps, weight, durationSeconds, distance, isCompleted, setType, rpe, notes];
}

/// Exercise definition from the library (not a logged exercise)
class ExerciseDefinition extends Equatable {
  final String id;
  final String name;
  final MuscleGroup primaryMuscle;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;
  final ExerciseType type;
  final String? instructions;
  final String? videoUrl;
  final bool isCustom;

  const ExerciseDefinition({
    required this.id,
    required this.name,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.equipment = Equipment.bodyweight,
    this.type = ExerciseType.strength,
    this.instructions,
    this.videoUrl,
    this.isCustom = false,
  });

  @override
  List<Object?> get props => [
    id, name, primaryMuscle, secondaryMuscles, equipment, type,
    instructions, videoUrl, isCustom,
  ];
}

/// Workout template for quick-start routines
class WorkoutTemplate extends Equatable {
  final String id;
  final String userId;
  final String name;
  final List<TemplateExercise> exercises;
  final int estimatedMinutes;
  final List<MuscleGroup> targetMuscles;
  final DateTime createdAt;
  final int timesUsed;

  const WorkoutTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.exercises = const [],
    this.estimatedMinutes = 60,
    this.targetMuscles = const [],
    required this.createdAt,
    this.timesUsed = 0,
  });

  factory WorkoutTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkoutTemplate(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      exercises: (data['exercises'] as List<dynamic>?)
              ?.map((e) => TemplateExercise.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedMinutes: data['estimatedMinutes'] ?? 60,
      targetMuscles: (data['targetMuscles'] as List<dynamic>?)
              ?.map((e) => MuscleGroup.values.firstWhere(
                    (m) => m.name == e,
                    orElse: () => MuscleGroup.fullBody,
                  ))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timesUsed: data['timesUsed'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'targetMuscles': targetMuscles.map((m) => m.name).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'timesUsed': timesUsed,
    };
  }

  @override
  List<Object?> get props => [
    id, userId, name, exercises, estimatedMinutes, targetMuscles, createdAt, timesUsed,
  ];
}

/// Exercise in a template (with target sets/reps)
class TemplateExercise extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final int restSeconds;

  const TemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.targetSets = 3,
    this.targetReps = 10,
    this.restSeconds = 90,
  });

  factory TemplateExercise.fromMap(Map<String, dynamic> map) {
    return TemplateExercise(
      exerciseId: map['exerciseId'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      targetSets: map['targetSets'] ?? 3,
      targetReps: map['targetReps'] ?? 10,
      restSeconds: map['restSeconds'] ?? 90,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'restSeconds': restSeconds,
    };
  }

  @override
  List<Object?> get props => [exerciseId, exerciseName, targetSets, targetReps, restSeconds];
}
