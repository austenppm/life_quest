import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// Currency settings
enum Currency {
  usd('\$', 'USD'),
  eur('\u20AC', 'EUR'),
  gbp('\u00A3', 'GBP'),
  jpy('\u00A5', 'JPY'),
  cny('\u00A5', 'CNY'),
  krw('\u20A9', 'KRW'),
  inr('\u20B9', 'INR'),
  thb('\u0E3F', 'THB'),
  mmk('K', 'MMK'),
  sgd('S\$', 'SGD'),
  myr('RM', 'MYR'),
  php('\u20B1', 'PHP'),
  idr('Rp', 'IDR'),
  vnd('\u20AB', 'VND'),
  aud('A\$', 'AUD'),
  cad('C\$', 'CAD');

  final String symbol;
  final String code;
  const Currency(this.symbol, this.code);
}

// Currency provider with persistence
class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(Currency.usd) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('currency') ?? 'USD';
    state = Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.usd,
    );
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency.code);
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>(
  (ref) => CurrencyNotifier(),
);

// Convenience provider for just the currency symbol
final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(currencyProvider).symbol;
});

// Helper to format currency
String formatCurrency(double amount, Currency currency) {
  return '${currency.symbol}${amount.toStringAsFixed(2)}';
}

// Transactions stream provider
final transactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchTransactions(user.uid);
});

// Transactions for current month
final currentMonthTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return transactions.where((t) =>
    t.date.year == now.year && t.date.month == now.month
  ).toList();
});

// Selected month state
final selectedMonthProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Transactions for selected month
final selectedMonthTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final selectedMonth = ref.watch(selectedMonthProvider);
  return transactions.where((t) =>
    t.date.year == selectedMonth.year && t.date.month == selectedMonth.month
  ).toList();
});

// Total income for selected month
final monthlyIncomeProvider = Provider<double>((ref) {
  final transactions = ref.watch(selectedMonthTransactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Total expenses for selected month
final monthlyExpensesProvider = Provider<double>((ref) {
  final transactions = ref.watch(selectedMonthTransactionsProvider);
  return transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Balance for selected month
final monthlyBalanceProvider = Provider<double>((ref) {
  final income = ref.watch(monthlyIncomeProvider);
  final expenses = ref.watch(monthlyExpensesProvider);
  return income - expenses;
});

// Expenses by category for selected month
final expensesByCategoryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(selectedMonthTransactionsProvider);
  final Map<String, double> byCategory = {};
  
  for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
    byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
  }
  
  return byCategory;
});

// Income by category for selected month
final incomeByCategoryProvider = Provider<Map<String, double>>((ref) {
  final transactions = ref.watch(selectedMonthTransactionsProvider);
  final Map<String, double> byCategory = {};
  
  for (final t in transactions.where((t) => t.type == TransactionType.income)) {
    byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
  }
  
  return byCategory;
});

// All-time balance
final totalBalanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  double balance = 0;
  for (final t in transactions) {
    if (t.type == TransactionType.income) {
      balance += t.amount;
    } else {
      balance -= t.amount;
    }
  }
  return balance;
});

// Recent transactions (last 10)
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  return sorted.take(10).toList();
});

// Transaction notifier for CRUD operations
class TransactionNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final String? _userId;

  TransactionNotifier(this._firestoreService, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> addTransaction({
    required TransactionType type,
    required double amount,
    required String categoryId,
    String? note,
    DateTime? date,
    bool isRecurring = false,
    RecurrenceType? recurrenceType,
    DateTime? recurrenceEndDate,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final transactionDate = date ?? DateTime.now();
      final nextOccurrence = isRecurring && recurrenceType != null
          ? recurrenceType.nextOccurrence(transactionDate)
          : null;

      final transaction = Transaction(
        id: const Uuid().v4(),
        userId: _userId,
        type: type,
        amount: amount,
        categoryId: categoryId,
        note: note,
        date: transactionDate,
        createdAt: DateTime.now(),
        isRecurring: isRecurring,
        recurrenceType: recurrenceType,
        recurrenceEndDate: recurrenceEndDate,
        nextOccurrence: nextOccurrence,
      );

      await _firestoreService.createTransaction(_userId, transaction);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Generate recurring transaction instances that are due
  Future<void> processRecurringTransactions() async {
    if (_userId == null) return;

    // This would be called periodically (e.g., on app start or daily)
    // For now, we'll implement the basic structure
    // In production, this could be a cloud function
  }

  Future<void> updateTransaction(
    String transactionId, {
    TransactionType? type,
    double? amount,
    String? categoryId,
    String? note,
    DateTime? date,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (type != null) updates['type'] = type.name;
      if (amount != null) updates['amount'] = amount;
      if (categoryId != null) updates['categoryId'] = categoryId;
      if (note != null) updates['note'] = note;
      if (date != null) updates['date'] = Timestamp.fromDate(date);

      await _firestoreService.updateTransaction(_userId, transactionId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteTransaction(_userId, transactionId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(currentUserProvider);
  return TransactionNotifier(firestoreService, user?.uid);
});

// ==================== Budget Providers ====================

// Budget stream provider
final budgetProvider = StreamProvider<Budget?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('settings')
      .doc('budget')
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return Budget.fromFirestore(doc);
      });
});

// Expenses for current budget period
final periodExpensesProvider = Provider<Map<String, double>>((ref) {
  final budget = ref.watch(budgetProvider).valueOrNull;
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

  if (budget == null) {
    // Default to monthly if no budget set
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final periodTransactions = transactions.where((t) =>
        t.type == TransactionType.expense && t.date.isAfter(monthStart));

    final Map<String, double> byCategory = {};
    for (final t in periodTransactions) {
      byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
    }
    return byCategory;
  }

  final periodStart = budget.period.getCurrentPeriodStart();
  final periodTransactions = transactions.where((t) =>
      t.type == TransactionType.expense &&
      t.date.isAfter(periodStart.subtract(const Duration(seconds: 1))));

  final Map<String, double> byCategory = {};
  for (final t in periodTransactions) {
    byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + t.amount;
  }
  return byCategory;
});

// Total period expenses
final periodTotalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(periodExpensesProvider);
  return expenses.values.fold(0.0, (sum, amount) => sum + amount);
});

