import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../models/achievement.dart';
import '../../providers/achievement_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Achievements'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achievements',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Your collection of accomplishments',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),
            // Show all available achievements
            ...AchievementCategory.values.map((category) => _buildCategory(
                  context,
                  ref,
                  category,
                  Achievements.getByCategory(category),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    WidgetRef ref,
    AchievementCategory category,
    List<Achievement> achievements,
  ) {
    final unlockedIds = ref.watch(unlockedAchievementIdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            category.name.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _AchievementTile(
              achievement: achievement,
              isUnlocked: unlockedIds.contains(achievement.id),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const _AchievementTile({
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(achievement.rarityColor.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUnlocked ? color.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked ? color : AppColors.surfaceLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 32,
              color: isUnlocked ? color : AppColors.textMuted.withOpacity(0.3),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(achievement.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(achievement.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.accent, size: 16),
                const SizedBox(width: 4),
                Text('+${achievement.xpReward} XP'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
