import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../models/quest.dart';
import '../../providers/quest_provider.dart';

class QuestFormDialog extends ConsumerStatefulWidget {
  final Quest? quest; // null for create, non-null for edit

  const QuestFormDialog({super.key, this.quest});

  @override
  ConsumerState<QuestFormDialog> createState() => _QuestFormDialogState();
}

class _QuestFormDialogState extends ConsumerState<QuestFormDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  
  QuestDifficulty _difficulty = QuestDifficulty.medium;
  DateTime? _deadline;
  List<String> _subtasks = [];
  Map<String, int> _statRewards = {};
  int _xpReward = 50;

  bool get isEditing => widget.quest != null;

  @override
  void initState() {
    super.initState();
    if (widget.quest != null) {
      _titleController.text = widget.quest!.title;
      _descriptionController.text = widget.quest!.description ?? '';
      _difficulty = widget.quest!.difficulty;
      _deadline = widget.quest!.deadline;
      _subtasks = widget.quest!.subtasks.map((s) => s.title).toList();
      _statRewards = Map.from(widget.quest!.statRewards);
      _xpReward = widget.quest!.xpReward;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Quest' : 'New Quest',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Quest Title *',
                      hintText: 'e.g., Learn a new programming language',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your quest...',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Difficulty
                  Text(
                    'Difficulty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _DifficultySelector(
                    selected: _difficulty,
                    onChanged: (d) => setState(() {
                      _difficulty = d;
                      _xpReward = _getBaseXPForDifficulty(d);
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Deadline
                  Text(
                    'Deadline (Optional)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDeadline,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: _deadline != null 
                                ? AppColors.primary 
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _deadline != null
                                ? DateFormat('EEEE, MMM d, yyyy').format(_deadline!)
                                : 'No deadline set',
                            style: TextStyle(
                              color: _deadline != null 
                                  ? AppColors.textPrimary 
                                  : AppColors.textMuted,
                            ),
                          ),
                          const Spacer(),
                          if (_deadline != null)
                            IconButton(
                              onPressed: () => setState(() => _deadline = null),
                              icon: const Icon(Icons.clear, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subtasks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtasks',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_subtasks.length} tasks',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Add subtask input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subtaskController,
                          decoration: const InputDecoration(
                            hintText: 'Add a subtask...',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addSubtask(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addSubtask,
                        icon: const Icon(Icons.add_circle),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtask list
                  ..._subtasks.asMap().entries.map((entry) => 
                    _SubtaskTile(
                      title: entry.value,
                      onRemove: () => setState(() => _subtasks.removeAt(entry.key)),
                      onReorder: (direction) {
                        final newIndex = entry.key + direction;
                        if (newIndex >= 0 && newIndex < _subtasks.length) {
                          setState(() {
                            final item = _subtasks.removeAt(entry.key);
                            _subtasks.insert(newIndex, item);
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Stat Rewards
                  Text(
                    'Stat Rewards',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _StatRewardsSelector(
                    rewards: _statRewards,
                    onChanged: (rewards) => setState(() => _statRewards = rewards),
                  ),
                  const SizedBox(height: 24),

                  // XP Reward
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'XP Reward',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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
                              '$_xpReward XP',
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
                  Slider(
                    value: _xpReward.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '$_xpReward XP',
                    onChanged: (value) => setState(() => _xpReward = value.round()),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(isEditing ? 'Save Changes' : 'Create Quest'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subtasks.add(text);
        _subtaskController.clear();
      });
    }
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  int _getBaseXPForDifficulty(QuestDifficulty difficulty) {
    switch (difficulty) {
      case QuestDifficulty.easy:
        return 25;
      case QuestDifficulty.medium:
        return 50;
      case QuestDifficulty.hard:
        return 100;
      case QuestDifficulty.epic:
        return 200;
      case QuestDifficulty.legendary:
        return 500;
    }
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a quest title')),
      );
      return;
    }

    if (isEditing) {
      ref.read(questNotifierProvider.notifier).updateQuest(
        widget.quest!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        difficulty: _difficulty,
        statRewards: _statRewards,
        xpReward: _xpReward,
        deadline: _deadline,
      );
    } else {
      ref.read(questNotifierProvider.notifier).createQuest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        difficulty: _difficulty,
        subtaskTitles: _subtasks,
        statRewards: _statRewards,
        xpReward: _xpReward,
        deadline: _deadline,
      );
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEditing ? 'Quest updated!' : 'Quest created!'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  final QuestDifficulty selected;
  final ValueChanged<QuestDifficulty> onChanged;

  const _DifficultySelector({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: QuestDifficulty.values.map((d) {
        final isSelected = d == selected;
        final color = _getColor(d);
        
        return GestureDetector(
          onTap: () => onChanged(d),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(d),
                  color: isSelected ? color : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  d.name.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getColor(QuestDifficulty d) {
    switch (d) {
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

  IconData _getIcon(QuestDifficulty d) {
    switch (d) {
      case QuestDifficulty.easy:
        return Icons.sentiment_satisfied;
      case QuestDifficulty.medium:
        return Icons.sentiment_neutral;
      case QuestDifficulty.hard:
        return Icons.sentiment_dissatisfied;
      case QuestDifficulty.epic:
        return Icons.whatshot;
      case QuestDifficulty.legendary:
        return Icons.auto_awesome;
    }
  }
}

class _SubtaskTile extends StatelessWidget {
  final String title;
  final VoidCallback onRemove;
  final Function(int) onReorder;

  const _SubtaskTile({
    required this.title,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          const Icon(Icons.check_box_outline_blank, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _StatRewardsSelector extends StatelessWidget {
  final Map<String, int> rewards;
  final ValueChanged<Map<String, int>> onChanged;

  const _StatRewardsSelector({
    required this.rewards,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppColors.statNames.map((stat) {
        final reward = rewards[stat] ?? 0;
        final isSelected = reward > 0;
        final color = AppColors.getStatColor(stat);

        return GestureDetector(
          onTap: () {
            final newRewards = Map<String, int>.from(rewards);
            if (isSelected) {
              newRewards.remove(stat);
            } else {
              newRewards[stat] = 10;
            }
            onChanged(newRewards);
          },
          onLongPress: () => _showRewardDialog(context, stat, reward),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppColors.getStatIcon(stat),
                  color: isSelected ? color : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  AppColors.getStatAbbreviation(stat),
                  style: TextStyle(
                    color: isSelected ? color : AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 4),
                  Text(
                    '+$reward',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showRewardDialog(BuildContext context, String stat, int currentReward) {
    int reward = currentReward > 0 ? currentReward : 10;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${AppColors.getStatAbbreviation(stat)} Reward'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('+$reward XP'),
              Slider(
                value: reward.toDouble(),
                min: 5,
                max: 50,
                divisions: 9,
                onChanged: (v) => setDialogState(() => reward = v.round()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newRewards = Map<String, int>.from(rewards);
                newRewards[stat] = reward;
                onChanged(newRewards);
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }
}
