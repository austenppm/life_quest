import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'task.dart';

/// A template for quickly creating tasks with predefined settings
class TaskTemplate extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;

  // Task configuration
  final TaskType taskType;
  final TaskFrequency frequency;
  final List<int> customDays;
  final String stat;
  final Map<String, int> statRewards;
  final int xpReward;
  final TaskPriority priority;
  final int? estimatedDuration;
  final List<String> defaultSubtasks;
  final List<String> tags;
  final String? projectId;

  // Template metadata
  final DateTime createdAt;
  final int timesUsed;
  final bool isFavorite;

  const TaskTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.taskType = TaskType.oneTime,
    this.frequency = TaskFrequency.daily,
    this.customDays = const [],
    this.stat = 'discipline',
    this.statRewards = const {},
    this.xpReward = 10,
    this.priority = TaskPriority.medium,
    this.estimatedDuration,
    this.defaultSubtasks = const [],
    this.tags = const [],
    this.projectId,
    required this.createdAt,
    this.timesUsed = 0,
    this.isFavorite = false,
  });

  factory TaskTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    Map<String, int> rewards = {};
    if (data['statRewards'] != null) {
      (data['statRewards'] as Map<String, dynamic>).forEach((key, value) {
        rewards[key] = (value as num).toInt();
      });
    }

    return TaskTemplate(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      taskType: TaskType.values.firstWhere(
        (e) => e.name == data['taskType'],
        orElse: () => TaskType.oneTime,
      ),
      frequency: TaskFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => TaskFrequency.daily,
      ),
      customDays: List<int>.from(data['customDays'] ?? []),
      stat: data['stat'] ?? 'discipline',
      statRewards: rewards,
      xpReward: data['xpReward'] ?? 10,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      estimatedDuration: data['estimatedDuration'],
      defaultSubtasks: List<String>.from(data['defaultSubtasks'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      projectId: data['projectId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timesUsed: data['timesUsed'] ?? 0,
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'taskType': taskType.name,
      'frequency': frequency.name,
      'customDays': customDays,
      'stat': stat,
      'statRewards': statRewards,
      'xpReward': xpReward,
      'priority': priority.name,
      'estimatedDuration': estimatedDuration,
      'defaultSubtasks': defaultSubtasks,
      'tags': tags,
      'projectId': projectId,
      'createdAt': Timestamp.fromDate(createdAt),
      'timesUsed': timesUsed,
      'isFavorite': isFavorite,
    };
  }

  /// Creates a new Task from this template
  Task toTask({
    required String taskId,
    String? customTitle,
    DateTime? dueDate,
    String? overrideProjectId,
  }) {
    return Task(
      id: taskId,
      userId: userId,
      title: customTitle ?? name,
      description: description,
      type: taskType,
      frequency: frequency,
      customDays: customDays,
      stat: stat,
      statRewards: statRewards.isEmpty ? {stat: xpReward} : statRewards,
      xpReward: xpReward,
      priority: priority,
      estimatedDuration: estimatedDuration,
      subtasks: defaultSubtasks
          .map((title) => Subtask(
                id: DateTime.now().millisecondsSinceEpoch.toString() + title.hashCode.toString(),
                title: title,
              ))
          .toList(),
      tags: tags,
      projectId: overrideProjectId ?? projectId,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
  }

  TaskTemplate copyWith({
    String? name,
    String? description,
    TaskType? taskType,
    TaskFrequency? frequency,
    List<int>? customDays,
    String? stat,
    Map<String, int>? statRewards,
    int? xpReward,
    TaskPriority? priority,
    int? estimatedDuration,
    List<String>? defaultSubtasks,
    List<String>? tags,
    String? projectId,
    int? timesUsed,
    bool? isFavorite,
  }) {
    return TaskTemplate(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      stat: stat ?? this.stat,
      statRewards: statRewards ?? this.statRewards,
      xpReward: xpReward ?? this.xpReward,
      priority: priority ?? this.priority,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      defaultSubtasks: defaultSubtasks ?? this.defaultSubtasks,
      tags: tags ?? this.tags,
      projectId: projectId ?? this.projectId,
      createdAt: createdAt,
      timesUsed: timesUsed ?? this.timesUsed,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        taskType,
        frequency,
        customDays,
        stat,
        statRewards,
        xpReward,
        priority,
        estimatedDuration,
        defaultSubtasks,
        tags,
        projectId,
        createdAt,
        timesUsed,
        isFavorite,
      ];
}
