import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../theme/app_theme.dart';
import '../../models/task.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_tile.dart';
import 'create_task_dialog.dart';

enum TaskViewMode { list, kanban, calendar }

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TaskViewMode _viewMode = TaskViewMode.list;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                // View mode switcher
                _ViewModeSwitcher(
                  currentMode: _viewMode,
                  onChanged: (mode) => setState(() => _viewMode = mode),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case TaskViewMode.list:
        return _buildListView();
      case TaskViewMode.kanban:
        return _buildKanbanView();
      case TaskViewMode.calendar:
        return _buildCalendarView();
    }
  }

  Widget _buildListView() {
    final dailyTasks = ref.watch(dailyTasksProvider);
    final oneTimeTasks = ref.watch(oneTimeTasksProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Daily (${dailyTasks.length})'),
            Tab(text: 'One-time (${oneTimeTasks.length})'),
          ],
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildTaskList(dailyTasks, 'daily'),
              _buildTaskList(oneTimeTasks, 'one-time'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks, String type) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to create one',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ),
      );
    }

    // Sort by priority
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) => b.priority.value.compareTo(a.priority.value));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sortedTasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final task = sortedTasks[index];
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
    );
  }

  Widget _buildKanbanView() {
    final tasksByStatus = ref.watch(tasksByStatusProvider);

    return Row(
      children: [
        _KanbanColumn(
          title: 'To Do',
          tasks: tasksByStatus[TaskStatus.todo] ?? [],
          status: TaskStatus.todo,
          color: AppColors.textMuted,
          onTaskTap: (task) => context.go('/tasks/${task.id}'),
          onStatusChange: (task, status) {
            ref.read(taskNotifierProvider.notifier).updateTaskStatus(task.id, status);
          },
          onToggle: (task) {
            if (task.isCompletedToday()) {
              ref.read(taskNotifierProvider.notifier).uncompleteTask(task);
            } else {
              ref.read(taskNotifierProvider.notifier).completeTask(task);
            }
          },
        ),
        _KanbanColumn(
          title: 'In Progress',
          tasks: tasksByStatus[TaskStatus.inProgress] ?? [],
          status: TaskStatus.inProgress,
          color: AppColors.primary,
          onTaskTap: (task) => context.go('/tasks/${task.id}'),
          onStatusChange: (task, status) {
            ref.read(taskNotifierProvider.notifier).updateTaskStatus(task.id, status);
          },
          onToggle: (task) {
            if (task.isCompletedToday()) {
              ref.read(taskNotifierProvider.notifier).uncompleteTask(task);
            } else {
              ref.read(taskNotifierProvider.notifier).completeTask(task);
            }
          },
        ),
        _KanbanColumn(
          title: 'Done',
          tasks: tasksByStatus[TaskStatus.done] ?? [],
          status: TaskStatus.done,
          color: AppColors.success,
          onTaskTap: (task) => context.go('/tasks/${task.id}'),
          onStatusChange: (task, status) {
            ref.read(taskNotifierProvider.notifier).updateTaskStatus(task.id, status);
          },
          onToggle: (task) {
            if (task.isCompletedToday()) {
              ref.read(taskNotifierProvider.notifier).uncompleteTask(task);
            } else {
              ref.read(taskNotifierProvider.notifier).completeTask(task);
            }
          },
        ),
      ],
    );
  }

  Widget _buildCalendarView() {
    final tasksForSelectedDay = ref.watch(tasksByDateProvider(_selectedDay));
    final allTasks = ref.watch(tasksProvider).valueOrNull ?? [];

    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: (day) {
            return allTasks.where((task) {
              if (task.dueDate == null) return false;
              return task.dueDate!.year == day.year &&
                  task.dueDate!.month == day.month &&
                  task.dueDate!.day == day.day;
            }).toList();
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            outsideDaysVisible: false,
            weekendTextStyle: const TextStyle(color: AppColors.textMuted),
            defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.textPrimary),
            rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.textPrimary),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AppColors.textMuted),
            weekendStyle: TextStyle(color: AppColors.textMuted),
          ),
          calendarFormat: CalendarFormat.month,
        ),
        const Divider(color: AppColors.surfaceLight),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Tasks for ${_formatDate(_selectedDay)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${tasksForSelectedDay.length} task(s)',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: tasksForSelectedDay.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: AppColors.textMuted.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No tasks for this day',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasksForSelectedDay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasksForSelectedDay[index];
                    return TaskTile(
                      task: task,
                      compact: true,
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
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return '${date.month}/${date.day}/${date.year}';
  }

  void _showCreateTaskDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateTaskDialog(),
    );
  }
}

