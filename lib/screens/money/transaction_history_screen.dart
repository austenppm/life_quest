import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/money_provider.dart';
import 'edit_transaction_sheet.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState
    extends ConsumerState<TransactionHistoryScreen> {
  TransactionType? _filterType;
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    var transactions = ref.watch(selectedMonthTransactionsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    // Apply filters
    if (_filterType != null) {
      transactions = transactions.where((t) => t.type == _filterType).toList();
    }
    if (_filterCategoryId != null) {
      transactions =
          transactions.where((t) => t.categoryId == _filterCategoryId).toList();
    }

    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};
    for (final t in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(t.date);
      groupedTransactions.putIfAbsent(dateKey, () => []).add(t);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final hasFilter = _filterType != null || _filterCategoryId != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(DateFormat('MMMM yyyy').format(selectedMonth)),
        actions: [
          if (hasFilter)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              tooltip: 'Clear filters',
              onPressed: () {
                setState(() {
                  _filterType = null;
                  _filterCategoryId = null;
                });
              },
            ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasFilter ? AppColors.primary : null,
            ),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: transactions.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateKey = sortedDates[index];
                final dayTransactions = groupedTransactions[dateKey]!;
                final date = DateTime.parse(dateKey);

                return _DaySection(
                  date: date,
                  transactions: dayTransactions,
                  onTransactionTap: (t) => _showTransactionDetails(context, t),
                );
              },
            ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Transactions',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 20),
            const Text('Type',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterType == null,
                  onSelected: (_) {
                    setState(() => _filterType = null);
                    Navigator.pop(ctx);
                  },
                ),
                ChoiceChip(
                  label: const Text('Expenses'),
                  selected: _filterType == TransactionType.expense,
                  onSelected: (_) {
                    setState(() => _filterType = TransactionType.expense);
                    Navigator.pop(ctx);
                  },
                ),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: _filterType == TransactionType.income,
                  onSelected: (_) {
                    setState(() => _filterType = TransactionType.income);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filterCategoryId == null,
                  onSelected: (_) {
                    setState(() => _filterCategoryId = null);
                    Navigator.pop(ctx);
                  },
                ),
                ...DefaultCategories.all.map((cat) => ChoiceChip(
                      label: Text(cat.name),
                      selected: _filterCategoryId == cat.id,
                      avatar: Icon(cat.icon, size: 16, color: cat.color),
                      onSelected: (_) {
                        setState(() => _filterCategoryId = cat.id);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTransactionDetails(
      BuildContext context, Transaction transaction) {
    final category = DefaultCategories.getById(transaction.categoryId);
    final currency = ref.read(currencyProvider);
    final currencyFormat = NumberFormat.currency(symbol: currency.symbol, decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (category?.color ?? AppColors.primary).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                category?.icon ?? Icons.attach_money,
                color: category?.color ?? AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              category?.name ?? 'Unknown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${transaction.type == TransactionType.expense ? '-' : '+'}'
              '${currencyFormat.format(transaction.amount)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: transaction.type == TransactionType.expense
                        ? AppColors.error
                        : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (transaction.note != null && transaction.note!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note, color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        transaction.note!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(transaction.date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, transaction);
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    label: const Text('Delete',
                        style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTransaction(context, transaction);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditTransaction(BuildContext context, Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditTransactionSheet(transaction: transaction),
    );
  }

  void _confirmDelete(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(transactionNotifierProvider.notifier)
                  .deleteTransaction(transaction.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your money!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DateTime date;
  final List<Transaction> transactions;
  final Function(Transaction) onTransactionTap;

  const _DaySection({
    required this.date,
    required this.transactions,
    required this.onTransactionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayTotal = transactions.fold<double>(0, (sum, t) {
      return t.type == TransactionType.expense
          ? sum - t.amount
          : sum + t.amount;
    });

    final currency = ref.watch(currencyProvider);
    final currencyFormat = NumberFormat.currency(symbol: currency.symbol, decimalDigits: 2);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
        date, DateTime.now().subtract(const Duration(days: 1)));

    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                currencyFormat.format(dayTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: dayTotal >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        ...transactions.map((t) => _TransactionTile(
              transaction: t,
              onTap: () => onTransactionTap(t),
            )),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  final Transaction transaction;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = DefaultCategories.getById(transaction.categoryId);
    final currency = ref.watch(currencyProvider);
    final currencyFormat = NumberFormat.currency(symbol: currency.symbol, decimalDigits: 2);
    final isExpense = transaction.type == TransactionType.expense;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (category?.color ?? AppColors.primary).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category?.icon ?? Icons.attach_money,
                color: category?.color ?? AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Text(
                      transaction.note!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}${currencyFormat.format(transaction.amount)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isExpense ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
