import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../services/ai_service.dart';

class CreateTaskDialog extends ConsumerStatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  ConsumerState<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends ConsumerState<CreateTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();

  TaskType _taskType = TaskType.daily;
  TaskFrequency _frequency = TaskFrequency.daily;
  Map<String, int> _selectedStats = {};
  int _xpReward = 10;
  bool _isAnalyzing = false;
  String? _aiReasoning;
  List<String> _tags = [];
  bool _useAiSuggestions = true;
  bool _hasAnalyzed = false;

  // New fields
  TaskPriority _priority = TaskPriority.medium;
  List<Subtask> _subtasks = [];
  int? _estimatedDuration;
  DateTime? _dueDate;

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
                  'New Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Task Title with AI analyze button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'e.g., Morning run for 30 minutes',
                    ),
                    autofocus: true,
                    onChanged: (value) {
                      if (_hasAnalyzed) {
                        setState(() {
                          _aiReasoning = null;
                          _hasAnalyzed = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isAnalyzing ? null : _analyzeWithAI,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.auto_awesome,
                          color: _hasAnalyzed ? AppColors.success : AppColors.accent,
                        ),
                  tooltip: 'Analyze with Gemini AI',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // AI Analysis result
            if (_aiReasoning != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accent, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Gemini AI Suggestion',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              _useAiSuggestions ? 'Using' : 'Ignored',
                              style: TextStyle(
                                fontSize: 10,
                                color: _useAiSuggestions ? AppColors.success : AppColors.textMuted,
                              ),
                            ),
                            Switch(
                              value: _useAiSuggestions,
                              onChanged: (v) => setState(() => _useAiSuggestions = v),
                              activeColor: AppColors.accent,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiReasoning!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: _tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(tag, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Add details...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Task Type
            Text(
              'Task Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Daily',
                    isSelected: _taskType == TaskType.daily,
                    onTap: () => setState(() => _taskType = TaskType.daily),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeChip(
                    label: 'One-time',
                    isSelected: _taskType == TaskType.oneTime,
                    onTap: () => setState(() => _taskType = TaskType.oneTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Priority Selection
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((priority) {
                final isSelected = _priority == priority;
                final color = _getPriorityColor(priority);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = priority),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.2) : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : AppColors.surfaceLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getPriorityIcon(priority),
                            size: 16,
                            color: isSelected ? color : AppColors.textMuted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            priority.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : null,
                              color: isSelected ? color : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Due Date (for one-time tasks)
            if (_taskType == TaskType.oneTime) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Due Date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (_dueDate != null)
                    TextButton(
                      onPressed: () => setState(() => _dueDate = null),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDueDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      Text(
                        _dueDate != null
                            ? '${_dueDate!.month}/${_dueDate!.day}/${_dueDate!.year}'
                            : 'Select due date',
                        style: TextStyle(
                          color: _dueDate != null ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Estimated Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated Duration',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_estimatedDuration != null)
                  Text(
                    _formatDuration(_estimatedDuration!),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _DurationChip(
                  label: '15m',
                  isSelected: _estimatedDuration == 15,
                  onTap: () => setState(() => _estimatedDuration = 15),
                ),
                _DurationChip(
                  label: '30m',
                  isSelected: _estimatedDuration == 30,
                  onTap: () => setState(() => _estimatedDuration = 30),
                ),
                _DurationChip(
                  label: '1h',
                  isSelected: _estimatedDuration == 60,
                  onTap: () => setState(() => _estimatedDuration = 60),
                ),
                _DurationChip(
                  label: '2h',
                  isSelected: _estimatedDuration == 120,
                  onTap: () => setState(() => _estimatedDuration = 120),
                ),
                _DurationChip(
                  label: 'Custom',
                  isSelected: _estimatedDuration != null &&
                      ![15, 30, 60, 120].contains(_estimatedDuration),
                  onTap: _selectCustomDuration,
                ),
              ],
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
                  '${_subtasks.length} item(s)',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_subtasks.isNotEmpty) ...[
              ...List.generate(_subtasks.length, (index) {
                final subtask = _subtasks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subtask.title,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _subtasks.removeAt(index);
                          });
                        },
                        child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: 'Add subtask...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: _addSubtask,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _addSubtask(_subtaskController.text),
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Selection (multi-select)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stats Affected',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${_selectedStats.length} selected',
                  style: TextStyle(
                    color: _selectedStats.isNotEmpty ? AppColors.success : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to select • Long-press to adjust XP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppColors.statNames.map((stat) {
                final isSelected = _selectedStats.containsKey(stat);
                final color = AppColors.getStatColor(stat);
                final xp = _selectedStats[stat] ?? 0;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedStats.remove(stat);
                      } else {
                        _selectedStats[stat] = 10;
                      }
                    });
                  },
                  onLongPress: isSelected ? () => _showStatXpDialog(stat) : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.2) : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : AppColors.surfaceLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppColors.getStatIcon(stat),
                          size: 14,
                          color: isSelected ? color : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppColors.getStatAbbreviation(stat),
                          style: TextStyle(
                            color: isSelected ? color : AppColors.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '+$xp',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // XP Reward
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total XP Reward',
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
              min: 5,
              max: 50,
              divisions: 9,
              label: '$_xpReward XP',
              onChanged: (value) => setState(() => _xpReward = value.round()),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createTask,
                child: const Text('Create Task'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _analyzeWithAI() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title first')),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final analysis = await aiService.analyzeTask(
        title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      setState(() {
        _selectedStats = Map.from(analysis.suggestedStats);
        _xpReward = analysis.suggestedXP;
        _aiReasoning = analysis.reasoning ?? 'Analyzed based on task keywords';
        _tags = analysis.tags;
        _isAnalyzing = false;
        _hasAnalyzed = true;
        _useAiSuggestions = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('AI detected ${_selectedStats.length} stat(s): ${_selectedStats.keys.map((s) => AppColors.getStatAbbreviation(s)).join(", ")}'),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI analysis failed, please select stats manually'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  void _showStatXpDialog(String stat) {
    int xp = _selectedStats[stat] ?? 10;
    final color = AppColors.getStatColor(stat);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(AppColors.getStatIcon(stat), color: color),
              const SizedBox(width: 8),
              Text('${AppColors.getStatAbbreviation(stat)} XP'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+$xp',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppColors.getStatDescription(stat),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Slider(
                value: xp.toDouble(),
                min: 5,
                max: 25,
                divisions: 4,
                activeColor: color,
                onChanged: (v) => setDialogState(() => xp = v.round()),
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
                setState(() => _selectedStats[stat] = xp);
                Navigator.pop(context);
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
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

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
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

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _selectCustomDuration() async {
    int? minutes = _estimatedDuration;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estimated Duration'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(minutes ?? 30),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: (minutes ?? 30).toDouble(),
                min: 5,
                max: 480,
                divisions: 95,
                onChanged: (v) => setDialogState(() => minutes = v.round()),
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
            onPressed: () {
              setState(() => _estimatedDuration = minutes);
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  void _addSubtask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _subtasks.add(Subtask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.trim(),
      ));
      _subtaskController.clear();
    });
  }

  void _createTask() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    // Use AI suggestions or default to discipline
    final stats = _useAiSuggestions && _selectedStats.isNotEmpty
        ? _selectedStats
        : {'discipline': 10};

    ref.read(taskNotifierProvider.notifier).createTask(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _taskType,
      frequency: _frequency,
      statRewards: stats,
      stat: stats.keys.first,
      xpReward: _xpReward,
      aiReasoning: _aiReasoning,
      tags: _tags,
      priority: _priority,
      subtasks: _subtasks,
      estimatedDuration: _estimatedDuration,
      dueDate: _dueDate,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task created! Complete for +$_xpReward XP'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
