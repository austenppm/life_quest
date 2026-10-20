import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TransactionType { income, expense }

/// Recurrence type for recurring transactions
enum RecurrenceType {
  daily('Daily'),
  weekly('Weekly'),
  biweekly('Bi-weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  final String displayName;
  const RecurrenceType(this.displayName);

  /// Get next occurrence date from a given date
  DateTime nextOccurrence(DateTime from) {
    switch (this) {
      case RecurrenceType.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        return from.add(const Duration(days: 7));
      case RecurrenceType.biweekly:
        return from.add(const Duration(days: 14));
      case RecurrenceType.monthly:
        return DateTime(from.year, from.month + 1, from.day);
      case RecurrenceType.quarterly:
        return DateTime(from.year, from.month + 3, from.day);
      case RecurrenceType.yearly:
        return DateTime(from.year + 1, from.month, from.day);
    }
  }
}

class Transaction extends Equatable {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  // Recurring payment fields
  final bool isRecurring;
  final RecurrenceType? recurrenceType;
  final DateTime? recurrenceEndDate;
  final String? parentTransactionId; // For generated recurring instances
  final DateTime? nextOccurrence;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.categoryId,
    this.note,
    required this.date,
    required this.createdAt,
    this.isRecurring = false,
    this.recurrenceType,
    this.recurrenceEndDate,
    this.parentTransactionId,
    this.nextOccurrence,
  });

  /// Check if this is a recurring transaction template
  bool get isRecurringTemplate => isRecurring && parentTransactionId == null;

  /// Check if this is a generated instance from a recurring template
  bool get isRecurringInstance => parentTransactionId != null;

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      categoryId: data['categoryId'] ?? '',
      note: data['note'],
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRecurring: data['isRecurring'] ?? false,
      recurrenceType: data['recurrenceType'] != null
          ? RecurrenceType.values.firstWhere(
              (e) => e.name == data['recurrenceType'],
              orElse: () => RecurrenceType.monthly,
            )
          : null,
      recurrenceEndDate: (data['recurrenceEndDate'] as Timestamp?)?.toDate(),
      parentTransactionId: data['parentTransactionId'],
      nextOccurrence: (data['nextOccurrence'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'note': note,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'isRecurring': isRecurring,
      'recurrenceType': recurrenceType?.name,
      'recurrenceEndDate': recurrenceEndDate != null
          ? Timestamp.fromDate(recurrenceEndDate!)
          : null,
      'parentTransactionId': parentTransactionId,
      'nextOccurrence': nextOccurrence != null
          ? Timestamp.fromDate(nextOccurrence!)
          : null,
    };
  }

  Transaction copyWith({
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
    bool? isRecurring,
    RecurrenceType? recurrenceType,
    DateTime? recurrenceEndDate,
    String? parentTransactionId,
    DateTime? nextOccurrence,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentTransactionId: parentTransactionId ?? this.parentTransactionId,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
    );
  }

  @override
  List<Object?> get props => [
    id, userId, type, amount, categoryId, note, date, createdAt,
    isRecurring, recurrenceType, recurrenceEndDate, parentTransactionId, nextOccurrence,
  ];
}

class TransactionCategory extends Equatable {
  final String id;
  final String name;
  final String iconName;
  final int colorValue;
  final TransactionType type;
  final bool isDefault;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorValue,
    required this.type,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);

  IconData get icon {
    switch (iconName) {
      // Expense icons
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'directions_car':
        return Icons.directions_car;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'phone':
        return Icons.phone;
      case 'flight':
        return Icons.flight;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'pets':
        return Icons.pets;
      case 'checkroom':
        return Icons.checkroom;
      case 'card_giftcard':
        return Icons.card_giftcard;
      case 'more_horiz':
        return Icons.more_horiz;
      // Income icons
      case 'work':
        return Icons.work;
      case 'account_balance':
        return Icons.account_balance;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      case 'sell':
        return Icons.sell;
      case 'redeem':
        return Icons.redeem;
      default:
        return Icons.attach_money;
    }
  }

  factory TransactionCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionCategory(
      id: doc.id,
      name: data['name'] ?? '',
      iconName: data['iconName'] ?? 'attach_money',
      colorValue: data['colorValue'] ?? 0xFF6C5CE7,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconName': iconName,
      'colorValue': colorValue,
      'type': type.name,
      'isDefault': isDefault,
    };
  }

  @override
  List<Object?> get props => [id, name, iconName, colorValue, type, isDefault];
}

// Default categories
class DefaultCategories {
  static const List<TransactionCategory> expenses = [
    TransactionCategory(
      id: 'food',
      name: 'Food & Drinks',
      iconName: 'restaurant',
      colorValue: 0xFFFF6B6B,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'shopping',
      name: 'Shopping',
      iconName: 'shopping_cart',
      colorValue: 0xFF4ECDC4,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'transport',
      name: 'Transport',
      iconName: 'directions_car',
      colorValue: 0xFF45B7D1,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'entertainment',
      name: 'Entertainment',
      iconName: 'movie',
      colorValue: 0xFFA66CFF,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'health',
      name: 'Health',
      iconName: 'local_hospital',
      colorValue: 0xFFFF85A2,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'education',
      name: 'Education',
      iconName: 'school',
      colorValue: 0xFF6BCB77,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'bills',
      name: 'Bills & Utilities',
      iconName: 'home',
      colorValue: 0xFFFFB347,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'phone',
      name: 'Phone & Internet',
      iconName: 'phone',
      colorValue: 0xFF98D8C8,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'travel',
      name: 'Travel',
      iconName: 'flight',
      colorValue: 0xFFF7DC6F,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'fitness',
      name: 'Fitness',
      iconName: 'fitness_center',
      colorValue: 0xFF00D9FF,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'pets',
      name: 'Pets',
      iconName: 'pets',
      colorValue: 0xFFDDA0DD,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'clothing',
      name: 'Clothing',
      iconName: 'checkroom',
      colorValue: 0xFFE6B0AA,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'gifts',
      name: 'Gifts',
      iconName: 'card_giftcard',
      colorValue: 0xFFFF69B4,
      type: TransactionType.expense,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'other_expense',
      name: 'Other',
      iconName: 'more_horiz',
      colorValue: 0xFF95A5A6,
      type: TransactionType.expense,
      isDefault: true,
    ),
  ];

  static const List<TransactionCategory> incomes = [
    TransactionCategory(
      id: 'salary',
      name: 'Salary',
      iconName: 'work',
      colorValue: 0xFF2ECC71,
      type: TransactionType.income,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'freelance',
      name: 'Freelance',
      iconName: 'account_balance',
      colorValue: 0xFF3498DB,
      type: TransactionType.income,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'savings',
      name: 'Savings',
      iconName: 'savings',
      colorValue: 0xFFF39C12,
      type: TransactionType.income,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'investments',
      name: 'Investments',
      iconName: 'trending_up',
      colorValue: 0xFF9B59B6,
      type: TransactionType.income,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'sales',
      name: 'Sales',
      iconName: 'sell',
      colorValue: 0xFF1ABC9C,
      type: TransactionType.income,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'gifts_income',
      name: 'Gifts',
      iconName: 'redeem',
      colorValue: 0xFFE74C3C,
      type: TransactionType.income,
      isDefault: true,
    ),
    TransactionCategory(
      id: 'other_income',
      name: 'Other',
      iconName: 'more_horiz',
      colorValue: 0xFF95A5A6,
      type: TransactionType.income,
      isDefault: true,
    ),
  ];

  static List<TransactionCategory> get all => [...expenses, ...incomes];

  static TransactionCategory? getById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
