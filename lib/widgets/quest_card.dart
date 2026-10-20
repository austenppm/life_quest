import 'package:flutter/material.dart';

import '../models/quest.dart';
import '../theme/app_theme.dart';

class QuestCard extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onTap;

  const QuestCard({
    super.key,
    required this.quest,
    this.onTap,
  });

  Color get _difficultyColor {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return AppColors.success;
      case QuestDifficulty.medium:
        return AppColors.info;
      case QuestDifficulty.hard:
        return AppColors.warning;
      case QuestDifficulty.epic:
        return AppColors.primary;
      case QuestDifficulty.legendary:
        return AppColors.accent;
    }
  }

  String get _difficultyLabel {
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return 'EASY';
      case QuestDifficulty.medium:
        return 'MEDIUM';
      case QuestDifficulty.hard:
        return 'HARD';
      case QuestDifficulty.epic:
        return 'EPIC';
      case QuestDifficulty.legendary:
        return 'LEGENDARY';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _difficultyColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _difficultyLabel,
                    style: TextStyle(
                      color: _difficultyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '+${quest.totalXpReward} XP',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title
            Text(
              quest.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (quest.description != null) ...[
              const SizedBox(height: 4),
              Text(
                quest.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Spacer(),
            // Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                    ),
                    Text(
                      '${quest.completedSubtasks}/${quest.subtasks.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: quest.progress,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(_difficultyColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
            // Deadline indicator
            if (quest.deadline != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: quest.isOverdue ? AppColors.error : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    quest.isOverdue
                        ? 'Overdue'
                        : _formatDeadline(quest.deadline!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: quest.isOverdue
                              ? AppColors.error
                              : AppColors.textMuted,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.inDays == 0) {
      return 'Due today';
    } else if (difference.inDays == 1) {
      return 'Due tomorrow';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays} days';
    } else {
      return 'Due ${deadline.month}/${deadline.day}';
    }
  }
}
