import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../providers/workout_provider.dart';
import '../../data/exercise_library.dart';
import '../../models/workout.dart';

class ExerciseProgressScreen extends ConsumerStatefulWidget {
  const ExerciseProgressScreen({super.key});

  @override
  ConsumerState<ExerciseProgressScreen> createState() => _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState extends ConsumerState<ExerciseProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedExercise;

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
    final stats = ref.watch(workoutStatsProvider);
    final personalRecords = ref.watch(personalRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Records'),
            Tab(text: 'Exercise'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(stats: stats),
          _RecordsTab(records: personalRecords),
          _ExerciseTab(
            selectedExercise: _selectedExercise,
            onExerciseSelected: (name) => setState(() => _selectedExercise = name),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final WorkoutStats stats;

  const _OverviewTab({required this.stats});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Workouts',
                  value: stats.totalWorkouts.toString(),
                  icon: Icons.fitness_center,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'This Week',
                  value: stats.workoutsThisWeek.toString(),
                  icon: Icons.calendar_today,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Current Streak',
                  value: '${stats.currentStreak} days',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Total Volume',
                  value: _formatVolume(stats.totalVolume),
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Workout Frequency Chart
          const Text(
            'Workout Frequency',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _WorkoutFrequencyChart(workouts: workouts),
          ),
          const SizedBox(height: 24),

          // Muscle Group Distribution
          const Text(
            'Muscle Group Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _MuscleGroupDistribution(workouts: workouts),
        ],
      ),
    );
  }

  String _formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M kg';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K kg';
    }
    return '${volume.toStringAsFixed(0)} kg';
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
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

class _WorkoutFrequencyChart extends StatelessWidget {
  final List<Workout> workouts;

  const _WorkoutFrequencyChart({required this.workouts});

