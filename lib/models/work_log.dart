import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class WorkLog extends Equatable {
  final String id;
  final String userId;
  final String? projectId;
  final String? projectName;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String? description;
  final List<String> tasksCompleted;
  final int xpEarned;
  final bool isActive;
  final List<String> tags;

  const WorkLog({
    required this.id,
    required this.userId,
    this.projectId,
    this.projectName,
    required this.date,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.description,
    this.tasksCompleted = const [],
    this.xpEarned = 0,
    this.isActive = false,
    this.tags = const [],
  });

  factory WorkLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WorkLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      projectId: data['projectId'],
      projectName: data['projectName'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
      description: data['description'],
      tasksCompleted: List<String>.from(data['tasksCompleted'] ?? []),
      xpEarned: data['xpEarned'] ?? 0,
      isActive: data['isActive'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'projectId': projectId,
      'projectName': projectName,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'description': description,
      'tasksCompleted': tasksCompleted,
      'xpEarned': xpEarned,
      'isActive': isActive,
      'tags': tags,
    };
  }

  int get calculatedDuration {
    if (endTime != null) {
      return endTime!.difference(startTime).inMinutes;
    }
    if (isActive) {
      return DateTime.now().difference(startTime).inMinutes;
    }
    return durationMinutes;
  }

  String get formattedDuration {
    final hours = calculatedDuration ~/ 60;
    final minutes = calculatedDuration % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  WorkLog copyWith({
    String? projectId,
    String? projectName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? description,
    List<String>? tasksCompleted,
    int? xpEarned,
    bool? isActive,
    List<String>? tags,
  }) {
    return WorkLog(
      id: id,
      userId: userId,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      description: description ?? this.description,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      xpEarned: xpEarned ?? this.xpEarned,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        projectId,
        projectName,
        date,
        startTime,
        endTime,
        durationMinutes,
        description,
        tasksCompleted,
        xpEarned,
        isActive,
        tags,
      ];
}

class Project extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? color;
  final int totalMinutes;
  final bool isActive;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color,
    this.totalMinutes = 0,
    this.isActive = true,
    required this.createdAt,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      color: data['color'],
      totalMinutes: data['totalMinutes'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'color': color,
      'totalMinutes': totalMinutes,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  String get formattedTotalTime {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        color,
        totalMinutes,
        isActive,
        createdAt,
      ];
}