class _ViewModeSwitcher extends StatelessWidget {
  final TaskViewMode currentMode;
  final ValueChanged<TaskViewMode> onChanged;

  const _ViewModeSwitcher({
    required this.currentMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewModeButton(
            icon: Icons.list,
            isSelected: currentMode == TaskViewMode.list,
            onTap: () => onChanged(TaskViewMode.list),
            tooltip: 'List View',
          ),
          _ViewModeButton(
            icon: Icons.view_kanban,
            isSelected: currentMode == TaskViewMode.kanban,
            onTap: () => onChanged(TaskViewMode.kanban),
            tooltip: 'Kanban View',
          ),
          _ViewModeButton(
            icon: Icons.calendar_month,
            isSelected: currentMode == TaskViewMode.calendar,
            onTap: () => onChanged(TaskViewMode.calendar),
            tooltip: 'Calendar View',
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final TaskStatus status;
  final Color color;
  final Function(Task) onTaskTap;
  final Function(Task, TaskStatus) onStatusChange;
  final Function(Task) onToggle;

  const _KanbanColumn({
    required this.title,
    required this.tasks,
    required this.status,
    required this.color,
    required this.onTaskTap,
    required this.onStatusChange,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            // Column header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Tasks list
            Expanded(
              child: DragTarget<Task>(
                onAcceptWithDetails: (details) {
                  if (details.data.status != status) {
                    onStatusChange(details.data, status);
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? color.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: candidateData.isNotEmpty
                          ? Border.all(color: color.withOpacity(0.5), width: 2)
                          : null,
                    ),
                    child: tasks.isEmpty
                        ? Center(
                            child: Text(
                              'No tasks',
                              style: TextStyle(
                                color: AppColors.textMuted.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(4),
                            itemCount: tasks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final task = tasks[index];
                              return LongPressDraggable<Task>(
                                data: task,
                                feedback: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width / 3 - 20,
                                    child: _KanbanTaskCard(
                                      task: task,
                                      onTap: () {},
                                      onToggle: () {},
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _KanbanTaskCard(
                                    task: task,
                                    onTap: () => onTaskTap(task),
                                    onToggle: () => onToggle(task),
                                  ),
                                ),
                                child: _KanbanTaskCard(
                                  task: task,
                                  onTap: () => onTaskTap(task),
                                  onToggle: () => onToggle(task),
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _KanbanTaskCard({
    required this.task,
    required this.onTap,
    required this.onToggle,
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

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompletedToday();
    final priorityColor = _getPriorityColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.success.withOpacity(0.1) : AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: task.isHighPriority
                ? priorityColor.withOpacity(0.5)
                : AppColors.surfaceLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority dot
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (task.hasSubtasks) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: task.subtasksProgress,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation(
                          task.allSubtasksCompleted
                              ? AppColors.success
                              : AppColors.primary,
                        ),
                        minHeight: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${task.completedSubtasksCount}/${task.totalSubtasksCount}',
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.getStatColor(task.statAffected).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.statAffected.substring(0, 3).toUpperCase(),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getStatColor(task.statAffected),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '+${task.xpReward}',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
