import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('No profile found'));
            }
            return _StatsContent(profile: profile);
          },
        ),
      ),
    );
  }
}

class _StatsContent extends StatefulWidget {
  final UserProfile profile;

  const _StatsContent({required this.profile});

  @override
  State<_StatsContent> createState() => _StatsContentState();
}

class _StatsContentState extends State<_StatsContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.profile.stats;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Character Stats',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.totalStatPoints} Total',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Radar Chart
        SizedBox(
          height: 220,
          child: _StatRadarChart(stats: stats),
        ),

        // Tab Bar
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Physical'),
            Tab(text: 'Mental'),
            Tab(text: 'Social'),
            Tab(text: 'Lifestyle'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AllStatsView(stats: stats),
              _CategoryStatsView(
                stats: stats,
                category: 'Physical',
                statNames: AppColors.physicalStats,
              ),
              _CategoryStatsView(
                stats: stats,
                category: 'Mental',
                statNames: AppColors.mentalStats,
              ),
              _CategoryStatsView(
                stats: stats,
                category: 'Social',
                statNames: AppColors.socialStatsList,
              ),
              _CategoryStatsView(
                stats: stats,
                category: 'Lifestyle',
                statNames: AppColors.lifestyleStats,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRadarChart extends StatelessWidget {
  final UserStats stats;

  const _StatRadarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final allStats = stats.allStats;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              dataEntries: allStats.map<RadarEntry>((e) => RadarEntry(value: e.value.toDouble())).toList(),
              fillColor: AppColors.primary.withOpacity(0.2),
              borderColor: AppColors.primary,
              borderWidth: 2,
              entryRadius: 3,
            ),
          ],
          radarBackgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          radarBorderData: BorderSide(color: AppColors.surfaceLight, width: 1),
          gridBorderData: BorderSide(color: AppColors.surfaceLight.withOpacity(0.5), width: 1),
          tickCount: 4,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 8),
          tickBorderData: BorderSide(color: AppColors.surfaceLight.withOpacity(0.3), width: 1),
          getTitle: (index, angle) {
            final stat = allStats[index];
            return RadarChartTitle(
              text: AppColors.getStatAbbreviation(stat.key),
              angle: angle,
              positionPercentageOffset: 0.1,
            );
          },
          titleTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          titlePositionPercentageOffset: 0.2,
        ),
      ),
    );
  }
}

class _AllStatsView extends StatelessWidget {
  final UserStats stats;

  const _AllStatsView({required this.stats});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatCategoryHeader(title: 'Physical', icon: Icons.fitness_center, color: AppColors.strength),
        ...AppColors.physicalStats.map((stat) => _StatCard(
          stat: stat,
          level: stats.getStatLevel(stat),
          xp: stats.getStatXP(stat),
        )),
        const SizedBox(height: 16),
        
        _StatCategoryHeader(title: 'Mental', icon: Icons.psychology, color: AppColors.intelligence),
        ...AppColors.mentalStats.map((stat) => _StatCard(
          stat: stat,
          level: stats.getStatLevel(stat),
          xp: stats.getStatXP(stat),
        )),
        const SizedBox(height: 16),
        
        _StatCategoryHeader(title: 'Social', icon: Icons.people, color: AppColors.charisma),
        ...AppColors.socialStatsList.map((stat) => _StatCard(
          stat: stat,
          level: stats.getStatLevel(stat),
          xp: stats.getStatXP(stat),
        )),
        const SizedBox(height: 16),
        
        _StatCategoryHeader(title: 'Lifestyle', icon: Icons.self_improvement, color: AppColors.discipline),
        ...AppColors.lifestyleStats.map((stat) => _StatCard(
          stat: stat,
          level: stats.getStatLevel(stat),
          xp: stats.getStatXP(stat),
        )),
      ],
    );
  }
}

class _CategoryStatsView extends StatelessWidget {
  final UserStats stats;
  final String category;
  final List<String> statNames;

  const _CategoryStatsView({
    required this.stats,
    required this.category,
    required this.statNames,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Category summary card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.getStatColor(statNames.first).withOpacity(0.2),
                AppColors.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    color: AppColors.getStatColor(statNames.first),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$category Stats',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.getStatColor(statNames.first),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getCategoryDescription(category),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: statNames.map((stat) {
                  final level = stats.getStatLevel(stat);
                  final mod = stats.getStatMod(stat);
                  return Column(
                    children: [
                      Text(
                        '$level',
                        style: TextStyle(
                          color: AppColors.getStatColor(stat),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppColors.getStatAbbreviation(stat),
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        mod >= 0 ? '+$mod' : '$mod',
                        style: TextStyle(
                          color: mod >= 0 ? AppColors.success : AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Individual stat cards
        ...statNames.map((stat) => _DetailedStatCard(
          stat: stat,
          level: stats.getStatLevel(stat),
          xp: stats.getStatXP(stat),
        )),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Physical':
        return Icons.fitness_center;
      case 'Mental':
        return Icons.psychology;
      case 'Social':
        return Icons.people;
      case 'Lifestyle':
        return Icons.self_improvement;
      default:
        return Icons.star;
    }
  }

  String _getCategoryDescription(String category) {
    switch (category) {
      case 'Physical':
        return 'Your body is your vessel. Train it well through exercise, nutrition, and rest.';
      case 'Mental':
        return 'Sharpen your mind through learning, reflection, and focused work.';
      case 'Social':
        return 'Build connections and influence through communication and leadership.';
      case 'Lifestyle':
        return 'Master your habits and express your creativity to level up your life.';
      default:
        return '';
    }
  }
}

class _StatCategoryHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _StatCategoryHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: color.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String stat;
  final int level;
  final int xp;

  const _StatCard({
    required this.stat,
    required this.level,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatColor(stat);
    final xpForNext = level * 100;
    final progress = xp / xpForNext;
    final mod = (level - 10) ~/ 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(AppColors.getStatIcon(stat), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          
          // Name and progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stat[0].toUpperCase() + stat.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${AppColors.getStatAbbreviation(stat)})',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$xp / $xpForNext XP',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // Level
          Column(
            children: [
              Text(
                '$level',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: mod >= 0 ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mod >= 0 ? '+$mod' : '$mod',
                  style: TextStyle(
                    color: mod >= 0 ? AppColors.success : AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailedStatCard extends StatelessWidget {
  final String stat;
  final int level;
  final int xp;

  const _DetailedStatCard({
    required this.stat,
    required this.level,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatColor(stat);
    final xpForNext = level * 100;
    final progress = xp / xpForNext;
    final mod = (level - 10) ~/ 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(AppColors.getStatIcon(stat), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat[0].toUpperCase() + stat.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      AppColors.getStatDescription(stat),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    '$level',
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: mod >= 0 ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Mod: ${mod >= 0 ? '+$mod' : mod}',
                      style: TextStyle(
                        color: mod >= 0 ? AppColors.success : AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // XP Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to Level ${level + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                '$xp / $xpForNext XP',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% complete',
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
