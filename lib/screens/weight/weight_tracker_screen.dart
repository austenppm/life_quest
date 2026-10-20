import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/weight_entry.dart';
import '../../providers/weight_provider.dart';

class WeightTrackerScreen extends ConsumerStatefulWidget {
  const WeightTrackerScreen({super.key});

  @override
  ConsumerState<WeightTrackerScreen> createState() => _WeightTrackerScreenState();
}

class _WeightTrackerScreenState extends ConsumerState<WeightTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(weightEntriesProvider);
    final stats = ref.watch(weightStatsProvider);
    final goal = ref.watch(weightGoalProvider).valueOrNull;
    final hasLoggedToday = ref.watch(hasLoggedTodayProvider);
    final unit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Weight Tracker'),
        actions: [
          // Unit toggle
          TextButton(
            onPressed: () {
              ref.read(weightUnitProvider.notifier).state =
                  unit == WeightUnit.kg ? WeightUnit.lbs : WeightUnit.kg;
            },
            child: Text(
              unit == WeightUnit.kg ? 'KG' : 'LBS',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showGoalDialog(context, stats.currentWeight, unit),
            tooltip: 'Set Goal',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) => TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(
              entries: entries,
              stats: stats,
              goal: goal,
              unit: unit,
              hasLoggedToday: hasLoggedToday,
            ),
            _HistoryTab(entries: entries, unit: unit),
            _StatsTab(stats: stats, unit: unit),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEntryDialog(context),
        icon: Icon(
          hasLoggedToday ? Icons.edit : Icons.add,
          color: Colors.white,
        ),
        label: Text(
          hasLoggedToday ? 'Update' : 'Log Weight',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: hasLoggedToday ? AppColors.success : AppColors.primary,
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddWeightEntrySheet(),
    );
  }

  void _showGoalDialog(BuildContext context, double currentWeight, WeightUnit unit) {
    showDialog(
      context: context,
      builder: (context) => _SetGoalDialog(
        currentWeight: currentWeight,
        unit: unit,
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final List<WeightEntry> entries;
  final WeightStats stats;
  final WeightGoal? goal;
  final WeightUnit unit;
  final bool hasLoggedToday;

  const _OverviewTab({
    required this.entries,
    required this.stats,
    required this.goal,
    required this.unit,
    required this.hasLoggedToday,
  });

  @override
  Widget build(BuildContext context) {
    final displayWeight = unit == WeightUnit.kg
        ? stats.currentWeight
        : stats.currentWeight * 2.20462;
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Weight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.constitution.withOpacity(0.8),
                  AppColors.constitution.withOpacity(0.4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Current Weight',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      entries.isEmpty ? '--' : displayWeight.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        unitLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                if (stats.weeklyChange != 0) ...[
                  const SizedBox(height: 8),
                  _ChangeChip(
                    change: unit == WeightUnit.kg
                        ? stats.weeklyChange
                        : stats.weeklyChange * 2.20462,
                    label: 'this week',
                    unit: unitLabel,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Goal Progress (if set)
          if (goal != null) _GoalProgressCard(goal: goal!, stats: stats, unit: unit),
          if (goal != null) const SizedBox(height: 16),

          // Quick Stats Row
          Row(
            children: [
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.local_fire_department,
                  title: 'Streak',
                  value: '${stats.currentStreak}',
                  subtitle: 'days',
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStatCard(
                  icon: Icons.format_list_numbered,
                  title: 'Entries',
                  value: '${stats.totalEntries}',
                  subtitle: 'logged',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickStatCard(
                  icon: hasLoggedToday ? Icons.check_circle : Icons.schedule,
                  title: 'Today',
                  value: hasLoggedToday ? '✓' : '−',
                  subtitle: hasLoggedToday ? 'logged' : 'pending',
                  color: hasLoggedToday ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weight Chart
          Text(
            'Last 30 Days',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _WeightChart(entries: entries, unit: unit),
          ),
          const SizedBox(height: 24),

          // Tips Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pro Tips',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '• Weigh yourself at the same time daily (morning is best)\n'
                  '• Log consistently to see accurate trends\n'
                  '• Weight fluctuates - focus on weekly averages\n'
                  '• Earn XP for every log to boost Constitution!',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
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

class _HistoryTab extends ConsumerWidget {
  final List<WeightEntry> entries;
  final WeightUnit unit;

  const _HistoryTab({required this.entries, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No weight entries yet',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to log your first entry',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final groupedEntries = _groupEntriesByMonth(entries);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedEntries.length,
      itemBuilder: (context, index) {
        final month = groupedEntries.keys.elementAt(index);
        final monthEntries = groupedEntries[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                month,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ),
            ...monthEntries.map((entry) => _WeightEntryTile(
                  entry: entry,
                  unit: unit,
                  onTap: () => _showEntryDetails(context, ref, entry),
                  onDelete: () => _deleteEntry(context, ref, entry),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Map<String, List<WeightEntry>> _groupEntriesByMonth(List<WeightEntry> entries) {
    final grouped = <String, List<WeightEntry>>{};
    for (final entry in entries) {
      final month = DateFormat('MMMM yyyy').format(entry.date);
      grouped.putIfAbsent(month, () => []).add(entry);
    }
    return grouped;
  }

  void _showEntryDetails(BuildContext context, WidgetRef ref, WeightEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryDetailsSheet(entry: entry),
    );
  }

  void _deleteEntry(BuildContext context, WidgetRef ref, WeightEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text(
          'Delete weight entry from ${DateFormat('MMM d, yyyy').format(entry.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(weightNotifierProvider.notifier).deleteWeightEntry(entry.id);
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

class _StatsTab extends StatelessWidget {
  final WeightStats stats;
  final WeightUnit unit;

  const _StatsTab({required this.stats, required this.unit});

  @override
  Widget build(BuildContext context) {
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';
    final multiplier = unit == WeightUnit.kg ? 1.0 : 2.20462;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All-time stats
          Text(
            'All-Time Statistics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _StatRow(
            label: 'Lowest Weight',
            value: '${(stats.lowestWeight * multiplier).toStringAsFixed(1)} $unitLabel',
            icon: Icons.arrow_downward,
            color: AppColors.success,
          ),
          _StatRow(
            label: 'Highest Weight',
            value: '${(stats.highestWeight * multiplier).toStringAsFixed(1)} $unitLabel',
            icon: Icons.arrow_upward,
            color: AppColors.error,
          ),
          _StatRow(
            label: 'Average Weight',
            value: '${(stats.averageWeight * multiplier).toStringAsFixed(1)} $unitLabel',
            icon: Icons.straighten,
            color: AppColors.primary,
          ),
          _StatRow(
            label: 'Total Change',
            value: '${stats.totalChange >= 0 ? '+' : ''}${(stats.totalChange * multiplier).toStringAsFixed(1)} $unitLabel',
            icon: Icons.trending_flat,
            color: stats.totalChange >= 0 ? AppColors.error : AppColors.success,
          ),
          const SizedBox(height: 24),

          // Recent changes
          Text(
            'Recent Changes',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ChangeCard(
                  title: 'Weekly',
                  change: stats.weeklyChange * multiplier,
                  unit: unitLabel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ChangeCard(
                  title: 'Monthly',
                  change: stats.monthlyChange * multiplier,
                  unit: unitLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Consistency
          Text(
            'Consistency',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${stats.currentStreak}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Keep logging daily to maintain your streak!',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.local_fire_department,
                  color: AppColors.accent,
                  size: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;
  final WeightUnit unit;

  const _WeightChart({required this.entries, required this.unit});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No data to display',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentEntries = entries
        .where((e) => e.date.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (recentEntries.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No recent data',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final multiplier = unit == WeightUnit.kg ? 1.0 : 2.20462;
    final spots = recentEntries.asMap().entries.map((e) {
      return FlSpot(
        e.key.toDouble(),
        e.value.weightInKg * multiplier,
      );
    }).toList();

    final weights = recentEntries.map((e) => e.weightInKg * multiplier).toList();
    final minY = (weights.reduce((a, b) => a < b ? a : b) - 2).floorToDouble();
    final maxY = (weights.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.surfaceLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (recentEntries.length / 5).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= recentEntries.length) return const SizedBox();
                  return Text(
                    DateFormat('M/d').format(recentEntries[index].date),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.constitution,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) =>
                    FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.constitution,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.constitution.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final entry = recentEntries[spot.spotIndex];
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} ${unit == WeightUnit.kg ? 'kg' : 'lbs'}\n${DateFormat('MMM d').format(entry.date)}',
                    const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AddWeightEntrySheet extends ConsumerStatefulWidget {
  const _AddWeightEntrySheet();

  @override
  ConsumerState<_AddWeightEntrySheet> createState() => _AddWeightEntrySheetState();
}

class _AddWeightEntrySheetState extends ConsumerState<_AddWeightEntrySheet> {
  final _weightController = TextEditingController();
  final _noteController = TextEditingController();
  final _bodyFatController = TextEditingController();
  late WeightUnit _unit;
  DateTime _selectedDate = DateTime.now();
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _unit = ref.read(weightUnitProvider);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Weight',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weight input
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      hintText: 'Enter your weight',
                    ),
                    autofocus: true,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                ToggleButtons(
                  isSelected: [_unit == WeightUnit.kg, _unit == WeightUnit.lbs],
                  onPressed: (index) {
                    setState(() {
                      _unit = index == 0 ? WeightUnit.kg : WeightUnit.lbs;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  children: const [
                    Text('kg'),
                    Text('lbs'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'How are you feeling?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Advanced options toggle
            TextButton.icon(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
              label: Text(_showAdvanced ? 'Hide Advanced' : 'Show Advanced'),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Body Fat % (optional)',
                  suffixText: '%',
                ),
              ),
            ],
            const SizedBox(height: 24),

            // XP reward info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.constitution.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: AppColors.constitution, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Earn +15 XP for logging today!',
                    style: TextStyle(
                      color: AppColors.constitution,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveEntry,
                child: const Text('Save Entry'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveEntry() {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your weight')),
      );
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    double? bodyFat;
    if (_bodyFatController.text.isNotEmpty) {
      bodyFat = double.tryParse(_bodyFatController.text);
    }

    ref.read(weightNotifierProvider.notifier).addWeightEntry(
          weight: weight,
          unit: _unit,
          date: _selectedDate,
          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          bodyFat: bodyFat,
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Weight logged! +15 XP'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// Weight entry details sheet
class _EntryDetailsSheet extends ConsumerStatefulWidget {
  final WeightEntry entry;

  const _EntryDetailsSheet({required this.entry});

  @override
  ConsumerState<_EntryDetailsSheet> createState() => _EntryDetailsSheetState();
}

class _EntryDetailsSheetState extends ConsumerState<_EntryDetailsSheet> {
  late TextEditingController _weightController;
  late TextEditingController _noteController;
  late TextEditingController _bodyFatController;
  late WeightUnit _unit;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.entry.weight.toString());
    _noteController = TextEditingController(text: widget.entry.note ?? '');
    _bodyFatController = TextEditingController(
      text: widget.entry.bodyFat?.toString() ?? '',
    );
    _unit = widget.entry.unit;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Entry' : 'Weight Details',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => setState(() => _isEditing = true),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(widget.entry.date),
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            if (_isEditing) ...[
              // Editable weight
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Weight'),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ToggleButtons(
                    isSelected: [_unit == WeightUnit.kg, _unit == WeightUnit.lbs],
                    onPressed: (index) {
                      setState(() {
                        _unit = index == 0 ? WeightUnit.kg : WeightUnit.lbs;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    children: const [Text('kg'), Text('lbs')],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyFatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Body Fat % (optional)',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _isEditing = false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // View mode
              _DetailRow(
                icon: Icons.scale,
                label: 'Weight',
                value: '${widget.entry.weight} ${widget.entry.unit.name}',
              ),
              if (widget.entry.bodyFat != null)
                _DetailRow(
                  icon: Icons.percent,
                  label: 'Body Fat',
                  value: '${widget.entry.bodyFat}%',
                ),
              if (widget.entry.muscleMass != null)
                _DetailRow(
                  icon: Icons.fitness_center,
                  label: 'Muscle Mass',
                  value: '${widget.entry.muscleMass} kg',
                ),
              if (widget.entry.waterPercentage != null)
                _DetailRow(
                  icon: Icons.water_drop,
                  label: 'Water',
                  value: '${widget.entry.waterPercentage}%',
                ),
              if (widget.entry.note != null && widget.entry.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Note',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(widget.entry.note!),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deleteEntry(context),
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  label: const Text('Delete Entry', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    double? bodyFat;
    if (_bodyFatController.text.isNotEmpty) {
      bodyFat = double.tryParse(_bodyFatController.text);
    }

    final updatedEntry = widget.entry.copyWith(
      weight: weight,
      unit: _unit,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      bodyFat: bodyFat,
    );

    ref.read(weightNotifierProvider.notifier).updateWeightEntry(updatedEntry);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entry updated'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _deleteEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(weightNotifierProvider.notifier).deleteWeightEntry(widget.entry.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Entry deleted')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _SetGoalDialog extends ConsumerStatefulWidget {
  final double currentWeight;
  final WeightUnit unit;

  const _SetGoalDialog({
    required this.currentWeight,
    required this.unit,
  });

  @override
  ConsumerState<_SetGoalDialog> createState() => _SetGoalDialogState();
}

class _SetGoalDialogState extends ConsumerState<_SetGoalDialog> {
  final _targetController = TextEditingController();
  late WeightUnit _unit;
  String _goalType = 'lose';
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit;
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Weight Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Goal type
            const Text('Goal Type'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Lose'),
                  selected: _goalType == 'lose',
                  onSelected: (selected) {
                    if (selected) setState(() => _goalType = 'lose');
                  },
                ),
                ChoiceChip(
                  label: const Text('Maintain'),
                  selected: _goalType == 'maintain',
                  onSelected: (selected) {
                    if (selected) setState(() => _goalType = 'maintain');
                  },
                ),
                ChoiceChip(
                  label: const Text('Gain'),
                  selected: _goalType == 'gain',
                  onSelected: (selected) {
                    if (selected) setState(() => _goalType = 'gain');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target weight
            TextField(
              controller: _targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Weight',
                suffixText: _unit == WeightUnit.kg ? 'kg' : 'lbs',
              ),
            ),
            const SizedBox(height: 16),

            // Target date
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _targetDate != null
                    ? DateFormat('MMM d, yyyy').format(_targetDate!)
                    : 'Set target date (optional)',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _targetDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveGoal,
          child: const Text('Set Goal'),
        ),
      ],
    );
  }

  void _saveGoal() {
    final targetText = _targetController.text.trim();
    if (targetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a target weight')),
      );
      return;
    }

    final target = double.tryParse(targetText);
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }

    ref.read(weightNotifierProvider.notifier).setWeightGoal(
          targetWeight: target,
          unit: _unit,
          startWeight: widget.currentWeight,
          goalType: _goalType,
          targetDate: _targetDate,
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Goal set! Stay consistent to reach it.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// Helper widgets
class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeChip extends StatelessWidget {
  final double change;
  final String label;
  final String unit;

  const _ChangeChip({
    required this.change,
    required this.label,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final color = isPositive ? AppColors.error : AppColors.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(1)} $unit $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final WeightGoal goal;
  final WeightStats stats;
  final WeightUnit unit;

  const _GoalProgressCard({
    required this.goal,
    required this.stats,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final multiplier = unit == WeightUnit.kg ? 1.0 : 2.20462;
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';
    final progress = goal.progressPercentage(stats.currentWeight);
    final remaining = goal.remainingWeight(stats.currentWeight) * multiplier;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flag, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Goal: ${goal.goalType.toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${(goal.targetWeight * multiplier).toStringAsFixed(1)} $unitLabel',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.toStringAsFixed(0)}% complete',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                '${remaining.toStringAsFixed(1)} $unitLabel to go',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightEntryTile extends StatelessWidget {
  final WeightEntry entry;
  final WeightUnit unit;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WeightEntryTile({
    required this.entry,
    required this.unit,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final displayWeight = unit == WeightUnit.kg
        ? entry.weightInKg
        : entry.weightInLbs;
    final unitLabel = unit == WeightUnit.kg ? 'kg' : 'lbs';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.constitution.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              DateFormat('d').format(entry.date),
              style: TextStyle(
                color: AppColors.constitution,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Text(
          '${displayWeight.toStringAsFixed(1)} $unitLabel',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: entry.note != null
            ? Text(
                entry.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted),
              )
            : Text(
                DateFormat('EEEE').format(entry.date),
                style: const TextStyle(color: AppColors.textMuted),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final String title;
  final double change;
  final String unit;

  const _ChangeCard({
    required this.title,
    required this.change,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change > 0;
    final color = change == 0
        ? AppColors.textMuted
        : (isPositive ? AppColors.error : AppColors.success);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (change != 0)
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                  size: 16,
                ),
              Text(
                '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
