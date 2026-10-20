import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum QuestStatus { active, completed, failed, abandoned }

enum QuestDifficulty { easy, medium, hard, epic, legendary }

class Quest extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final QuestDifficulty difficulty;
  final QuestStatus status;
  final List<SubTask> subtasks;
  final Map<String, int> statRewards; // stat name -> xp amount
  final int xpReward;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? iconName;

  const Quest({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.difficulty = QuestDifficulty.medium,
    this.status = QuestStatus.active,
    this.subtasks = const [],
    this.statRewards = const {},
    this.xpReward = 50,
    this.deadline,
    required this.createdAt,
    this.completedAt,
    this.iconName,
  });

  factory Quest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quest(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      difficulty: QuestDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => QuestDifficulty.medium,
      ),
      status: QuestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => QuestStatus.active,
      ),
      subtasks: (data['subtasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      statRewards: Map<String, int>.from(data['statRewards'] ?? {}),
      xpReward: data['xpReward'] ?? 50,
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      iconName: data['iconName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'difficulty': difficulty.name,
      'status': status.name,
      'subtasks': subtasks.map((e) => e.toMap()).toList(),
      'statRewards': statRewards,
      'xpReward': xpReward,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'iconName': iconName,
    };
  }

  double get progress {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;

  bool get isOverdue {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline!) && status == QuestStatus.active;
  }

  int get totalXpReward {
    int total = xpReward;
    for (var reward in statRewards.values) {
      total += reward;
    }
    return total;
  }

  int get difficultyMultiplier {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 1;
      case QuestDifficulty.medium:
        return 2;
      case QuestDifficulty.hard:
        return 3;
      case QuestDifficulty.epic:
        return 5;
      case QuestDifficulty.legendary:
        return 10;
    }
  }

  Quest copyWith({
    String? title,
    String? description,
    QuestDifficulty? difficulty,
    QuestStatus? status,
    List<SubTask>? subtasks,
    Map<String, int>? statRewards,
    int? xpReward,
    DateTime? deadline,
    DateTime? completedAt,
    String? iconName,
  }) {
    return Quest(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      subtasks: subtasks ?? this.subtasks,
      statRewards: statRewards ?? this.statRewards,
      xpReward: xpReward ?? this.xpReward,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      iconName: iconName ?? this.iconName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        difficulty,
        status,
        subtasks,
        statRewards,
        xpReward,
        deadline,
        createdAt,
        completedAt,
        iconName,
      ];
}

class SubTask extends Equatable {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;

  const SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
  });

  factory SubTask.fromMap(Map<String, dynamic> map) {
    return SubTask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  SubTask copyWith({
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return SubTask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted, completedAt];
}
