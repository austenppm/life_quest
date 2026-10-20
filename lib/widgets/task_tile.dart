import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final bool compact;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.compact = false,
  });

  Color _getPriorityColor() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return AppColors.primary;
      case TaskPriority.low:
        return AppColors.textMuted;
    }
  }

  IconData _getPriorityIcon() {
    switch (task.priority) {
      case TaskPriority.urgent:
        return Icons.priority_high;
      case TaskPriority.high:
        return Icons.arrow_upward;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.low:
        return Icons.arrow_downward;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompletedToday();
    final statColor = AppColors.getStatColor(task.statAffected);
    final priorityColor = _getPriorityColor();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(compact ? 12 : 16),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.success.withOpacity(0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? AppColors.success.withOpacity(0.3)
                : task.isHighPriority
                    ? priorityColor.withOpacity(0.3)
                    : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority indicator bar
            if (task.priority != TaskPriority.medium) ...[
              Container(
                width: 3,
                height: compact ? 40 : 56,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
            ],
            // Checkbox
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: compact ? 24 : 28,
                height: compact ? 24 : 28,
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCompleted ? AppColors.success : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: compact ? 14 : 18,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Task info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration:
                                    isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted
                                    ? AppColors.textMuted
                                    : AppColors.textPrimary,
                                fontSize: compact ? 14 : null,
                              ),
                        ),
                      ),
                      // Priority badge for urgent/high
                      if (task.isHighPriority && !compact)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getPriorityIcon(), size: 10, color: priorityColor),
                              const SizedBox(width: 2),
                              Text(
                                task.priority.displayName,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (task.description != null && !compact) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Subtasks progress
                  if (task.hasSubtasks) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: task.subtasksProgress,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation(
                                task.allSubtasksCompleted
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${task.completedSubtasksCount}/${task.totalSubtasksCount}',
                          style: TextStyle(
                            fontSize: 10,
                            color: task.allSubtasksCompleted
                                ? AppColors.success
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Stat badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              task.statAffected.toUpperCase(),
                              style: TextStyle(
                                color: statColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // XP reward
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '+${task.xpReward} XP',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      // Streak indicator
                      if (task.currentStreak > 0) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: AppColors.accentSecondary,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${task.currentStreak}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.accentSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                      // Duration estimate
                      if (task.estimatedDuration != null && !compact) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppColors.textMuted,
                              size: 12,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              task.formattedDuration,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Overdue indicator
                      if (task.isOverdue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber, size: 10, color: Colors.red),
                              SizedBox(width: 2),
                              Text(
                                'OVERDUE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            if (onTap != null && !compact)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
              ),
          ],
        ),
      ),
    );
  }
}