// Budget status provider
final budgetStatusProvider = Provider<BudgetStatus?>((ref) {
  final budget = ref.watch(budgetProvider).valueOrNull;
  if (budget == null) return null;

  final periodExpenses = ref.watch(periodExpensesProvider);
  final totalSpent = periodExpenses.values.fold(0.0, (sum, v) => sum + v);

  // Calculate category statuses
  final categoryStatuses = <String, CategoryBudgetStatus>{};
  final overBudgetCategories = <String>[];
  final nearLimitCategories = <String>[];

  for (final categoryBudget in budget.categoryBudgets) {
    final spent = periodExpenses[categoryBudget.categoryId] ?? 0;
    final status = CategoryBudgetStatus.calculate(
      categoryId: categoryBudget.categoryId,
      limit: categoryBudget.limit,
      spent: spent,
      alertThreshold: categoryBudget.alertThreshold,
    );
    categoryStatuses[categoryBudget.categoryId] = status;

    if (status.isOverBudget) {
      overBudgetCategories.add(categoryBudget.categoryId);
    } else if (status.isNearLimit) {
      nearLimitCategories.add(categoryBudget.categoryId);
    }
  }

  final remaining = budget.totalLimit - totalSpent;
  final percentUsed = budget.totalLimit > 0 ? totalSpent / budget.totalLimit : 0.0;
  final daysRemaining = budget.period.getRemainingDays();
  final dailyAllowance = remaining > 0 && daysRemaining > 0
      ? remaining / daysRemaining
      : 0.0;

  return BudgetStatus(
    totalLimit: budget.totalLimit,
    totalSpent: totalSpent,
    remaining: remaining,
    percentUsed: percentUsed,
    isOverBudget: totalSpent > budget.totalLimit,
    isNearLimit: percentUsed >= budget.alertThreshold && percentUsed < 1.0,
    categoryStatuses: categoryStatuses,
    overBudgetCategories: overBudgetCategories,
    nearLimitCategories: nearLimitCategories,
    daysRemaining: daysRemaining,
    dailyAllowance: dailyAllowance,
  );
});

// Budget notifier for CRUD operations
class BudgetNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;

  BudgetNotifier(this._userId) : super(const AsyncValue.data(null));

  Future<void> saveBudget({
    required double totalLimit,
    required BudgetPeriod period,
    List<CategoryBudget> categoryBudgets = const [],
    bool alertsEnabled = true,
    double alertThreshold = 0.8,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('budget');

      final doc = await docRef.get();

      if (doc.exists) {
        // Update existing budget
        await docRef.update({
          'totalLimit': totalLimit,
          'period': period.name,
          'categoryBudgets': categoryBudgets.map((b) => b.toMap()).toList(),
          'alertsEnabled': alertsEnabled,
          'alertThreshold': alertThreshold,
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Create new budget
        final budget = Budget(
          id: 'budget',
          userId: _userId,
          totalLimit: totalLimit,
          period: period,
          categoryBudgets: categoryBudgets,
          alertsEnabled: alertsEnabled,
          alertThreshold: alertThreshold,
          createdAt: DateTime.now(),
        );
        await docRef.set(budget.toFirestore());
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setCategoryBudget({
    required String categoryId,
    required double limit,
    bool alertEnabled = true,
    double alertThreshold = 0.8,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('budget');

      final doc = await docRef.get();

      if (!doc.exists) {
        // Create budget with just this category
        await saveBudget(
          totalLimit: 0,
          period: BudgetPeriod.monthly,
          categoryBudgets: [
            CategoryBudget(
              categoryId: categoryId,
              limit: limit,
              alertEnabled: alertEnabled,
              alertThreshold: alertThreshold,
            ),
          ],
        );
        return;
      }

      final budget = Budget.fromFirestore(doc);
      final existingIndex = budget.categoryBudgets
          .indexWhere((b) => b.categoryId == categoryId);

      List<CategoryBudget> updatedBudgets;
      if (existingIndex >= 0) {
        // Update existing category budget
        updatedBudgets = [...budget.categoryBudgets];
        updatedBudgets[existingIndex] = CategoryBudget(
          categoryId: categoryId,
          limit: limit,
          alertEnabled: alertEnabled,
          alertThreshold: alertThreshold,
        );
      } else {
        // Add new category budget
        updatedBudgets = [
          ...budget.categoryBudgets,
          CategoryBudget(
            categoryId: categoryId,
            limit: limit,
            alertEnabled: alertEnabled,
            alertThreshold: alertThreshold,
          ),
        ];
      }

      await docRef.update({
        'categoryBudgets': updatedBudgets.map((b) => b.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeCategoryBudget(String categoryId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('budget');

      final doc = await docRef.get();
      if (!doc.exists) return;

      final budget = Budget.fromFirestore(doc);
      final updatedBudgets = budget.categoryBudgets
          .where((b) => b.categoryId != categoryId)
          .toList();

      await docRef.update({
        'categoryBudgets': updatedBudgets.map((b) => b.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteBudget() async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('settings')
          .doc('budget')
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final budgetNotifierProvider =
    StateNotifierProvider<BudgetNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return BudgetNotifier(user?.uid);
});
