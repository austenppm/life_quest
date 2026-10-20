import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/quest_provider.dart';
import '../../providers/money_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/task_tile.dart';
import '../../widgets/quest_card.dart';

class DashboardContent extends ConsumerWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final todayTasks = ref.watch(todayTasksProvider);
    final activeQuests = ref.watch(activeQuestsProvider);
    final completedToday = ref.watch(completedTodayCountProvider);

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(tasksProvider);
        ref.invalidate(questsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            Text(
              'Welcome back,',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            Text(
              profile.displayName,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Stats Radar Chart
            _buildStatsSection(context, profile),
            const SizedBox(height: 24),

            // Quick Stats Row
            _buildQuickStats(context, profile, completedToday, todayTasks.length),
            const SizedBox(height: 24),

            // Today's Tasks
            _buildTodayTasks(context, ref, todayTasks),
            const SizedBox(height: 24),

            // Active Quests
            _buildActiveQuests(context, activeQuests),
            const SizedBox(height: 24),

            // Money Summary
            _buildMoneySummary(context, ref),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActions(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, profile) {
    final stats = profile.stats;
    final allStats = stats.allStats;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Character Stats',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () => context.push('/stats'),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                tickCount: 4,
                ticksTextStyle: const TextStyle(color: Colors.transparent),
                radarBorderData: const BorderSide(color: AppColors.surfaceLight),
                gridBorderData: const BorderSide(color: AppColors.surfaceLight, width: 0.5),
                tickBorderData: const BorderSide(color: Colors.transparent),
                getTitle: (index, angle) {
                  final stat = allStats[index];
                  return RadarChartTitle(
                    text: AppColors.getStatAbbreviation(stat.key),
                    angle: 0,
                    positionPercentageOffset: 0.15,
                  );
                },
                dataSets: [
                  RadarDataSet(
                    fillColor: AppColors.primary.withOpacity(0.3),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: allStats.map<RadarEntry>((e) =>
                      RadarEntry(value: e.value.toDouble())
                    ).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Stat pills showing highest and lowest
          _buildStatHighlights(context, stats),
        ],
      ),
    );
  }

  Widget _buildStatHighlights(BuildContext context, stats) {
    final allStats = stats.allStats as List<MapEntry<String, int>>;
    final sorted = [...allStats]..sort((a, b) => b.value.compareTo(a.value));
    final highest = sorted.first;
    final lowest = sorted.last;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatPill(
          label: 'Highest',
          stat: highest.key,
          value: highest.value,
          isPositive: true,
        ),
        const SizedBox(width: 16),
        _StatPill(
          label: 'Lowest',
          stat: lowest.key,
          value: lowest.value,
          isPositive: false,
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, profile, int completedToday, int totalToday) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.local_fire_department,
            iconColor: AppColors.accent,
            title: 'Streak',
            value: '${profile.stats.discipline} days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.check_circle,
            iconColor: AppColors.success,
            title: 'Today',
            value: '$completedToday/$totalToday',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.emoji_events,
            iconColor: AppColors.levelBadge,
            title: 'Total XP',
            value: '${profile.totalXP}',
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTasks(BuildContext context, WidgetRef ref, List todayTasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Quests",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton.icon(
              onPressed: () => context.go('/tasks'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (todayTasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 48,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tasks for today',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/tasks'),
                    child: const Text('Create your first task'),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayTasks.length > 5 ? 5 : todayTasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = todayTasks[index];
              return TaskTile(
                task: task,
                onToggle: () {
                  if (task.isCompletedToday()) {
                    ref.read(taskNotifierProvider.notifier).uncompleteTask(task);
                  } else {
                    ref.read(taskNotifierProvider.notifier).completeTask(task);
                  }
                },
                onTap: () => context.go('/tasks/${task.id}'),
              );
            },
          ),
        if (todayTasks.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () => context.go('/tasks'),
              child: Text('View all ${todayTasks.length} tasks'),
            ),
          ),
      ],
    );
  }

  Widget _buildActiveQuests(BuildContext context, List activeQuests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Quests',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton.icon(
              onPressed: () => context.push('/quests'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (activeQuests.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.explore,
                    size: 48,
                    color: AppColors.textMuted.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No active quests',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/quests'),
                    child: const Text('Start a new quest'),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: activeQuests.length > 3 ? 3 : activeQuests.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final quest = activeQuests[index];
                return SizedBox(
                  width: 280,
                  child: QuestCard(
                    quest: quest,
                    onTap: () => context.push('/quests/${quest.id}'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.fitness_center,
                label: 'Log Workout',
                color: AppColors.dexterity,
                onTap: () => context.push('/workouts/log'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.book,
                label: 'Study Session',
                color: AppColors.intelligence,
                onTap: () => context.push('/study'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.monitor_weight,
                label: 'Log Weight',
                color: AppColors.constitution,
                onTap: () => context.push('/weight'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.restaurant,
                label: 'Log Food',
                color: AppColors.wisdom,
                onTap: () => context.go('/food'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Add Money',
                color: AppColors.success,
                onTap: () => context.go('/money'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.work,
                label: 'Log Work',
                color: AppColors.discipline,
                onTap: () => context.push('/work'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMoneySummary(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpenses = ref.watch(monthlyExpensesProvider);
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Money',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: () => context.go('/money'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.8),
                AppColors.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                currencyFormat.format(totalBalance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.arrow_downward,
                                color: AppColors.success,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Income',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(monthlyIncome),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.arrow_upward,
                                color: AppColors.error,
                                size: 12,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expenses',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(monthlyExpenses),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
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
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String stat;
  final int value;
  final bool isPositive;

  const _StatPill({
    required this.label,
    required this.stat,
    required this.value,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatColor(stat);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
              Row(
                children: [
                  Icon(
                    AppColors.getStatIcon(stat),
                    color: color,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${AppColors.getStatAbbreviation(stat)} $value',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
