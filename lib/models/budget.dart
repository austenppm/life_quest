import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Budget period for tracking
enum BudgetPeriod {
  weekly('Weekly'),
  biweekly('Bi-weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  final String displayName;
  const BudgetPeriod(this.displayName);

  /// Get the start date for the current period
  DateTime getCurrentPeriodStart() {
    final now = DateTime.now();
    switch (this) {
      case BudgetPeriod.weekly:
        // Start from Monday of current week
        return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case BudgetPeriod.biweekly:
        // Start from 1st or 15th of month
        final day = now.day < 15 ? 1 : 15;
        return DateTime(now.year, now.month, day);
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month, 1);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 1, 1);
    }
  }

  /// Get the end date for the current period
  DateTime getCurrentPeriodEnd() {
    final now = DateTime.now();
    switch (this) {
      case BudgetPeriod.weekly:
        final start = getCurrentPeriodStart();
        return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
      case BudgetPeriod.biweekly:
        final day = now.day < 15 ? 14 : DateTime(now.year, now.month + 1, 0).day;
        return DateTime(now.year, now.month, day, 23, 59, 59);
      case BudgetPeriod.monthly:
        return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      case BudgetPeriod.yearly:
        return DateTime(now.year, 12, 31, 23, 59, 59);
    }
  }

  /// Get remaining days in current period
  int getRemainingDays() {
    final now = DateTime.now();
    final end = getCurrentPeriodEnd();
    return end.difference(now).inDays + 1;
  }

  /// Get total days in current period
  int getTotalDays() {
    final start = getCurrentPeriodStart();
    final end = getCurrentPeriodEnd();
    return end.difference(start).inDays + 1;
  }
}

/// Budget limit for a specific category
class CategoryBudget extends Equatable {
  final String categoryId;
  final double limit;
  final bool alertEnabled;
  final double alertThreshold; // Percentage (0.0 - 1.0) to trigger alert

  const CategoryBudget({
    required this.categoryId,
    required this.limit,
    this.alertEnabled = true,
    this.alertThreshold = 0.8, // Alert at 80% by default
  });

  factory CategoryBudget.fromMap(Map<String, dynamic> map) {
    return CategoryBudget(
      categoryId: map['categoryId'] ?? '',
      limit: (map['limit'] as num?)?.toDouble() ?? 0,
      alertEnabled: map['alertEnabled'] ?? true,
      alertThreshold: (map['alertThreshold'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'limit': limit,
      'alertEnabled': alertEnabled,
      'alertThreshold': alertThreshold,
    };
  }

  CategoryBudget copyWith({
    double? limit,
    bool? alertEnabled,
    double? alertThreshold,
  }) {
    return CategoryBudget(
      categoryId: categoryId,
      limit: limit ?? this.limit,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }

  @override
  List<Object?> get props => [categoryId, limit, alertEnabled, alertThreshold];
}

/// Main budget model
class Budget extends Equatable {
  final String id;
  final String userId;
  final double totalLimit; // Overall spending limit
  final BudgetPeriod period;
  final List<CategoryBudget> categoryBudgets;
  final bool alertsEnabled;
  final double alertThreshold; // Overall alert threshold
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.totalLimit,
    this.period = BudgetPeriod.monthly,
    this.categoryBudgets = const [],
    this.alertsEnabled = true,
    this.alertThreshold = 0.8,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get the budget limit for a specific category
  double? getCategoryLimit(String categoryId) {
    try {
      return categoryBudgets
          .firstWhere((b) => b.categoryId == categoryId)
          .limit;
    } catch (_) {
      return null;
    }
  }

  /// Get all category IDs that have budgets set
  Set<String> get budgetedCategoryIds =>
      categoryBudgets.map((b) => b.categoryId).toSet();

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      userId: data['userId'] ?? '',
      totalLimit: (data['totalLimit'] as num?)?.toDouble() ?? 0,
      period: BudgetPeriod.values.firstWhere(
        (p) => p.name == data['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      categoryBudgets: (data['categoryBudgets'] as List<dynamic>?)
              ?.map((b) => CategoryBudget.fromMap(b as Map<String, dynamic>))
              .toList() ??
          [],
      alertsEnabled: data['alertsEnabled'] ?? true,
      alertThreshold: (data['alertThreshold'] as num?)?.toDouble() ?? 0.8,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'totalLimit': totalLimit,
      'period': period.name,
      'categoryBudgets': categoryBudgets.map((b) => b.toMap()).toList(),
      'alertsEnabled': alertsEnabled,
      'alertThreshold': alertThreshold,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  Budget copyWith({
    double? totalLimit,
    BudgetPeriod? period,
    List<CategoryBudget>? categoryBudgets,
    bool? alertsEnabled,
    double? alertThreshold,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id,
      userId: userId,
      totalLimit: totalLimit ?? this.totalLimit,
      period: period ?? this.period,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        totalLimit,
        period,
        categoryBudgets,
        alertsEnabled,
        alertThreshold,
        createdAt,
        updatedAt,
      ];
}

/// Budget status for a category
class CategoryBudgetStatus {
  final String categoryId;
  final double limit;
  final double spent;
  final double remaining;
  final double percentUsed;
  final bool isOverBudget;
  final bool isNearLimit;

  const CategoryBudgetStatus({
    required this.categoryId,
    required this.limit,
    required this.spent,
    required this.remaining,
    required this.percentUsed,
    required this.isOverBudget,
    required this.isNearLimit,
  });

  factory CategoryBudgetStatus.calculate({
    required String categoryId,
    required double limit,
    required double spent,
    double alertThreshold = 0.8,
  }) {
    final remaining = limit - spent;
    final percentUsed = limit > 0 ? spent / limit : 0.0;
    return CategoryBudgetStatus(
      categoryId: categoryId,
      limit: limit,
      spent: spent,
      remaining: remaining,
      percentUsed: percentUsed,
      isOverBudget: spent > limit,
      isNearLimit: percentUsed >= alertThreshold && percentUsed < 1.0,
    );
  }
}

/// Overall budget status
class BudgetStatus {
  final double totalLimit;
  final double totalSpent;
  final double remaining;
  final double percentUsed;
  final bool isOverBudget;
  final bool isNearLimit;
  final Map<String, CategoryBudgetStatus> categoryStatuses;
  final List<String> overBudgetCategories;
  final List<String> nearLimitCategories;
  final int daysRemaining;
  final double dailyAllowance;

  const BudgetStatus({
    required this.totalLimit,
    required this.totalSpent,
    required this.remaining,
    required this.percentUsed,
    required this.isOverBudget,
    required this.isNearLimit,
    required this.categoryStatuses,
    required this.overBudgetCategories,
    required this.nearLimitCategories,
    required this.daysRemaining,
    required this.dailyAllowance,
  });
}