  @override
  Widget build(BuildContext context) {
    // Get last 7 weeks of data
    final now = DateTime.now();
    final weekCounts = <int, int>{};

    for (int i = 0; i < 7; i++) {
      weekCounts[i] = 0;
    }

    for (final workout in workouts) {
      final weeksAgo = now.difference(workout.date).inDays ~/ 7;
      if (weeksAgo >= 0 && weeksAgo < 7) {
        weekCounts[weeksAgo] = (weekCounts[weeksAgo] ?? 0) + 1;
      }
    }

    final maxCount = weekCounts.values.fold(0, (max, v) => v > max ? v : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxCount + 1).toDouble(),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final weeksAgo = 6 - value.toInt();
                if (weeksAgo == 0) return const Text('This\nweek', style: TextStyle(fontSize: 10));
                if (weeksAgo == 1) return const Text('Last\nweek', style: TextStyle(fontSize: 10));
                return Text('${weeksAgo}w\nago', style: const TextStyle(fontSize: 10));
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == value.roundToDouble()) {
                  return Text(value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.surfaceLight,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          final weeksAgo = 6 - index;
          final count = weekCounts[weeksAgo] ?? 0;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: AppColors.primary,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MuscleGroupDistribution extends StatelessWidget {
  final List<Workout> workouts;

  const _MuscleGroupDistribution({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final muscleSetCounts = <MuscleGroup, int>{};

    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        // Try to find the exercise definition to get muscle group
        final definition = ExerciseLibrary.exercises.firstWhere(
          (e) => e.name.toLowerCase() == exercise.name.toLowerCase(),
          orElse: () => ExerciseDefinition(
            id: '',
            name: exercise.name,
            primaryMuscle: MuscleGroup.chest,
            secondaryMuscles: [],
            equipment: Equipment.barbell,
            type: ExerciseType.strength,
          ),
        );
        muscleSetCounts[definition.primaryMuscle] =
            (muscleSetCounts[definition.primaryMuscle] ?? 0) + exercise.sets.length;
      }
    }

    final sortedMuscles = muscleSetCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSets = muscleSetCounts.values.fold(0, (sum, v) => sum + v);

    if (sortedMuscles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'No workout data yet',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sortedMuscles.take(6).map((entry) {
          final percentage = totalSets > 0 ? entry.value / totalSets : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${entry.key.emoji} ${entry.key.displayName}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${entry.value} sets',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecordsTab extends StatelessWidget {
  final Map<String, PersonalRecord> records;

  const _RecordsTab({required this.records});

  @override
  Widget build(BuildContext context) {
    final sortedRecords = records.values.toList()
      ..sort((a, b) => b.estimatedOneRepMax.compareTo(a.estimatedOneRepMax));

    if (sortedRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No personal records yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete some workouts to see your PRs',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        return _PersonalRecordTile(record: record, rank: index + 1);
      },
    );
  }
}

class _PersonalRecordTile extends StatelessWidget {
  final PersonalRecord record;
  final int rank;

  const _PersonalRecordTile({required this.record, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: rank <= 3
            ? Border.all(
                color: rank == 1
                    ? Colors.amber
                    : rank == 2
                        ? Colors.grey[400]!
                        : Colors.brown[300]!,
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? (rank == 1
                          ? Colors.amber
                          : rank == 2
                              ? Colors.grey[400]
                              : Colors.brown[300])!
                      .withOpacity(0.2)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      Icons.emoji_events,
                      color: rank == 1
                          ? Colors.amber
                          : rank == 2
                              ? Colors.grey[400]
                              : Colors.brown[300],
                      size: 20,
                    )
                  : Text(
                      '#$rank',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.exerciseName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.weight.toStringAsFixed(1)} kg x ${record.reps} reps',
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
                '${record.estimatedOneRepMax.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                'Est. 1RM',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExerciseTab extends ConsumerWidget {
  final String? selectedExercise;
  final Function(String) onExerciseSelected;

  const _ExerciseTab({
    required this.selectedExercise,
    required this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];

    // Get unique exercises from all workouts
    final exerciseNames = <String>{};
    for (final workout in workouts) {
      for (final exercise in workout.exercises) {
        exerciseNames.add(exercise.name);
      }
    }

    final sortedExercises = exerciseNames.toList()..sort();

    if (sortedExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No exercises tracked yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete some workouts to track progress',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    final selected = selectedExercise ?? sortedExercises.first;
    final history = ref.watch(exerciseHistoryProvider(selected));

    return Column(
      children: [
        // Exercise selector
        Container(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: sortedExercises.contains(selected) ? selected : sortedExercises.first,
            decoration: InputDecoration(
              labelText: 'Select Exercise',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: sortedExercises.map((name) {
              return DropdownMenuItem(
                value: name,
                child: Text(name),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) onExerciseSelected(value);
            },
          ),
        ),

        // Progress chart
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (history.length >= 2) ...[
                  const Text(
                    'Weight Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _ExerciseProgressChart(history: history),
                  ),
                  const SizedBox(height: 24),
                ],

                const Text(
                  'History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...history.reversed.take(20).map((entry) => _HistoryEntryTile(entry: entry)),

                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'No history for this exercise',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseProgressChart extends StatelessWidget {
  final List<ExerciseHistory> history;

  const _ExerciseProgressChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox();

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.maxWeight);
    }).toList();

    final minWeight = history.map((h) => h.maxWeight).reduce((a, b) => a < b ? a : b);
    final maxWeight = history.map((h) => h.maxWeight).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.surfaceLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < history.length && index % (history.length ~/ 4 + 1) == 0) {
                  return Text(
                    DateFormat('M/d').format(history[index].date),
                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()} kg',
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: (minWeight - 5).clamp(0, double.infinity),
        maxY: maxWeight + 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.primary,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  final ExerciseHistory entry;

  const _HistoryEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM d').format(entry.date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.sets} sets • ${entry.totalReps} reps',
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
                '${entry.maxWeight.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${entry.totalVolume.toStringAsFixed(0)} kg vol',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
