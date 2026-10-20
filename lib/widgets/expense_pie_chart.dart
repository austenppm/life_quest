import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../providers/money_provider.dart';

/// Period filter for the pie chart
enum ChartPeriod {
  week('This Week'),
  month('This Month'),
  year('This Year'),
  all('All Time');

  final String displayName;
  const ChartPeriod(this.displayName);

  DateTime get startDate {
    final now = DateTime.now();
    switch (this) {
      case ChartPeriod.week:
        return now.subtract(Duration(days: now.weekday - 1));
      case ChartPeriod.month:
        return DateTime(now.year, now.month, 1);
      case ChartPeriod.year:
        return DateTime(now.year, 1, 1);
      case ChartPeriod.all:
        return DateTime(2000);
    }
  }
}

/// A beautiful pie chart showing expense or income distribution by category
class ExpensePieChart extends ConsumerStatefulWidget {
  final TransactionType transactionType;
  final ChartPeriod initialPeriod;
  final bool showLegend;
  final bool showTotal;
  final double? height;

  const ExpensePieChart({
    super.key,
    this.transactionType = TransactionType.expense,
    this.initialPeriod = ChartPeriod.month,
    this.showLegend = true,
    this.showTotal = true,
    this.height,
  });

  @override
  ConsumerState<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends ConsumerState<ExpensePieChart> {
  late ChartPeriod _selectedPeriod;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final filteredTransactions = _filterTransactions(transactions);
        final categoryTotals = _calculateCategoryTotals(filteredTransactions);
        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

        if (categoryTotals.isEmpty) {
          return _buildEmptyState(context);
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, currencySymbol, total),
                const SizedBox(height: 8),
                _buildPeriodSelector(context),
                const SizedBox(height: 16),
                SizedBox(
                  height: widget.height ?? 220,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildPieChart(context, categoryTotals, total),
                      ),
                      if (widget.showLegend) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _buildLegend(
                            context,
                            categoryTotals,
                            total,
                            currencySymbol,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => Card(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text('Error: $e'),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String currencySymbol, double total) {
    final title = widget.transactionType == TransactionType.expense
        ? 'Expense Distribution'
        : 'Income Distribution';

    return Row(
      children: [
        Icon(
          widget.transactionType == TransactionType.expense
              ? Icons.pie_chart
              : Icons.donut_large,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        if (widget.showTotal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.transactionType == TransactionType.expense
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$currencySymbol${_formatAmount(total)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.transactionType == TransactionType.expense
                    ? Colors.red
                    : Colors.green,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ChartPeriod.values.map((period) {
          final isSelected = period == _selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(period.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                    _touchedIndex = null;
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<TransactionCategory, double> categoryTotals,
    double total,
  ) {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = null;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 50,
        sections: entries.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value.key;
          final amount = entry.value.value;
          final percentage = (amount / total) * 100;
          final isTouched = index == _touchedIndex;

          return PieChartSectionData(
            color: category.color,
            value: amount,
            title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
            radius: isTouched ? 70 : 60,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            badgeWidget: isTouched
                ? _buildBadge(context, category, amount)
                : null,
            badgePositionPercentageOffset: 1.2,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    TransactionCategory category,
    double amount,
  ) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: category.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: category.color.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(
        category.icon,
        size: 16,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegend(
    BuildContext context,
    Map<TransactionCategory, double> categoryTotals,
    double total,
    String currencySymbol,
  ) {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Show top 6 categories, group rest as "Other"
    final displayEntries = entries.take(6).toList();

    return ListView.builder(
      shrinkWrap: true,
      itemCount: displayEntries.length,
      itemBuilder: (context, index) {
        final entry = displayEntries[index];
        final category = entry.key;
        final amount = entry.value;
        final percentage = (amount / total) * 100;
        final isTouched = index == _touchedIndex;

        return InkWell(
          onTap: () {
            setState(() {
              _touchedIndex = _touchedIndex == index ? null : index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: isTouched
                  ? category.color.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isTouched ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$currencySymbol${_formatAmount(amount)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isTouched
                        ? category.color
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final message = widget.transactionType == TransactionType.expense
        ? 'No expenses recorded for this period'
        : 'No income recorded for this period';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    final startDate = _selectedPeriod.startDate;
    return transactions.where((t) {
      return t.type == widget.transactionType && t.date.isAfter(startDate);
    }).toList();
  }

  Map<TransactionCategory, double> _calculateCategoryTotals(
    List<Transaction> transactions,
  ) {
    final totals = <TransactionCategory, double>{};

    for (final transaction in transactions) {
      final category = DefaultCategories.getById(transaction.categoryId);
      if (category != null) {
        totals[category] = (totals[category] ?? 0) + transaction.amount;
      }
    }

    return totals;
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}

/// A combined expense and income comparison chart
class IncomeExpenseComparisonChart extends ConsumerWidget {
  final ChartPeriod period;

  const IncomeExpenseComparisonChart({
    super.key,
    this.period = ChartPeriod.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final startDate = period.startDate;
        final filtered = transactions.where((t) => t.date.isAfter(startDate));

        double totalIncome = 0;
        double totalExpense = 0;

        for (final t in filtered) {
          if (t.type == TransactionType.income) {
            totalIncome += t.amount;
          } else {
            totalExpense += t.amount;
          }
        }

        final balance = totalIncome - totalExpense;
        final total = totalIncome + totalExpense;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income vs Expense',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  period.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Income',
                        totalIncome,
                        currencySymbol,
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Expense',
                        totalExpense,
                        currencySymbol,
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Balance bar
                if (total > 0) ...[
                  Row(
                    children: [
                      Text(
                        'Balance: ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '$currencySymbol${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (totalIncome / total * 100).round(),
                          child: Container(
                            height: 8,
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          flex: (totalExpense / total * 100).round(),
                          child: Container(
                            height: 8,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => Card(
        child: Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    double amount,
    String currencySymbol,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$currencySymbol${amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

/// Monthly spending trend chart
class SpendingTrendChart extends ConsumerWidget {
  final int monthsToShow;

  const SpendingTrendChart({
    super.key,
    this.monthsToShow = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final monthlyData = _calculateMonthlyData(transactions);

        if (monthlyData.isEmpty) {
          return const SizedBox.shrink();
        }

        final maxY = monthlyData.values
                .map((m) => m['expense']! > m['income']!
                    ? m['expense']!
                    : m['income']!)
                .reduce((a, b) => a > b ? a : b) *
            1.2;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Monthly Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    _buildLegendItem(context, 'Income', Colors.green),
                    const SizedBox(width: 16),
                    _buildLegendItem(context, 'Expense', Colors.red),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final month = monthlyData.keys.toList()[groupIndex];
                            final data = monthlyData[month]!;
                            final label = rodIndex == 0 ? 'Income' : 'Expense';
                            final amount = rodIndex == 0
                                ? data['income']!
                                : data['expense']!;
                            return BarTooltipItem(
                              '$label\n$currencySymbol${amount.toStringAsFixed(0)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final months = monthlyData.keys.toList();
                              if (value.toInt() >= months.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  DateFormat('MMM').format(months[value.toInt()]),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                _formatAxisLabel(value),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline,
                                  fontSize: 10,
                                ),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      barGroups: monthlyData.entries
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final data = entry.value.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: data['income']!,
                              color: Colors.green,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                            BarChartRodData(
                              toY: data['expense']!,
                              color: Colors.red,
                              width: 10,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Map<DateTime, Map<String, double>> _calculateMonthlyData(
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    final monthlyData = <DateTime, Map<String, double>>{};

    // Initialize months
    for (int i = monthsToShow - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      monthlyData[month] = {'income': 0.0, 'expense': 0.0};
    }

    // Aggregate transactions
    for (final t in transactions) {
      final month = DateTime(t.date.year, t.date.month, 1);
      if (monthlyData.containsKey(month)) {
        if (t.type == TransactionType.income) {
          monthlyData[month]!['income'] =
              monthlyData[month]!['income']! + t.amount;
        } else {
          monthlyData[month]!['expense'] =
              monthlyData[month]!['expense']! + t.amount;
        }
      }
    }

    return monthlyData;
  }

  String _formatAxisLabel(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// Category breakdown list with progress bars
class CategoryBreakdownList extends ConsumerWidget {
  final TransactionType transactionType;
  final ChartPeriod period;

  const CategoryBreakdownList({
    super.key,
    this.transactionType = TransactionType.expense,
    this.period = ChartPeriod.month,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);

    return transactionsAsync.when(
      data: (transactions) {
        final filtered = transactions.where((t) {
          return t.type == transactionType &&
              t.date.isAfter(period.startDate);
        }).toList();

        final categoryTotals = <TransactionCategory, double>{};
        for (final t in filtered) {
          final category = DefaultCategories.getById(t.categoryId);
          if (category != null) {
            categoryTotals[category] = (categoryTotals[category] ?? 0) + t.amount;
          }
        }

        final sortedEntries = categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

        if (sortedEntries.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transactionType == TransactionType.expense
                      ? 'Expense Breakdown'
                      : 'Income Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                ...sortedEntries.map((entry) {
                  final category = entry.key;
                  final amount = entry.value;
                  final percentage = total > 0 ? (amount / total) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: category.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                category.icon,
                                color: category.color,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '$currencySymbol${amount.toStringAsFixed(2)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: category.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: category.color.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(category.color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
