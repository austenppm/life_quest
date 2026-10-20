import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/quest.dart';
import '../../providers/quest_provider.dart';
import 'quest_form_dialog.dart';

class QuestDetailScreen extends ConsumerWidget {
  final String questId;

  const QuestDetailScreen({super.key, required this.questId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = ref.watch(questsProvider).valueOrNull ?? [];
    final quest = quests.where((q) => q.id == questId).firstOrNull;

    if (quest == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Quest not found')),
      );
    }

    final difficultyColor = _getDifficultyColor(quest.difficulty);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Quest Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, quest),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'abandon':
                  _confirmAbandon(context, ref, quest);
                  break;
                case 'delete':
                  _confirmDelete(context, ref, quest);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (quest.status == QuestStatus.active)
                const PopupMenuItem(
                  value: 'abandon',
                  child: Row(
                    children: [
                      Icon(Icons.flag, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text('Abandon Quest'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Delete Quest'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with difficulty badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quest.difficulty.name.toUpperCase(),
                    style: TextStyle(
                      color: difficultyColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(quest.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    quest.status.name.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(quest.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              quest.title,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            if (quest.description != null) ...[
              const SizedBox(height: 8),
              Text(
                quest.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 24),

            // Progress
            _buildProgressCard(context, quest),
            const SizedBox(height: 16),

            // Rewards
            _buildRewardsCard(context, quest),
            const SizedBox(height: 16),

            // Deadline
            if (quest.deadline != null) ...[
              _buildDeadlineCard(context, quest),
              const SizedBox(height: 16),
            ],

            // Subtasks
            Text(
              'Subtasks (${quest.completedSubtasks}/${quest.subtasks.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            if (quest.subtasks.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'No subtasks for this quest',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...quest.subtasks.map((subtask) => _SubtaskTile(
                    subtask: subtask,
                    onToggle: () {
                      ref.read(questNotifierProvider.notifier)
                          .toggleSubtask(quest, subtask.id);
                    },
                  )),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: quest.status == QuestStatus.active && quest.progress >= 1.0
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(questNotifierProvider.notifier).completeQuest(quest);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Quest completed! +${quest.totalXpReward} XP'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Complete Quest'),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProgressCard(BuildContext context, Quest quest) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress', style: TextStyle(color: AppColors.textMuted)),
              Text(
                '${(quest.progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: quest.progress,
              minHeight: 12,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation(_getDifficultyColor(quest.difficulty)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsCard(BuildContext context, Quest quest) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rewards', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '+${quest.totalXpReward} XP',
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
          if (quest.statRewards.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: quest.statRewards.entries.map((entry) {
                final color = AppColors.getStatColor(entry.key);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppColors.getStatIcon(entry.key), color: color, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${entry.value} ${AppColors.getStatAbbreviation(entry.key)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadlineCard(BuildContext context, Quest quest) {
    final isOverdue = quest.isOverdue;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue ? Border.all(color: AppColors.error.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: isOverdue ? AppColors.error : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deadline',
                style: TextStyle(
                  color: isOverdue ? AppColors.error : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(quest.deadline!),
                style: TextStyle(
                  color: isOverdue ? AppColors.error : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isOverdue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'OVERDUE',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(QuestDifficulty difficulty) {
    switch (difficulty) {
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

  Color _getStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return AppColors.info;
      case QuestStatus.completed:
        return AppColors.success;
      case QuestStatus.abandoned:
        return AppColors.textMuted;
      case QuestStatus.failed:
        return AppColors.error;
    }
  }

  void _showEditDialog(BuildContext context, Quest quest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuestFormDialog(quest: quest),
    );
  }

  void _confirmAbandon(BuildContext context, WidgetRef ref, Quest quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandon Quest?'),
        content: const Text('You can restart this quest later if you change your mind.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(questNotifierProvider.notifier).abandonQuest(quest.id);
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Quest quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(questNotifierProvider.notifier).deleteQuest(quest.id);
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SubtaskTile extends StatelessWidget {
  final SubTask subtask;
  final VoidCallback onToggle;

  const _SubtaskTile({
    required this.subtask,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: subtask.isCompleted 
            ? AppColors.success.withOpacity(0.1) 
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: subtask.isCompleted 
            ? Border.all(color: AppColors.success.withOpacity(0.3)) 
            : null,
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: subtask.isCompleted ? AppColors.success : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: subtask.isCompleted ? AppColors.success : AppColors.textMuted,
                width: 2,
              ),
            ),
            child: subtask.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),
        title: Text(
          subtask.title,
          style: TextStyle(
            color: subtask.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: subtask.completedAt != null
            ? Text(
                'Completed ${DateFormat('MMM d').format(subtask.completedAt!)}',
                style: TextStyle(
                  color: AppColors.success.withOpacity(0.8),
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }
}
