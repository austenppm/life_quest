import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum WeightUnit { kg, lbs }

class WeightEntry extends Equatable {
  final String id;
  final String userId;
  final double weight;
  final WeightUnit unit;
  final DateTime date;
  final String? note;
  final double? bodyFat; // Optional body fat percentage
  final double? muscleMass; // Optional muscle mass
  final double? waterPercentage; // Optional water percentage
  final Map<String, double>? measurements; // Optional body measurements

  const WeightEntry({
    required this.id,
    required this.userId,
    required this.weight,
    this.unit = WeightUnit.kg,
    required this.date,
    this.note,
    this.bodyFat,
    this.muscleMass,
    this.waterPercentage,
    this.measurements,
  });

  // Convert weight to kg
  double get weightInKg => unit == WeightUnit.kg ? weight : weight * 0.453592;
  
  // Convert weight to lbs
  double get weightInLbs => unit == WeightUnit.lbs ? weight : weight * 2.20462;

  factory WeightEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeightEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      weight: (data['weight'] as num).toDouble(),
      unit: WeightUnit.values.firstWhere(
        (e) => e.name == data['unit'],
        orElse: () => WeightUnit.kg,
      ),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'],
      bodyFat: (data['bodyFat'] as num?)?.toDouble(),
      muscleMass: (data['muscleMass'] as num?)?.toDouble(),
      waterPercentage: (data['waterPercentage'] as num?)?.toDouble(),
      measurements: data['measurements'] != null
          ? Map<String, double>.from(
              (data['measurements'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
              ),
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'weight': weight,
      'unit': unit.name,
      'date': Timestamp.fromDate(date),
      'note': note,
      'bodyFat': bodyFat,
      'muscleMass': muscleMass,
      'waterPercentage': waterPercentage,
      'measurements': measurements,
    };
  }

  WeightEntry copyWith({
    double? weight,
    WeightUnit? unit,
    DateTime? date,
    String? note,
    double? bodyFat,
    double? muscleMass,
    double? waterPercentage,
    Map<String, double>? measurements,
  }) {
    return WeightEntry(
      id: id,
      userId: userId,
      weight: weight ?? this.weight,
      unit: unit ?? this.unit,
      date: date ?? this.date,
      note: note ?? this.note,
      bodyFat: bodyFat ?? this.bodyFat,
      muscleMass: muscleMass ?? this.muscleMass,
      waterPercentage: waterPercentage ?? this.waterPercentage,
      measurements: measurements ?? this.measurements,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, weight, unit, date, note,
        bodyFat, muscleMass, waterPercentage, measurements,
      ];
}

class WeightGoal extends Equatable {
  final String userId;
  final double targetWeight;
  final WeightUnit unit;
  final double startWeight;
  final DateTime startDate;
  final DateTime? targetDate;
  final String goalType; // 'lose', 'gain', 'maintain'

  const WeightGoal({
    required this.userId,
    required this.targetWeight,
    this.unit = WeightUnit.kg,
    required this.startWeight,
    required this.startDate,
    this.targetDate,
    required this.goalType,
  });

  double get weightDifference => targetWeight - startWeight;
  
  double progressPercentage(double currentWeight) {
    if (weightDifference == 0) return 100;
    final progress = (currentWeight - startWeight) / weightDifference;
    return (progress * 100).clamp(0, 100);
  }

  double remainingWeight(double currentWeight) {
    return (targetWeight - currentWeight).abs();
  }

  factory WeightGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WeightGoal(
      userId: data['userId'] ?? '',
      targetWeight: (data['targetWeight'] as num).toDouble(),
      unit: WeightUnit.values.firstWhere(
        (e) => e.name == data['unit'],
        orElse: () => WeightUnit.kg,
      ),
      startWeight: (data['startWeight'] as num).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      targetDate: (data['targetDate'] as Timestamp?)?.toDate(),
      goalType: data['goalType'] ?? 'maintain',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'targetWeight': targetWeight,
      'unit': unit.name,
      'startWeight': startWeight,
      'startDate': Timestamp.fromDate(startDate),
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'goalType': goalType,
    };
  }

  @override
  List<Object?> get props => [
        userId, targetWeight, unit, startWeight, startDate, targetDate, goalType,
      ];
}

// Statistics calculated from weight entries
class WeightStats {
  final double currentWeight;
  final double lowestWeight;
  final double highestWeight;
  final double averageWeight;
  final double weeklyChange;
  final double monthlyChange;
  final double totalChange;
  final int totalEntries;
  final int currentStreak; // Days logged in a row

  const WeightStats({
    required this.currentWeight,
    required this.lowestWeight,
    required this.highestWeight,
    required this.averageWeight,
    required this.weeklyChange,
    required this.monthlyChange,
    required this.totalChange,
    required this.totalEntries,
    required this.currentStreak,
  });

  factory WeightStats.empty() {
    return const WeightStats(
      currentWeight: 0,
      lowestWeight: 0,
      highestWeight: 0,
      averageWeight: 0,
      weeklyChange: 0,
      monthlyChange: 0,
      totalChange: 0,
      totalEntries: 0,
      currentStreak: 0,
    );
  }

  factory WeightStats.fromEntries(List<WeightEntry> entries) {
    if (entries.isEmpty) return WeightStats.empty();

    // Sort by date descending
    final sorted = [...entries]..sort((a, b) => b.date.compareTo(a.date));
    
    final current = sorted.first.weightInKg;
    final weights = sorted.map((e) => e.weightInKg).toList();
    
    final lowest = weights.reduce((a, b) => a < b ? a : b);
    final highest = weights.reduce((a, b) => a > b ? a : b);
    final average = weights.reduce((a, b) => a + b) / weights.length;
    
    // Calculate changes
    double weeklyChange = 0;
    double monthlyChange = 0;
    double totalChange = 0;
    
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));
    
    final weekEntries = sorted.where((e) => e.date.isAfter(weekAgo)).toList();
    if (weekEntries.length > 1) {
      weeklyChange = weekEntries.first.weightInKg - weekEntries.last.weightInKg;
    }
    
    final monthEntries = sorted.where((e) => e.date.isAfter(monthAgo)).toList();
    if (monthEntries.length > 1) {
      monthlyChange = monthEntries.first.weightInKg - monthEntries.last.weightInKg;
    }
    
    if (sorted.length > 1) {
      totalChange = sorted.first.weightInKg - sorted.last.weightInKg;
    }
    
    // Calculate streak
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);
    
    for (final entry in sorted) {
      final entryDate = DateTime(entry.date.year, entry.date.month, entry.date.day);
      if (entryDate == checkDate || entryDate == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = entryDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return WeightStats(
      currentWeight: current,
      lowestWeight: lowest,
      highestWeight: highest,
      averageWeight: average,
      weeklyChange: weeklyChange,
      monthlyChange: monthlyChange,
      totalChange: totalChange,
      totalEntries: entries.length,
      currentStreak: streak,
    );
  }
}
