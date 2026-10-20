import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/money_provider.dart';
import 'add_transaction_sheet.dart';
import 'transaction_history_screen.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  double _dragStartX = 0;

  // Tab paths for edge swipe navigation
  static const _tabPaths = ['/home', '/tasks', '/food', '/money', '/profile'];
  static const _currentTabIndex = 3; // Money is index 3

  void _handleSwipe(DragEndDetails details, DateTime selectedMonth) {
    final screenWidth = MediaQuery.of(context).size.width;
    final edgeThreshold = screenWidth * 0.15;
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() < 300) return;

    final isFromLeftEdge = _dragStartX < edgeThreshold;
    final isFromRightEdge = _dragStartX > screenWidth - edgeThreshold;

    if (isFromLeftEdge || isFromRightEdge) {
      // Edge swipe -> switch tabs
      if (velocity > 0 && _currentTabIndex > 0) {
        context.go(_tabPaths[_currentTabIndex - 1]);
      } else if (velocity < 0 && _currentTabIndex < _tabPaths.length - 1) {
        context.go(_tabPaths[_currentTabIndex + 1]);
      }
    } else {
      // Center swipe -> change month
      if (velocity > 0) {
        ref.read(selectedMonthProvider.notifier).state = DateTime(
          selectedMonth.year,
          selectedMonth.month - 1,
        );
      } else {
        final next = DateTime(selectedMonth.year, selectedMonth.month + 1);
        if (next.isBefore(DateTime.now()) ||
            (next.year == DateTime.now().year && next.month == DateTime.now().month)) {
          ref.read(selectedMonthProvider.notifier).state = next;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final income = ref.watch(monthlyIncomeProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final balance = ref.watch(monthlyBalanceProvider);
    final expensesByCategory = ref.watch(expensesByCategoryProvider);

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (details) => _dragStartX = details.globalPosition.dx,
        onHorizontalDragEnd: (details) => _handleSwipe(details, selectedMonth),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
          children: [
            // Month selector
            _MonthSelector(
              selectedMonth: selectedMonth,
              onPrevious: () {
                ref.read(selectedMonthProvider.notifier).state = DateTime(
                  selectedMonth.year,
                  selectedMonth.month - 1,
                );
              },
              onNext: () {
                final next = DateTime(selectedMonth.year, selectedMonth.month + 1);
                if (next.isBefore(DateTime.now()) || 
                    (next.year == DateTime.now().year && next.month == DateTime.now().month)) {
                  ref.read(selectedMonthProvider.notifier).state = next;
                }
              },
            ),
            
            // Balance summary
            _BalanceSummary(
              income: income,
              expenses: expenses,
              balance: balance,
            ),
            
            // Donut chart with category buttons
            Expanded(
              child: _ChartWithCategories(
                expenses: expenses,
                expensesByCategory: expensesByCategory,
                onCategoryTap: (category) {
                  _showAddTransaction(context, category);
                },
                onCenterTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TransactionHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            
            // Quick add buttons
            _QuickAddButtons(
              onExpense: () => _showAddTransaction(context, null, isExpense: true),
              onIncome: () => _showAddTransaction(context, null, isExpense: false),
            ),
          ],
        ),
      ),
      ),
    );
  }

  void _showAddTransaction(BuildContext context, TransactionCategory? category, {bool isExpense = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(
        initialCategory: category,
        initialType: isExpense ? TransactionType.expense : TransactionType.income,
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentMonth = selectedMonth.year == DateTime.now().year &&
        selectedMonth.month == DateTime.now().month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            onPressed: isCurrentMonth ? null : onNext,
            icon: Icon(
              Icons.chevron_right,
              color: isCurrentMonth ? AppColors.textMuted : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceSummary extends ConsumerWidget {
  final double income;
  final double expenses;
  final double balance;

  const _BalanceSummary({
    required this.income,
    required this.expenses,
    required this.balance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final currencyFormat = NumberFormat.currency(symbol: currency.symbol, decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Income',
              amount: currencyFormat.format(income),
              color: AppColors.success,
              icon: Icons.arrow_downward,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.surfaceLight,
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Expenses',
              amount: currencyFormat.format(expenses),
              color: AppColors.error,
              icon: Icons.arrow_upward,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.surfaceLight,
          ),
          Expanded(
            child: _SummaryItem(
              label: 'Balance',
              amount: currencyFormat.format(balance),
              color: balance >= 0 ? AppColors.success : AppColors.error,
              icon: balance >= 0 ? Icons.trending_up : Icons.trending_down,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ChartWithCategories extends ConsumerWidget {
  final double expenses;
  final Map<String, double> expensesByCategory;
  final Function(TransactionCategory) onCategoryTap;
  final VoidCallback onCenterTap;

  const _ChartWithCategories({
    required this.expenses,
    required this.expensesByCategory,
    required this.onCategoryTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = DefaultCategories.expenses;
    final currency = ref.watch(currencyProvider);
    final currencyFormat = NumberFormat.currency(symbol: currency.symbol, decimalDigits: 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final minDimension = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        // Chart and button sizes
        final chartSize = minDimension * 0.32;
        final buttonSize = 36.0;
        // Radius for button placement
        final radius = (chartSize / 2) + buttonSize + 8;

        return Center(
          child: SizedBox(
            width: minDimension,
            height: minDimension,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Donut chart at center
                GestureDetector(
                  onTap: onCenterTap,
                  child: SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: chartSize / 3,
                            sections: _buildChartSections(),
                            pieTouchData: PieTouchData(enabled: false),
                          ),
                        ),
                        // Center text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Expenses',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                            ),
                            Text(
                              currencyFormat.format(expenses),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap for history',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 9,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Category buttons around the chart
                ...List.generate(categories.length, (index) {
                  final category = categories[index];
                  final angle = (index * 2 * math.pi / categories.length) - (math.pi / 2);
                  final x = radius * math.cos(angle);
                  final y = radius * math.sin(angle);
                  final amount = expensesByCategory[category.id] ?? 0;

                  return Transform.translate(
                    offset: Offset(x, y),
                    child: _CategoryButton(
                      category: category,
                      amount: amount,
                      size: buttonSize,
                      onTap: () => onCategoryTap(category),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> _buildChartSections() {
    if (expensesByCategory.isEmpty) {
      return [
        PieChartSectionData(
          color: AppColors.surfaceLight,
          value: 1,
          title: '',
          radius: 20,
        ),
      ];
    }

    final sections = <PieChartSectionData>[];
    expensesByCategory.forEach((categoryId, amount) {
      final category = DefaultCategories.getById(categoryId);
      if (category != null && amount > 0) {
        sections.add(
          PieChartSectionData(
            color: category.color,
            value: amount,
            title: '',
            radius: 20,
          ),
        );
      }
    });

    return sections.isEmpty
        ? [
            PieChartSectionData(
              color: AppColors.surfaceLight,
              value: 1,
              title: '',
              radius: 20,
            ),
          ]
        : sections;
  }
}

class _CategoryButton extends StatelessWidget {
  final TransactionCategory category;
  final double amount;
  final double size;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.category,
    required this.amount,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final hasAmount = amount > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hasAmount ? category.color.withOpacity(0.2) : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: hasAmount ? category.color : AppColors.surfaceLight,
            width: 2,
          ),
        ),
        child: Icon(
          category.icon,
          color: hasAmount ? category.color : AppColors.textMuted,
          size: size * 0.45,
        ),
      ),
    );
  }
}

class _QuickAddButtons extends StatelessWidget {
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  const _QuickAddButtons({
    required this.onExpense,
    required this.onIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onExpense,
              icon: const Icon(Icons.remove),
              label: const Text('Expense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onIncome,
              icon: const Icon(Icons.add),
              label: const Text('Income'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
