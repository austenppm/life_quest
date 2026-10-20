import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/transaction.dart';
import '../../providers/money_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final TransactionCategory? initialCategory;
  final TransactionType initialType;

  const AddTransactionSheet({
    super.key,
    this.initialCategory,
    this.initialType = TransactionType.expense,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late TransactionType _type;
  late TransactionCategory? _selectedCategory;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _displayAmount = '0';
  // Recurring payment fields
  bool _isRecurring = false;
  RecurrenceType _recurrenceType = RecurrenceType.monthly;
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _categories {
    return _type == TransactionType.expense
        ? DefaultCategories.expenses
        : DefaultCategories.incomes;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with type toggle
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeToggle(
                        type: _type,
                        onChanged: (type) {
                          setState(() {
                            _type = type;
                            _selectedCategory = null;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // Amount display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Text(
                      _type == TransactionType.expense ? 'Expense' : 'Income',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${ref.watch(currencyProvider).symbol}$_displayAmount',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _type == TransactionType.expense
                                ? AppColors.error
                                : AppColors.success,
                          ),
                    ),
                  ],
                ),
              ),

              // Category selector
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = category),
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? category.color
                                    : category.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: Icon(
                                category.icon,
                                color: isSelected ? Colors.white : category.color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 56,
                              child: Text(
                                category.name,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isSelected
                                          ? AppColors.textPrimary
                                          : AppColors.textMuted,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : null,
                                      fontSize: 10,
                                    ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Note field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Add note (optional)',
                    prefixIcon: const Icon(Icons.note_outlined),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Date selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Recurring payment toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.repeat, size: 20),
                          const SizedBox(width: 12),
                          const Text('Recurring Payment'),
                          const Spacer(),
                          Switch(
                            value: _isRecurring,
                            onChanged: (value) {
                              setState(() => _isRecurring = value);
                            },
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                      if (_isRecurring) ...[
                        const Divider(),
                        Row(
                          children: [
                            const Text('Repeat:', style: TextStyle(color: AppColors.textMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<RecurrenceType>(
                                  value: _recurrenceType,
                                  isExpanded: true,
                                  items: RecurrenceType.values.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type.displayName),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _recurrenceType = value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectEndDate,
                          child: Row(
                            children: [
                              const Text('End date:', style: TextStyle(color: AppColors.textMuted)),
                              const SizedBox(width: 12),
                              Text(
                                _recurrenceEndDate != null
                                    ? DateFormat('MMM d, yyyy').format(_recurrenceEndDate!)
                                    : 'No end date',
                                style: TextStyle(
                                  color: _recurrenceEndDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                ),
                              ),
                              const Spacer(),
                              if (_recurrenceEndDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() => _recurrenceEndDate = null);
                                  },
                                )
                              else
                                const Icon(Icons.chevron_right, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Numpad
              _Numpad(
                onDigit: _onDigit,
                onBackspace: _onBackspace,
                onDecimal: _onDecimal,
                onConfirm: _onConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onDigit(String digit) {
    setState(() {
      if (_displayAmount == '0') {
        _displayAmount = digit;
      } else if (_displayAmount.length < 10) {
        _displayAmount += digit;
      }
    });
  }

  void _onBackspace() {
    setState(() {
      if (_displayAmount.length > 1) {
        _displayAmount = _displayAmount.substring(0, _displayAmount.length - 1);
      } else {
        _displayAmount = '0';
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (!_displayAmount.contains('.')) {
        _displayAmount += '.';
      }
    });
  }

  void _onConfirm() {
    final amount = double.tryParse(_displayAmount) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    ref.read(transactionNotifierProvider.notifier).addTransaction(
          type: _type,
          amount: amount,
          categoryId: _selectedCategory!.id,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          date: _selectedDate,
          isRecurring: _isRecurring,
          recurrenceType: _isRecurring ? _recurrenceType : null,
          recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        );

    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_type == TransactionType.expense ? 'Expense' : 'Income'} added!',
        ),
        backgroundColor: _type == TransactionType.expense
            ? AppColors.error
            : AppColors.success,
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _recurrenceEndDate = picked);
    }
  }
}

class _TypeToggle extends StatelessWidget {
  final TransactionType type;
  final ValueChanged<TransactionType> onChanged;

  const _TypeToggle({
    required this.type,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Expense',
            isSelected: type == TransactionType.expense,
            color: AppColors.error,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _ToggleButton(
            label: 'Income',
            isSelected: type == TransactionType.income,
            color: AppColors.success,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : null,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onDecimal;
  final VoidCallback onConfirm;

  const _Numpad({
    required this.onDigit,
    required this.onBackspace,
    required this.onDecimal,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                _NumpadButton(label: '1', onTap: () => onDigit('1')),
                _NumpadButton(label: '2', onTap: () => onDigit('2')),
                _NumpadButton(label: '3', onTap: () => onDigit('3')),
                _NumpadButton(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                ),
              ],
            ),
            Row(
              children: [
                _NumpadButton(label: '4', onTap: () => onDigit('4')),
                _NumpadButton(label: '5', onTap: () => onDigit('5')),
                _NumpadButton(label: '6', onTap: () => onDigit('6')),
                _NumpadButton(label: '0', onTap: () => onDigit('0')),
              ],
            ),
            Row(
              children: [
                _NumpadButton(label: '7', onTap: () => onDigit('7')),
                _NumpadButton(label: '8', onTap: () => onDigit('8')),
                _NumpadButton(label: '9', onTap: () => onDigit('9')),
                _NumpadButton(
                  label: '.',
                  onTap: onDecimal,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Add Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _NumpadButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(icon, color: AppColors.textPrimary)
                  : Text(
                      label ?? '',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
