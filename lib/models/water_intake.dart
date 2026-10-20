import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a single water intake log entry
class WaterIntake extends Equatable {
  final String id;
  final String userId;
  final DateTime timestamp;
  final double amount; // in ml
  final WaterContainerType containerType;
  final String? note;

  const WaterIntake({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.amount,
    this.containerType = WaterContainerType.glass,
    this.note,
  });

  factory WaterIntake.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WaterIntake(
      id: doc.id,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 250,
      containerType: WaterContainerType.values.firstWhere(
        (t) => t.name == data['containerType'],
        orElse: () => WaterContainerType.glass,
      ),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'amount': amount,
      'containerType': containerType.name,
      'note': note,
    };
  }

  WaterIntake copyWith({
    double? amount,
    WaterContainerType? containerType,
    String? note,
  }) {
    return WaterIntake(
      id: id,
      userId: userId,
      timestamp: timestamp,
      amount: amount ?? this.amount,
      containerType: containerType ?? this.containerType,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [id, userId, timestamp, amount, containerType, note];
}

/// Common container types for quick logging
enum WaterContainerType {
  glass('Glass', 250),
  smallBottle('Small Bottle', 350),
  bottle('Bottle', 500),
  largeBottle('Large Bottle', 750),
  cup('Cup', 200),
  mug('Mug', 300),
  custom('Custom', 0);

  final String displayName;
  final double defaultAmount; // in ml

  const WaterContainerType(this.displayName, this.defaultAmount);
}

/// Daily water intake summary
class DailyWaterSummary {
  final DateTime date;
  final double totalAmount; // in ml
  final double goal; // in ml
  final int logCount;
  final List<WaterIntake> logs;

  const DailyWaterSummary({
    required this.date,
    required this.totalAmount,
    required this.goal,
    required this.logCount,
    required this.logs,
  });

  double get percentComplete => goal > 0 ? (totalAmount / goal).clamp(0, 1.5) : 0;
  double get remaining => (goal - totalAmount).clamp(0, double.infinity);
  bool get goalReached => totalAmount >= goal;

  /// How many glasses (250ml) left to reach goal
  int get glassesRemaining => (remaining / 250).ceil();
}

/// Water intake settings
class WaterSettings {
  final double dailyGoal; // in ml (default 2000ml = 8 glasses)
  final bool remindersEnabled;
  final int reminderIntervalMinutes; // how often to remind
  final int reminderStartHour; // when to start reminding (e.g., 8 AM)
  final int reminderEndHour; // when to stop reminding (e.g., 10 PM)
  final List<double> quickAddAmounts; // customizable quick add buttons

  const WaterSettings({
    this.dailyGoal = 2000,
    this.remindersEnabled = true,
    this.reminderIntervalMinutes = 60,
    this.reminderStartHour = 8,
    this.reminderEndHour = 22,
    this.quickAddAmounts = const [250, 350, 500, 750],
  });

  factory WaterSettings.fromMap(Map<String, dynamic> map) {
    return WaterSettings(
      dailyGoal: (map['dailyGoal'] as num?)?.toDouble() ?? 2000,
      remindersEnabled: map['remindersEnabled'] ?? true,
      reminderIntervalMinutes: map['reminderIntervalMinutes'] ?? 60,
      reminderStartHour: map['reminderStartHour'] ?? 8,
      reminderEndHour: map['reminderEndHour'] ?? 22,
      quickAddAmounts: (map['quickAddAmounts'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [250, 350, 500, 750],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyGoal': dailyGoal,
      'remindersEnabled': remindersEnabled,
      'reminderIntervalMinutes': reminderIntervalMinutes,
      'reminderStartHour': reminderStartHour,
      'reminderEndHour': reminderEndHour,
      'quickAddAmounts': quickAddAmounts,
    };
  }

  WaterSettings copyWith({
    double? dailyGoal,
    bool? remindersEnabled,
    int? reminderIntervalMinutes,
    int? reminderStartHour,
    int? reminderEndHour,
    List<double>? quickAddAmounts,
  }) {
    return WaterSettings(
      dailyGoal: dailyGoal ?? this.dailyGoal,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderIntervalMinutes: reminderIntervalMinutes ?? this.reminderIntervalMinutes,
      reminderStartHour: reminderStartHour ?? this.reminderStartHour,
      reminderEndHour: reminderEndHour ?? this.reminderEndHour,
      quickAddAmounts: quickAddAmounts ?? this.quickAddAmounts,
    );
  }

  /// Convert goal to number of glasses (250ml each)
  int get goalInGlasses => (dailyGoal / 250).round();

  /// Common goal presets
  static const List<double> goalPresets = [1500, 2000, 2500, 3000, 3500, 4000];
}
