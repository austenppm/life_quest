import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../providers/food_provider.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final FoodEntry entry;

  const FoodDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late TextEditingController _nameController;
  late TextEditingController _servingSizeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _notesController;
  late MealType _selectedMealType;
  late PortionUnit _selectedPortionUnit;
  late DateTime _selectedDate;
  bool _isEditing = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.entry.name);
    _servingSizeController = TextEditingController(
      text: widget.entry.formattedServingSize,
    );
    _caloriesController = TextEditingController(
      text: widget.entry.calories.toString(),
    );
    _proteinController = TextEditingController(
      text: widget.entry.protein.toStringAsFixed(1),
    );
    _carbsController = TextEditingController(
      text: widget.entry.carbs.toStringAsFixed(1),
    );
    _fatController = TextEditingController(
      text: widget.entry.fat.toStringAsFixed(1),
    );
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _selectedMealType = widget.entry.mealType;
    _selectedPortionUnit = widget.entry.portionUnit;
    _selectedDate = widget.entry.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset changes
        _initControllers();
        _hasChanges = false;
      }
    });
  }

  Future<void> _saveChanges() async {
    final servingSize = double.tryParse(_servingSizeController.text) ?? 1;
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;

    await ref.read(foodNotifierProvider.notifier).updateFoodEntry(
      widget.entry.id,
      name: _nameController.text,
      mealType: _selectedMealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servingSize: servingSize,
      portionUnit: _selectedPortionUnit,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (mounted) {
      setState(() {
        _isEditing = false;
        _hasChanges = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food entry updated'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showMoveDialog() async {
    DateTime targetDate = _selectedDate;
    MealType targetMeal = _selectedMealType;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MoveDialog(
        initialDate: targetDate,
        initialMealType: targetMeal,
      ),
    );

    if (result != null && mounted) {
      await ref.read(foodNotifierProvider.notifier).moveFoodEntry(
        widget.entry.id,
        newDate: result['date'],
        newMealType: result['mealType'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food moved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showCopyDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _MoveDialog(
        initialDate: DateTime.now(),
        initialMealType: _selectedMealType,
        isCopy: true,
      ),
    );

    if (result != null && mounted) {
      await ref.read(foodNotifierProvider.notifier).copyFoodEntry(
        widget.entry,
        targetDate: result['date'],
        targetMealType: result['mealType'],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food copied successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(foodNotifierProvider.notifier).deleteFoodEntry(widget.entry.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Food' : 'Food Details'),
        actions: [
          if (!_isEditing) ...[
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: 'Copy to another day',
              onPressed: _showCopyDialog,
            ),
            IconButton(
              icon: const Icon(Icons.move_up),
              tooltip: 'Move to another day',
              onPressed: _showMoveDialog,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEdit,
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleEdit,
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food name
            _buildTextField(
              label: 'Name',
              controller: _nameController,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),

            // Serving size and unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    label: 'Serving Size',
                    controller: _servingSizeController,
                    enabled: _isEditing,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildPortionDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Meal type
            _buildMealTypeSelector(),
            const SizedBox(height: 16),

            // Date
            if (_isEditing) _buildDateSelector(),
            if (!_isEditing)
              _buildInfoRow(
                'Date',
                DateFormat('EEEE, MMM d, yyyy').format(widget.entry.date),
                Icons.calendar_today,
              ),
            const SizedBox(height: 24),

            // Nutrition section
            Text(
              'Nutrition Facts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Main macros
            _buildNutritionCard(),
            const SizedBox(height: 16),

            // Extended nutrition if available
            if (widget.entry.hasExtendedNutrition || _isEditing)
              _buildExtendedNutrition(),

            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              label: 'Notes',
              controller: _notesController,
              enabled: _isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Delete button
            if (!_isEditing)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: const Text('Delete Entry', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() => _hasChanges = true),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? AppColors.card : AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildPortionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _isEditing ? AppColors.card : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: _isEditing
            ? Border.all(color: AppColors.primary.withOpacity(0.3))
            : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PortionUnit>(
          value: _selectedPortionUnit,
          isExpanded: true,
          items: PortionUnit.values.map((unit) {
            return DropdownMenuItem(
              value: unit,
              child: Text(unit.displayName),
            );
          }).toList(),
          onChanged: _isEditing
              ? (value) {
                  if (value != null) {
                    setState(() {
                      _selectedPortionUnit = value;
                      _hasChanges = true;
                    });
                  }
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Type',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: MealType.values.map((meal) {
            final isSelected = _selectedMealType == meal;
            final color = _getMealColor(meal);
            return Expanded(
              child: GestureDetector(
                onTap: _isEditing
                    ? () {
                        setState(() {
                          _selectedMealType = meal;
                          _hasChanges = true;
                        });
                      }
                    : null,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.2) : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : AppColors.surfaceLight,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getMealIcon(meal),
                        color: isSelected ? color : AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meal.name[0].toUpperCase() + meal.name.substring(1),
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? color : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
            _hasChanges = true;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 20),
            const SizedBox(width: 12),
            Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Calories
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('Calories', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_isEditing)
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    onChanged: (_) => setState(() => _hasChanges = true),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              else
                Text(
                  '${widget.entry.calories} kcal',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          // Macros
          Row(
            children: [
              Expanded(child: _buildMacroItem('Protein', _proteinController, const Color(0xFFFF6B6B))),
              Expanded(child: _buildMacroItem('Carbs', _carbsController, const Color(0xFF4ECDC4))),
              Expanded(child: _buildMacroItem('Fat', _fatController, const Color(0xFFFFD93D))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, TextEditingController controller, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        if (_isEditing)
          SizedBox(
            width: 60,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() => _hasChanges = true),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
            ),
          )
        else
          Text(
            '${double.parse(controller.text).toStringAsFixed(1)}g',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildExtendedNutrition() {
    final entry = widget.entry;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Nutrition',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (entry.fiber != null) _buildNutritionRow('Fiber', entry.fiber!, 'g'),
          if (entry.sugar != null) _buildNutritionRow('Sugar', entry.sugar!, 'g'),
          if (entry.saturatedFat != null) _buildNutritionRow('Saturated Fat', entry.saturatedFat!, 'g'),
          if (entry.polyunsaturatedFat != null) _buildNutritionRow('Polyunsaturated Fat', entry.polyunsaturatedFat!, 'g'),
          if (entry.monounsaturatedFat != null) _buildNutritionRow('Monounsaturated Fat', entry.monounsaturatedFat!, 'g'),
          if (entry.transFat != null) _buildNutritionRow('Trans Fat', entry.transFat!, 'g'),
          if (entry.cholesterol != null) _buildNutritionRow('Cholesterol', entry.cholesterol!, 'mg'),
          if (entry.sodium != null) _buildNutritionRow('Sodium', entry.sodium!, 'mg'),
          if (entry.potassium != null) _buildNutritionRow('Potassium', entry.potassium!, 'mg'),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          Text('${value.toStringAsFixed(1)} $unit'),
        ],
      ),
    );
  }

  Color _getMealColor(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return const Color(0xFFFFB347);
      case MealType.morningSnack:
        return const Color(0xFFE8A87C);
      case MealType.lunch:
        return const Color(0xFF4ECDC4);
      case MealType.afternoonSnack:
        return const Color(0xFF85C1E9);
      case MealType.dinner:
        return const Color(0xFF6C5CE7);
      case MealType.eveningSnack:
        return const Color(0xFFAF7AC5);
      case MealType.snack:
        return const Color(0xFFFF85A2);
      case MealType.preWorkout:
        return const Color(0xFF58D68D);
      case MealType.postWorkout:
        return const Color(0xFF5DADE2);
      case MealType.supper:
        return const Color(0xFFD7BDE2);
    }
  }

  IconData _getMealIcon(MealType meal) {
    switch (meal) {
      case MealType.breakfast:
        return Icons.wb_sunny_outlined;
      case MealType.morningSnack:
        return Icons.coffee_outlined;
      case MealType.lunch:
        return Icons.wb_cloudy_outlined;
      case MealType.afternoonSnack:
        return Icons.icecream_outlined;
      case MealType.dinner:
        return Icons.nights_stay_outlined;
      case MealType.eveningSnack:
        return Icons.bedtime_outlined;
      case MealType.snack:
        return Icons.cookie_outlined;
      case MealType.preWorkout:
        return Icons.fitness_center_outlined;
      case MealType.postWorkout:
        return Icons.sports_score_outlined;
      case MealType.supper:
        return Icons.local_dining_outlined;
    }
  }
}

class _MoveDialog extends StatefulWidget {
  final DateTime initialDate;
  final MealType initialMealType;
  final bool isCopy;

  const _MoveDialog({
    required this.initialDate,
    required this.initialMealType,
    this.isCopy = false,
  });

  @override
  State<_MoveDialog> createState() => _MoveDialogState();
}

class _MoveDialogState extends State<_MoveDialog> {
  late DateTime _selectedDate;
  late MealType _selectedMealType;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedMealType = widget.initialMealType;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isCopy ? 'Copy to...' : 'Move to...'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Date picker
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          const Divider(),
          // Meal type selector
          ...MealType.values.map((meal) {
            return RadioListTile<MealType>(
              title: Text(meal.name[0].toUpperCase() + meal.name.substring(1)),
              value: meal,
              groupValue: _selectedMealType,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMealType = value);
                }
              },
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'date': _selectedDate,
              'mealType': _selectedMealType,
            });
          },
          child: Text(widget.isCopy ? 'Copy' : 'Move'),
        ),
      ],
    );
  }
}
