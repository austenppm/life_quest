import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/workout_provider.dart';

/// A card widget displaying workout streak information
class WorkoutStreakCard extends ConsumerWidget {
  final bool compact;

  const WorkoutStreakCard({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider);
    final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];

    if (compact) {
      return _buildCompactStreak(context, stats);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: stats.currentStreak > 0
                      ? Colors.orange
                      : Theme.of(context).colorScheme.outline,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Workout Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStreakColor(stats.currentStreak).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats.currentStreak} days',
                    style: TextStyle(
                      color: _getStreakColor(stats.currentStreak),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Week view
            _buildWeekView(context, workouts),
            const SizedBox(height: 16),
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'This Week',
                  '${stats.workoutsThisWeek}',
                  Icons.calendar_today,
                ),
                _buildStatItem(
                  context,
                  'Total',
                  '${stats.totalWorkouts}',
                  Icons.fitness_center,
                ),
                _buildStatItem(
                  context,
                  'Hours',
                  (stats.totalMinutes / 60).toStringAsFixed(1),
                  Icons.timer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStreak(BuildContext context, WorkoutStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStreakColor(stats.currentStreak).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStreakColor(stats.currentStreak).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: _getStreakColor(stats.currentStreak),
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '${stats.currentStreak}',
            style: TextStyle(
              color: _getStreakColor(stats.currentStreak),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(BuildContext context, List<dynamic> workouts) {
    final now = DateTime.now();
    final days = <DateTime>[];

    // Get last 7 days
    for (int i = 6; i >= 0; i--) {
      days.add(now.subtract(Duration(days: i)));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((day) {
        final hasWorkout = workouts.any((w) =>
            w.date.year == day.year &&
            w.date.month == day.month &&
            w.date.day == day.day);
        final isToday = day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;

        return _buildDayIndicator(context, day, hasWorkout, isToday);
      }).toList(),
    );
  }

  Widget _buildDayIndicator(
    BuildContext context,
    DateTime day,
    bool hasWorkout,
    bool isToday,
  ) {
    final dayName = DateFormat('E').format(day).substring(0, 1);

    return Column(
      children: [
        Text(
          dayName,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasWorkout
                ? Colors.green
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: isToday
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: hasWorkout
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Color _getStreakColor(int streak) {
    if (streak == 0) return Colors.grey;
    if (streak < 3) return Colors.orange;
    if (streak < 7) return Colors.deepOrange;
    if (streak < 14) return Colors.red;
    if (streak < 30) return Colors.purple;
    return Colors.blue; // Legend status
  }
}

/// A motivational streak banner with fire animation effect
class StreakBanner extends ConsumerWidget {
  const StreakBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(workoutStatsProvider);

    if (stats.currentStreak == 0) {
      return _buildStartStreakBanner(context);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getStreakGradient(stats.currentStreak),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStreakGradient(stats.currentStreak).first.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Streak fire icon with glow effect
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: const Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stats.currentStreak} Day Streak!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getMotivationalMessage(stats.currentStreak),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Milestone indicator
          if (_getNextMilestone(stats.currentStreak) != null)
            Column(
              children: [
                Text(
                  '${_getNextMilestone(stats.currentStreak)! - stats.currentStreak}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'to next\nmilestone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStartStreakBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(
              Icons.local_fire_department,
              size: 32,
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start Your Streak!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete a workout today to begin building your streak',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getStreakGradient(int streak) {
    if (streak < 3) {
      return [Colors.orange.shade400, Colors.orange.shade600];
    } else if (streak < 7) {
      return [Colors.deepOrange.shade400, Colors.deepOrange.shade700];
    } else if (streak < 14) {
      return [Colors.red.shade400, Colors.red.shade700];
    } else if (streak < 30) {
      return [Colors.purple.shade400, Colors.purple.shade700];
    } else if (streak < 100) {
      return [Colors.blue.shade400, Colors.indigo.shade700];
    } else {
      // Legendary streak - gold gradient
      return [Colors.amber.shade400, Colors.orange.shade800];
    }
  }

  String _getMotivationalMessage(int streak) {
    if (streak == 1) return "Great start! Keep it going!";
    if (streak == 2) return "Two days strong!";
    if (streak == 3) return "You're building momentum!";
    if (streak < 7) return "Keep pushing! A week is within reach!";
    if (streak == 7) return "One week! You're on fire! 🔥";
    if (streak < 14) return "Incredible dedication!";
    if (streak == 14) return "Two weeks! Unstoppable!";
    if (streak < 30) return "You're becoming a legend!";
    if (streak == 30) return "30 days! A whole month! 🏆";
    if (streak < 100) return "Absolute beast mode!";
    if (streak == 100) return "100 DAYS! YOU'RE A LEGEND! 👑";
    return "Nothing can stop you now!";
  }

  int? _getNextMilestone(int currentStreak) {
    const milestones = [3, 7, 14, 30, 60, 100, 200, 365];
    for (final milestone in milestones) {
      if (currentStreak < milestone) return milestone;
    }
    return null;
  }
}

/// Calendar heatmap showing workout frequency
class WorkoutCalendarHeatmap extends ConsumerWidget {
  final int weeksToShow;

  const WorkoutCalendarHeatmap({
    super.key,
    this.weeksToShow = 12,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(workoutsProvider).valueOrNull ?? [];

    // Build a map of dates to workout counts
    final workoutCounts = <String, int>{};
    for (final workout in workouts) {
      final key = DateFormat('yyyy-MM-dd').format(workout.date);
      workoutCounts[key] = (workoutCounts[key] ?? 0) + 1;
    }

    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: weeksToShow * 7));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                _buildLegend(context),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(weeksToShow, (weekIndex) {
                  return Column(
                    children: List.generate(7, (dayIndex) {
                      final date = startDate.add(
                        Duration(days: weekIndex * 7 + dayIndex),
                      );
                      final key = DateFormat('yyyy-MM-dd').format(date);
                      final count = workoutCounts[key] ?? 0;

                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Tooltip(
                          message: '${DateFormat('MMM d').format(date)}: $count workout${count != 1 ? 's' : ''}',
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getHeatmapColor(context, count),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        Text(
          'Less',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
        const SizedBox(width: 4),
        for (int i = 0; i <= 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _getHeatmapColor(context, i),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(width: 4),
        Text(
          'More',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Color _getHeatmapColor(BuildContext context, int count) {
    if (count == 0) {
      return Theme.of(context).colorScheme.surfaceContainerHighest;
    } else if (count == 1) {
      return Colors.green.shade200;
    } else if (count == 2) {
      return Colors.green.shade400;
    } else if (count == 3) {
      return Colors.green.shade600;
    } else {
      return Colors.green.shade800;
    }
  }
}
