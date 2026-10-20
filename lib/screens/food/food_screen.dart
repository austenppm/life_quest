import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../theme/app_theme.dart';
import '../../models/food_entry.dart';
import '../../providers/food_provider.dart';
import 'add_food_dialog.dart';
import 'food_detail_screen.dart';

class FoodScreen extends ConsumerStatefulWidget {
  const FoodScreen({super.key});

  @override
  ConsumerState<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends ConsumerState<FoodScreen> {
  double _dragStartX = 0;

  // Tab paths for edge swipe navigation
  static const _tabPaths = ['/home', '/tasks', '/food', '/money', '/profile'];
  static const _currentTabIndex = 2; // Food is index 2

  void _handleSwipe(DragEndDetails details, DateTime selectedDate) {
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
      // Center swipe -> change day
      if (velocity > 0) {
        ref.read(selectedFoodDateProvider.notifier).state =
            selectedDate.subtract(const Duration(days: 1));
      } else {
        final nextDay = selectedDate.add(const Duration(days: 1));
        if (!nextDay.isAfter(DateTime.now())) {
          ref.read(selectedFoodDateProvider.notifier).state = nextDay;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedFoodDateProvider);
    final dailyNutrition = ref.watch(dailyNutritionProvider);
    final breakfastEntries = ref.watch(breakfastEntriesProvider);
    final lunchEntries = ref.watch(lunchEntriesProvider);
    final dinnerEntries = ref.watch(dinnerEntriesProvider);
    final snackEntries = ref.watch(snackEntriesProvider);

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragStart: (details) => _dragStartX = details.globalPosition.dx,
        onHorizontalDragEnd: (details) => _handleSwipe(details, selectedDate),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nutrition',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  _DateSelector(
                    selectedDate: selectedDate,
                    onDateChanged: (date) {
                      ref.read(selectedFoodDateProvider.notifier).state = date;
                    },
                  ),
                ],
              ),
            ),

            // Calorie ring and macros
            _NutritionSummary(nutrition: dailyNutrition),
            const SizedBox(height: 16),

            // Macro breakdown
            _MacroBreakdown(nutrition: dailyNutrition),
            const SizedBox(height: 24),

            // Meal sections
            _MealSection(
              title: 'Breakfast',
              icon: Icons.wb_sunny_outlined,
              color: const Color(0xFFFFB347),
              entries: breakfastEntries,
              mealType: MealType.breakfast,
              date: selectedDate,
            ),
            _MealSection(
              title: 'Lunch',
              icon: Icons.wb_cloudy_outlined,
              color: const Color(0xFF4ECDC4),
              entries: lunchEntries,
              mealType: MealType.lunch,
              date: selectedDate,
            ),
            _MealSection(
              title: 'Dinner',
              icon: Icons.nights_stay_outlined,
              color: const Color(0xFF6C5CE7),
              entries: dinnerEntries,
              mealType: MealType.dinner,
              date: selectedDate,
            ),
            _MealSection(
              title: 'Snacks',
              icon: Icons.cookie_outlined,
              color: const Color(0xFFFF85A2),
              entries: snackEntries,
              mealType: MealType.snack,
              date: selectedDate,
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodDialog(context, selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('Add Food'),
        backgroundColor: AppColors.constitution,
      ),
    );
  }

  void _showAddFoodDialog(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodDialog(date: date),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
      selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    String label;
    if (isToday) {
      label = 'Today';
    } else if (isYesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMM d').format(selectedDate);
    }

    return Row(
      children: [
        IconButton(
          onPressed: () {
            onDateChanged(selectedDate.subtract(const Duration(days: 1)));
          },
          icon: const Icon(Icons.chevron_left),
          iconSize: 20,
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          onPressed: isToday
              ? null
              : () {
                  onDateChanged(selectedDate.add(const Duration(days: 1)));
                },
          icon: Icon(
            Icons.chevron_right,
            color: isToday ? AppColors.textMuted : null,
          ),
          iconSize: 20,
        ),
      ],
    );
  }
}

class _NutritionSummary extends StatelessWidget {
  final DailyNutrition nutrition;

  const _NutritionSummary({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final progress = nutrition.calorieProgress.clamp(0.0, 1.0);
    final isOverGoal = nutrition.totalCalories > nutrition.calorieGoal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Calorie ring
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(
                      isOverGoal ? AppColors.error : AppColors.constitution,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${nutrition.totalCalories}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOverGoal ? AppColors.error : null,
                          ),
                    ),
                    Text(
                      'of ${nutrition.calorieGoal}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    const Text(
                      'kcal',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Remaining/over
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverGoal ? 'Over by' : 'Remaining',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
                Text(
                  '${nutrition.remainingCalories.abs()}',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isOverGoal ? AppColors.error : AppColors.success,
                      ),
                ),
                Text(
                  'calories',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBreakdown extends StatelessWidget {
  final DailyNutrition nutrition;

  const _MacroBreakdown({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MacroCard(
              label: 'Protein',
              value: nutrition.totalProtein,
              goal: nutrition.proteinGoal,
              unit: 'g',
              color: const Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroCard(
              label: 'Carbs',
              value: nutrition.totalCarbs,
              goal: nutrition.carbsGoal,
              unit: 'g',
              color: const Color(0xFF4ECDC4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MacroCard(
              label: 'Fat',
              value: nutrition.totalFat,
              goal: nutrition.fatGoal,
              unit: 'g',
              color: const Color(0xFFFFD93D),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  const _MacroCard({
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${value.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '/ ${goal.toInt()}$unit',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<FoodEntry> entries;
  final MealType mealType;
  final DateTime date;

  const _MealSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.entries,
    required this.mealType,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalCalories = entries.fold(0, (sum, e) => sum + e.calories);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$totalCalories kcal',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAddFoodForMeal(context, mealType, date),
                  icon: Icon(Icons.add_circle, color: color),
                ),
              ],
            ),
          ),
          // Entries
          if (entries.isNotEmpty)
            ...entries.map((entry) => _FoodEntryTile(
                  entry: entry,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FoodDetailScreen(entry: entry),
                      ),
                    );
                  },
                )),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'No entries yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddFoodForMeal(BuildContext context, MealType mealType, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddFoodDialog(
        date: date,
        initialMealType: mealType,
      ),
    );
  }
}

class _FoodEntryTile extends ConsumerWidget {
  final FoodEntry entry;
  final VoidCallback onTap;

  const _FoodEntryTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Delete the entry
        ref.read(foodNotifierProvider.notifier).deleteFoodEntry(entry.id);

        // Show undo snackbar
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.hideCurrentSnackBar();
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('${entry.name} deleted'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: AppColors.primary,
              onPressed: () {
                // Restore the entry
                ref.read(foodNotifierProvider.notifier).addFoodEntry(
                  name: entry.name,
                  mealType: entry.mealType,
                  calories: entry.calories,
                  protein: entry.protein,
                  carbs: entry.carbs,
                  fat: entry.fat,
                  fiber: entry.fiber,
                  sugar: entry.sugar,
                  servingSize: entry.servingSize,
                  servingUnit: entry.servingUnit,
                  date: entry.date,
                );
              },
            ),
            duration: const Duration(seconds: 4),
          ),
        );

        // Return false to prevent Dismissible from removing the widget
        // (we already deleted it in the provider)
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${entry.servingSize.toStringAsFixed(entry.servingSize == entry.servingSize.roundToDouble() ? 0 : 1)} ${entry.servingUnit}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.calories} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'P:${entry.protein.toInt()} C:${entry.carbs.toInt()} F:${entry.fat.toInt()}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
      ),
    );
  }
}
