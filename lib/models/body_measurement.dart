import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class BodyMeasurement extends Equatable {
  final String id;
  final String userId;
  final DateTime date;

  // Basic metrics
  final double? weight; // in kg or lbs based on user preference
  final double? bodyFat; // percentage

  // Circumference measurements (in cm or inches)
  final double? neck;
  final double? shoulders;
  final double? chest;
  final double? leftBicep;
  final double? rightBicep;
  final double? leftForearm;
  final double? rightForearm;
  final double? waist;
  final double? hips;
  final double? leftThigh;
  final double? rightThigh;
  final double? leftCalf;
  final double? rightCalf;

  // Optional note
  final String? notes;

  // Created timestamp
  final DateTime createdAt;

  const BodyMeasurement({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.bodyFat,
    this.neck,
    this.shoulders,
    this.chest,
    this.leftBicep,
    this.rightBicep,
    this.leftForearm,
    this.rightForearm,
    this.waist,
    this.hips,
    this.leftThigh,
    this.rightThigh,
    this.leftCalf,
    this.rightCalf,
    this.notes,
    required this.createdAt,
  });

  factory BodyMeasurement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BodyMeasurement(
      id: doc.id,
      userId: data['userId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weight: (data['weight'] as num?)?.toDouble(),
      bodyFat: (data['bodyFat'] as num?)?.toDouble(),
      neck: (data['neck'] as num?)?.toDouble(),
      shoulders: (data['shoulders'] as num?)?.toDouble(),
      chest: (data['chest'] as num?)?.toDouble(),
      leftBicep: (data['leftBicep'] as num?)?.toDouble(),
      rightBicep: (data['rightBicep'] as num?)?.toDouble(),
      leftForearm: (data['leftForearm'] as num?)?.toDouble(),
      rightForearm: (data['rightForearm'] as num?)?.toDouble(),
      waist: (data['waist'] as num?)?.toDouble(),
      hips: (data['hips'] as num?)?.toDouble(),
      leftThigh: (data['leftThigh'] as num?)?.toDouble(),
      rightThigh: (data['rightThigh'] as num?)?.toDouble(),
      leftCalf: (data['leftCalf'] as num?)?.toDouble(),
      rightCalf: (data['rightCalf'] as num?)?.toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'bodyFat': bodyFat,
      'neck': neck,
      'shoulders': shoulders,
      'chest': chest,
      'leftBicep': leftBicep,
      'rightBicep': rightBicep,
      'leftForearm': leftForearm,
      'rightForearm': rightForearm,
      'waist': waist,
      'hips': hips,
      'leftThigh': leftThigh,
      'rightThigh': rightThigh,
      'leftCalf': leftCalf,
      'rightCalf': rightCalf,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Check if any measurement exists
  bool get hasAnyMeasurement =>
      weight != null ||
      bodyFat != null ||
      neck != null ||
      shoulders != null ||
      chest != null ||
      leftBicep != null ||
      rightBicep != null ||
      leftForearm != null ||
      rightForearm != null ||
      waist != null ||
      hips != null ||
      leftThigh != null ||
      rightThigh != null ||
      leftCalf != null ||
      rightCalf != null;

  // Get average of left/right measurements
  double? get averageBicep {
    if (leftBicep == null && rightBicep == null) return null;
    if (leftBicep == null) return rightBicep;
    if (rightBicep == null) return leftBicep;
    return (leftBicep! + rightBicep!) / 2;
  }

  double? get averageForearm {
    if (leftForearm == null && rightForearm == null) return null;
    if (leftForearm == null) return rightForearm;
    if (rightForearm == null) return leftForearm;
    return (leftForearm! + rightForearm!) / 2;
  }

  double? get averageThigh {
    if (leftThigh == null && rightThigh == null) return null;
    if (leftThigh == null) return rightThigh;
    if (rightThigh == null) return leftThigh;
    return (leftThigh! + rightThigh!) / 2;
  }

  double? get averageCalf {
    if (leftCalf == null && rightCalf == null) return null;
    if (leftCalf == null) return rightCalf;
    if (rightCalf == null) return leftCalf;
    return (leftCalf! + rightCalf!) / 2;
  }

  BodyMeasurement copyWith({
    double? weight,
    double? bodyFat,
    double? neck,
    double? shoulders,
    double? chest,
    double? leftBicep,
    double? rightBicep,
    double? leftForearm,
    double? rightForearm,
    double? waist,
    double? hips,
    double? leftThigh,
    double? rightThigh,
    double? leftCalf,
    double? rightCalf,
    String? notes,
  }) {
    return BodyMeasurement(
      id: id,
      userId: userId,
      date: date,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      neck: neck ?? this.neck,
      shoulders: shoulders ?? this.shoulders,
      chest: chest ?? this.chest,
      leftBicep: leftBicep ?? this.leftBicep,
      rightBicep: rightBicep ?? this.rightBicep,
      leftForearm: leftForearm ?? this.leftForearm,
      rightForearm: rightForearm ?? this.rightForearm,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      leftThigh: leftThigh ?? this.leftThigh,
      rightThigh: rightThigh ?? this.rightThigh,
      leftCalf: leftCalf ?? this.leftCalf,
      rightCalf: rightCalf ?? this.rightCalf,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        weight,
        bodyFat,
        neck,
        shoulders,
        chest,
        leftBicep,
        rightBicep,
        leftForearm,
        rightForearm,
        waist,
        hips,
        leftThigh,
        rightThigh,
        leftCalf,
        rightCalf,
        notes,
        createdAt,
      ];
}

// Measurement type enum for UI
enum MeasurementType {
  weight('Weight', 'kg', Icons.scale),
  bodyFat('Body Fat', '%', Icons.percent),
  neck('Neck', 'cm', Icons.face),
  shoulders('Shoulders', 'cm', Icons.accessibility),
  chest('Chest', 'cm', Icons.favorite),
  biceps('Biceps', 'cm', Icons.fitness_center),
  forearms('Forearms', 'cm', Icons.front_hand),
  waist('Waist', 'cm', Icons.straighten),
  hips('Hips', 'cm', Icons.accessibility_new),
  thighs('Thighs', 'cm', Icons.directions_walk),
  calves('Calves', 'cm', Icons.sports_soccer);

  final String displayName;
  final String unit;
  final IconData icon;

  const MeasurementType(this.displayName, this.unit, this.icon);
}
