import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class StudySession extends Equatable {
  final String id;
  final String userId;
  final String subject;
  final String? topic;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String? notes;
  final int xpEarned;
  final int focusScore; // 1-100
  final List<String> tags;
  final bool isActive;

  const StudySession({
    required this.id,
    required this.userId,
    required this.subject,
    this.topic,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.notes,
    this.xpEarned = 0,
    this.focusScore = 100,
    this.tags = const [],
    this.isActive = false,
  });

  factory StudySession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudySession(
      id: doc.id,
      userId: data['userId'] ?? '',
      subject: data['subject'] ?? '',
      topic: data['topic'],
      startTime:
          (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
      notes: data['notes'],
      xpEarned: data['xpEarned'] ?? 0,
      focusScore: data['focusScore'] ?? 100,
      tags: List<String>.from(data['tags'] ?? []),
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subject': subject,
      'topic': topic,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'notes': notes,
      'xpEarned': xpEarned,
      'focusScore': focusScore,
      'tags': tags,
      'isActive': isActive,
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

  StudySession copyWith({
    String? subject,
    String? topic,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? notes,
    int? xpEarned,
    int? focusScore,
    List<String>? tags,
    bool? isActive,
  }) {
    return StudySession(
      id: id,
      userId: userId,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      xpEarned: xpEarned ?? this.xpEarned,
      focusScore: focusScore ?? this.focusScore,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        subject,
        topic,
        startTime,
        endTime,
        durationMinutes,
        notes,
        xpEarned,
        focusScore,
        tags,
        isActive,
      ];
}

class Subject extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? color;
  final String? iconName;
  final int totalMinutes;
  final int totalSessions;

  const Subject({
    required this.id,
    required this.userId,
    required this.name,
    this.color,
    this.iconName,
    this.totalMinutes = 0,
    this.totalSessions = 0,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      color: data['color'],
      iconName: data['iconName'],
      totalMinutes: data['totalMinutes'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'color': color,
      'iconName': iconName,
      'totalMinutes': totalMinutes,
      'totalSessions': totalSessions,
    };
  }

  @override
  List<Object?> get props =>
      [id, userId, name, color, iconName, totalMinutes, totalSessions];
}
