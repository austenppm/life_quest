import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/water_intake.dart';
import '../../providers/water_provider.dart';

class WaterTrackingScreen extends ConsumerStatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  ConsumerState<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends ConsumerState<WaterTrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(todayWaterSummaryProvider);
    final settings = ref.watch(waterSettingsProvider);
    final streakAsync = ref.watch(waterStreakProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress Circle
            _WaterProgressCircle(summary: summary),
            const SizedBox(height: 24),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Goal',
                    value: '${(settings.dailyGoal / 1000).toStringAsFixed(1)}L',
                    icon: Icons.flag,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Remaining',
                    value: '${(summary.remaining / 1000).toStringAsFixed(1)}L',
                    icon: Icons.water_drop_outlined,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Streak',
                    value: '${streakAsync.valueOrNull ?? 0} days',
                    icon: Icons.local_fire_department,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick Add Buttons
            const Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _QuickAddButtons(settings: settings),
            const SizedBox(height: 24),

            // Today's Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Log",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (summary.logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(waterIntakeNotifierProvider.notifier).undoLastIntake();
                    },
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Undo'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _TodayLogList(logs: summary.logs),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCustomAddDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Custom'),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _WaterSettingsSheet(),
    );
  }

  void _showCustomAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _CustomWaterAddSheet(),
    );
  }
}

class _WaterProgressCircle extends StatelessWidget {
  final DailyWaterSummary summary;

  const _WaterProgressCircle({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: summary.percentComplete.clamp(0, 1),
                    strokeWidth: 12,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(
                      summary.goalReached ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      size: 40,
                      color: summary.goalReached ? Colors.green : AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${summary.totalAmount.toInt()} ml',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(summary.percentComplete * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: summary.goalReached ? Colors.green : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (summary.goalReached) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daily Goal Reached!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              '${summary.glassesRemaining} glasses to go',
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddButtons extends ConsumerWidget {
  final WaterSettings settings;

  const _QuickAddButtons({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _QuickAddButton(
          amount: 250,
          label: 'Glass',
          icon: Icons.local_drink,
          onTap: () => ref.read(waterIntakeNotifierProvider.notifier).quickAdd(250),
        ),
        _QuickAddButton(
          amount: 350,
          label: 'Small',
          icon: Icons.local_cafe,
          onTap: () => ref.read(waterIntakeNotifierProvider.notifier).quickAdd(350),
        ),
        _QuickAddButton(
          amount: 500,
          label: 'Bottle',
          icon: Icons.liquor,
          onTap: () => ref.read(waterIntakeNotifierProvider.notifier).quickAdd(500),
        ),
        _QuickAddButton(
          amount: 750,
          label: 'Large',
          icon: Icons.sports_bar,
          onTap: () => ref.read(waterIntakeNotifierProvider.notifier).quickAdd(750),
        ),
      ],
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final double amount;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.amount,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 4),
            Text(
              '${amount.toInt()}ml',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayLogList extends StatelessWidget {
  final List<WaterIntake> logs;

  const _TodayLogList({required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.water_drop_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 8),
              Text(
                'No water logged today',
                style: TextStyle(color: AppColors.textMuted),
              ),
              Text(
                'Tap the buttons above to start!',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: logs.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.surfaceLight),
        itemBuilder: (context, index) {
          final log = logs[index];
          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop, color: AppColors.primary, size: 20),
            ),
            title: Text(
              '${log.amount.toInt()} ml',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              log.containerType.displayName,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing: Text(
              DateFormat('h:mm a').format(log.timestamp),
              style: const TextStyle(color: AppColors.textMuted),
            ),
          );
        },
      ),
    );
  }
}

class _WaterSettingsSheet extends ConsumerWidget {
  const _WaterSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(waterSettingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Water Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Daily Goal
          const Text(
            'Daily Goal',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WaterSettings.goalPresets.map((goal) {
              final isSelected = settings.dailyGoal == goal;
              return GestureDetector(
                onTap: () {
                  ref.read(waterSettingsProvider.notifier).setDailyGoal(goal);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    ),
                  ),
                  child: Text(
                    '${(goal / 1000).toStringAsFixed(1)}L',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Reminders Toggle
          SwitchListTile(
            title: const Text('Water Reminders'),
            subtitle: Text(
              settings.remindersEnabled
                  ? 'Every ${settings.reminderIntervalMinutes} minutes'
                  : 'Disabled',
            ),
            value: settings.remindersEnabled,
            onChanged: (value) {
              ref.read(waterSettingsProvider.notifier).setRemindersEnabled(value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomWaterAddSheet extends ConsumerStatefulWidget {
  const _CustomWaterAddSheet();

  @override
  ConsumerState<_CustomWaterAddSheet> createState() => _CustomWaterAddSheetState();
}

class _CustomWaterAddSheetState extends ConsumerState<_CustomWaterAddSheet> {
  final _amountController = TextEditingController(text: '250');
  WaterContainerType _selectedType = WaterContainerType.glass;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Water',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Amount Input
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Amount (ml)',
              suffixText: 'ml',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Container Type
          const Text(
            'Container Type',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WaterContainerType.values
                .where((t) => t != WaterContainerType.custom)
                .map((type) {
              final isSelected = _selectedType == type;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedType = type;
                    if (type.defaultAmount > 0) {
                      _amountController.text = type.defaultAmount.toInt().toString();
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                    ),
                  ),
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text) ?? 250;
                ref.read(waterIntakeNotifierProvider.notifier).addWaterIntake(
                      amount: amount,
                      containerType: _selectedType,
                    );
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ),
        ],
      ),
    );
  }
}
