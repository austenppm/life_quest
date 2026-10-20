import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TaskType { daily, oneTime }

enum TaskFrequency { daily, weekdays, weekends, custom }

enum TaskPriority {
  low('Low', 1),
  medium('Medium', 2),
  high('High', 3),
  urgent('Urgent', 4);

  final String displayName;
  final int value;

  const TaskPriority(this.displayName, this.value);

  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

enum TaskStatus {
  todo('To Do'),
  inProgress('In Progress'),
  done('Done');

  final String displayName;

  const TaskStatus(this.displayName);
}

class Subtask extends Equatable {
  final String id;
  final String title;
  final bool isCompleted;

  const Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  factory Subtask.fromMap(Map<String, dynamic> map) {
    return Subtask(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  Subtask copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return Subtask(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted];
}

class Task extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final TaskType type;
  final TaskFrequency frequency;
  final List<int> customDays; // 1-7 for Mon-Sun
  
  // Multi-stat support: stat name -> XP amount for that stat
  final Map<String, int> statRewards;
  // Legacy single stat (for backward compatibility)
  final String stat;
  
  final int xpReward;
  final int currentStreak;
  final int bestStreak;
  final List<DateTime> completedDates;
  final DateTime? dueDate; // For one-time tasks or calendar events
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? reminderTime;
  final int sortOrder;
  
  // Calendar integration
  final bool isFromCalendar;
  final String? calendarEventId;
  
  // AI analysis
  final String? aiReasoning;
  final List<String> tags;

  // Enhanced task features
  final TaskPriority priority;
  final TaskStatus status;
  final List<Subtask> subtasks;
  final int? estimatedDuration; // in minutes
  final String? projectId;
  final String? location;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    this.frequency = TaskFrequency.daily,
    this.customDays = const [],
    this.statRewards = const {},
    this.stat = 'discipline',
    this.xpReward = 10,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completedDates = const [],
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.reminderTime,
    this.sortOrder = 0,
    this.isFromCalendar = false,
    this.calendarEventId,
    this.aiReasoning,
    this.tags = const [],
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.subtasks = const [],
    this.estimatedDuration,
    this.projectId,
    this.location,
  });

  // Legacy getter for backward compatibility
  String get statAffected => stat;
  DateTime? get deadline => dueDate;

  // Get primary stat (highest XP reward or legacy stat)
  String get primaryStat {
    if (statRewards.isEmpty) return stat;
    return statRewards.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Get all stats affected
  List<String> get allStatsAffected {
    if (statRewards.isEmpty) return [stat];
    return statRewards.keys.toList();
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse stat rewards map
    Map<String, int> rewards = {};
    if (data['statRewards'] != null) {
      (data['statRewards'] as Map<String, dynamic>).forEach((key, value) {
        rewards[key] = (value as num).toInt();
      });
    }
    
    return Task(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      type: TaskType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TaskType.daily,
      ),
      frequency: TaskFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => TaskFrequency.daily,
      ),
      customDays: List<int>.from(data['customDays'] ?? []),
      statRewards: rewards,
      stat: data['stat'] ?? data['statAffected'] ?? 'discipline',
      xpReward: data['xpReward'] ?? 10,
      currentStreak: data['currentStreak'] ?? 0,
      bestStreak: data['bestStreak'] ?? 0,
      completedDates: (data['completedDates'] as List<dynamic>?)
              ?.map((e) => (e as Timestamp).toDate())
              .toList() ??
          [],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? 
               (data['deadline'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reminderTime: (data['reminderTime'] as Timestamp?)?.toDate(),
      sortOrder: data['sortOrder'] ?? 0,
      isFromCalendar: data['isFromCalendar'] ?? false,
      calendarEventId: data['calendarEventId'],
      aiReasoning: data['aiReasoning'],
      tags: List<String>.from(data['tags'] ?? []),
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => TaskStatus.todo,
      ),
      subtasks: (data['subtasks'] as List<dynamic>?)
              ?.map((s) => Subtask.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      estimatedDuration: data['estimatedDuration'],
      projectId: data['projectId'],
      location: data['location'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.name,
      'frequency': frequency.name,
      'customDays': customDays,
      'statRewards': statRewards,
      'stat': stat,
      'xpReward': xpReward,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'completedDates': completedDates.map((e) => Timestamp.fromDate(e)).toList(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'reminderTime': reminderTime != null ? Timestamp.fromDate(reminderTime!) : null,
      'sortOrder': sortOrder,
      'isFromCalendar': isFromCalendar,
      'calendarEventId': calendarEventId,
      'aiReasoning': aiReasoning,
      'tags': tags,
      'priority': priority.name,
      'status': status.name,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'estimatedDuration': estimatedDuration,
      'projectId': projectId,
      'location': location,
    };
  }

  bool isCompletedToday() {
    if (completedDates.isEmpty) return false;
    final today = DateTime.now();
    return completedDates.any((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);
  }

  bool shouldShowToday() {
    if (type == TaskType.oneTime) {
      return !isCompleted;
    }

    final today = DateTime.now().weekday; // 1 = Monday, 7 = Sunday
    switch (frequency) {
      case TaskFrequency.daily:
        return true;
      case TaskFrequency.weekdays:
        return today >= 1 && today <= 5;
      case TaskFrequency.weekends:
        return today == 6 || today == 7;
      case TaskFrequency.custom:
        return customDays.contains(today);
    }
  }

  // Subtask helpers
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;
  int get totalSubtasksCount => subtasks.length;
  double get subtasksProgress => totalSubtasksCount > 0
      ? completedSubtasksCount / totalSubtasksCount
      : 0.0;
  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get allSubtasksCompleted => hasSubtasks && completedSubtasksCount == totalSubtasksCount;

  // Priority helpers
  bool get isHighPriority => priority == TaskPriority.high || priority == TaskPriority.urgent;
  bool get isOverdue => dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  // Estimated duration formatted
  String get formattedDuration {
    if (estimatedDuration == null) return '';
    if (estimatedDuration! < 60) return '${estimatedDuration}m';
    final hours = estimatedDuration! ~/ 60;
    final mins = estimatedDuration! % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  Task copyWith({
    String? title,
    String? description,
    TaskType? type,
    TaskFrequency? frequency,
    List<int>? customDays,
    Map<String, int>? statRewards,
    String? stat,
    int? xpReward,
    int? currentStreak,
    int? bestStreak,
    List<DateTime>? completedDates,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? reminderTime,
    int? sortOrder,
    bool? isFromCalendar,
    String? calendarEventId,
    String? aiReasoning,
    List<String>? tags,
    TaskPriority? priority,
    TaskStatus? status,
    List<Subtask>? subtasks,
    int? estimatedDuration,
    String? projectId,
    String? location,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      customDays: customDays ?? this.customDays,
      statRewards: statRewards ?? this.statRewards,
      stat: stat ?? this.stat,
      xpReward: xpReward ?? this.xpReward,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      completedDates: completedDates ?? this.completedDates,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      reminderTime: reminderTime ?? this.reminderTime,
      sortOrder: sortOrder ?? this.sortOrder,
      isFromCalendar: isFromCalendar ?? this.isFromCalendar,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      subtasks: subtasks ?? this.subtasks,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      projectId: projectId ?? this.projectId,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, title, description, type, frequency, customDays,
        statRewards, stat, xpReward, currentStreak, bestStreak,
        completedDates, dueDate, isCompleted, createdAt, reminderTime,
        sortOrder, isFromCalendar, calendarEventId, aiReasoning, tags,
        priority, status, subtasks, estimatedDuration, projectId, location,
      ];
}
