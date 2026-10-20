import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Predefined project colors
class ProjectColors {
  static const List<Color> all = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF8B5CF6), // Violet
    Color(0xFFEC4899), // Pink
    Color(0xFFF43F5E), // Rose
    Color(0xFFEF4444), // Red
    Color(0xFFF97316), // Orange
    Color(0xFFEAB308), // Yellow
    Color(0xFF22C55E), // Green
    Color(0xFF10B981), // Emerald
    Color(0xFF14B8A6), // Teal
    Color(0xFF06B6D4), // Cyan
    Color(0xFF0EA5E9), // Sky
    Color(0xFF3B82F6), // Blue
    Color(0xFF6B7280), // Gray
  ];

  static Color fromHex(String hex) {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// Represents a task project/category for grouping related tasks
class TaskProject extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final Color color;
  final String? icon; // Icon name or emoji
  final DateTime createdAt;
  final bool isArchived;
  final int sortOrder;

  const TaskProject({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.color = const Color(0xFF6366F1),
    this.icon,
    required this.createdAt,
    this.isArchived = false,
    this.sortOrder = 0,
  });

  factory TaskProject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskProject(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      color: ProjectColors.fromHex(data['color'] ?? '#6366F1'),
      icon: data['icon'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] ?? false,
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'color': ProjectColors.toHex(color),
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'isArchived': isArchived,
      'sortOrder': sortOrder,
    };
  }

  TaskProject copyWith({
    String? name,
    String? description,
    Color? color,
    String? icon,
    bool? isArchived,
    int? sortOrder,
  }) {
    return TaskProject(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        color,
        icon,
        createdAt,
        isArchived,
        sortOrder,
      ];
}
