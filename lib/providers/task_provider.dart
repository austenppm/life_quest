import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../models/task_project.dart';
import '../models/task_template.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/xp_service.dart';
import '../services/notification_service.dart';
import '../services/ai_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// XP service provider
final xpServiceProvider = Provider<XPService>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return XPService(firestoreService);
});

// Tasks stream provider
final tasksProvider = StreamProvider<List<Task>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchTasks(user.uid);
});

// Today's tasks provider
final todayTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((task) => task.shouldShowToday()).toList();
});

// Completed today count provider
final completedTodayCountProvider = Provider<int>((ref) {
  final tasks = ref.watch(todayTasksProvider);
  return tasks.where((task) => task.isCompletedToday()).length;
});

// Daily tasks provider
final dailyTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((task) => task.type == TaskType.daily).toList();
});

// One-time tasks provider
final oneTimeTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks
      .where((task) => task.type == TaskType.oneTime && !task.isCompleted)
      .toList();
});

// Tasks by status (for Kanban view)
final tasksByStatusProvider = Provider<Map<TaskStatus, List<Task>>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return {
    TaskStatus.todo: tasks.where((t) => t.status == TaskStatus.todo && !t.isCompleted).toList(),
    TaskStatus.inProgress: tasks.where((t) => t.status == TaskStatus.inProgress && !t.isCompleted).toList(),
    TaskStatus.done: tasks.where((t) => t.status == TaskStatus.done || t.isCompleted).toList(),
  };
});

// Tasks by priority
final tasksByPriorityProvider = Provider<Map<TaskPriority, List<Task>>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();
  return {
    TaskPriority.urgent: incompleteTasks.where((t) => t.priority == TaskPriority.urgent).toList(),
    TaskPriority.high: incompleteTasks.where((t) => t.priority == TaskPriority.high).toList(),
    TaskPriority.medium: incompleteTasks.where((t) => t.priority == TaskPriority.medium).toList(),
    TaskPriority.low: incompleteTasks.where((t) => t.priority == TaskPriority.low).toList(),
  };
});

// High priority tasks provider
final highPriorityTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks
      .where((t) => !t.isCompleted && t.isHighPriority)
      .toList()
    ..sort((a, b) => b.priority.value.compareTo(a.priority.value));
});

// Overdue tasks provider
final overdueTasksProvider = Provider<List<Task>>((ref) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((t) => t.isOverdue).toList();
});

// Tasks by date (for calendar view)
final tasksByDateProvider = Provider.family<List<Task>, DateTime>((ref, date) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  return tasks.where((task) {
    if (task.dueDate == null) return false;
    return task.dueDate!.year == date.year &&
        task.dueDate!.month == date.month &&
        task.dueDate!.day == date.day;
  }).toList();
});

// Task notifier for CRUD operations
class TaskNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final XPService _xpService;
  final String? _userId;
  final UserProfile? _profile;
  final Ref _ref;

  TaskNotifier(
    this._firestoreService,
    this._xpService,
    this._userId,
    this._profile,
    this._ref,
  ) : super(const AsyncValue.data(null));

  Future<void> createTask({
    required String title,
    String? description,
    required TaskType type,
    TaskFrequency frequency = TaskFrequency.daily,
    List<int> customDays = const [],
    String stat = 'discipline',
    Map<String, int> statRewards = const {},
    int xpReward = 10,
    DateTime? dueDate,
    DateTime? reminderTime,
    bool isFromCalendar = false,
    String? calendarEventId,
    String? aiReasoning,
    List<String> tags = const [],
    TaskPriority priority = TaskPriority.medium,
    List<Subtask> subtasks = const [],
    int? estimatedDuration,
    String? projectId,
    String? location,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final task = Task(
        id: const Uuid().v4(),
        userId: _userId,
        title: title,
        description: description,
        type: type,
        frequency: frequency,
        customDays: customDays,
        stat: stat,
        statRewards: statRewards.isEmpty ? {stat: 10} : statRewards,
        xpReward: xpReward,
        dueDate: dueDate,
        createdAt: DateTime.now(),
        reminderTime: reminderTime,
        isFromCalendar: isFromCalendar,
        calendarEventId: calendarEventId,
        aiReasoning: aiReasoning,
        tags: tags,
        priority: priority,
        subtasks: subtasks,
        estimatedDuration: estimatedDuration,
        projectId: projectId,
        location: location,
      );

      await _firestoreService.createTask(_userId, task);

      // Schedule reminder if set
      if (reminderTime != null) {
        await NotificationService.scheduleTaskReminder(
          taskId: task.id,
          taskTitle: task.title,
          reminderTime: reminderTime,
        );
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeTask(Task task) async {
    if (_userId == null || _profile == null) return;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final newCompletedDates = [...task.completedDates, now];

      // Calculate streak
      int newStreak = task.currentStreak;
      if (task.type == TaskType.daily) {
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        final wasCompletedYesterday = task.completedDates.any((date) =>
            date.year == yesterday.year &&
            date.month == yesterday.month &&
            date.day == yesterday.day);

        if (wasCompletedYesterday || task.completedDates.isEmpty) {
          newStreak++;
        } else {
          newStreak = 1; // Reset streak if chain broken
        }
      }

      final newBestStreak =
          newStreak > task.bestStreak ? newStreak : task.bestStreak;

      // Update task
      final updates = <String, dynamic>{
        'completedDates':
            newCompletedDates.map((e) => Timestamp.fromDate(e)).toList(),
        'currentStreak': newStreak,
        'bestStreak': newBestStreak,
      };

      if (task.type == TaskType.oneTime) {
        updates['isCompleted'] = true;
      }

      await _firestoreService.updateTask(_userId, task.id, updates);

      // Award XP
      final updatedTask = task.copyWith(
        completedDates: newCompletedDates,
        currentStreak: newStreak,
        bestStreak: newBestStreak,
      );

      // Award XP using multi-stat support
      final xpResult = await _xpService.awardTaskXPMultiStat(
        userId: _userId,
        task: updatedTask,
        profile: _profile,
      );

      // Show notifications for level ups
      if (xpResult.leveledUp && xpResult.newLevel != null) {
        await NotificationService.showLevelUpNotification(xpResult.newLevel!);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> uncompleteTask(Task task) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final today = DateTime.now();
      final newCompletedDates = task.completedDates
          .where((date) =>
              !(date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day))
          .toList();

      await _firestoreService.updateTask(_userId, task.id, {
        'completedDates':
            newCompletedDates.map((e) => Timestamp.fromDate(e)).toList(),
        'isCompleted': false,
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTask(
    String taskId, {
    String? title,
    String? description,
    TaskFrequency? frequency,
    List<int>? customDays,
    String? statAffected,
    int? xpReward,
    DateTime? deadline,
    DateTime? reminderTime,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (frequency != null) updates['frequency'] = frequency.name;
      if (customDays != null) updates['customDays'] = customDays;
      if (statAffected != null) updates['statAffected'] = statAffected;
      if (xpReward != null) updates['xpReward'] = xpReward;
      if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
      if (reminderTime != null) {
        updates['reminderTime'] = Timestamp.fromDate(reminderTime);
        await NotificationService.scheduleTaskReminder(
          taskId: taskId,
          taskTitle: title ?? '',
          reminderTime: reminderTime,
        );
      }

      await _firestoreService.updateTask(_userId, taskId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await NotificationService.cancelTaskReminder(taskId);
      await _firestoreService.deleteTask(_userId, taskId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderTasks(List<Task> tasks) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final batch = _firestoreService.batch();
      for (int i = 0; i < tasks.length; i++) {
        final ref = _firestoreService.tasksRef(_userId).doc(tasks[i].id);
        batch.update(ref, {'sortOrder': i});
      }
      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Subtask management
  Future<void> addSubtask(Task task, String subtaskTitle) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final newSubtask = Subtask(
        id: const Uuid().v4(),
        title: subtaskTitle,
      );
      final updatedSubtasks = [...task.subtasks, newSubtask];
      await _firestoreService.updateTask(_userId, task.id, {
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSubtask(Task task, String subtaskId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updatedSubtasks = task.subtasks.map((s) {
        if (s.id == subtaskId) {
          return s.copyWith(isCompleted: !s.isCompleted);
        }
        return s;
      }).toList();
      await _firestoreService.updateTask(_userId, task.id, {
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteSubtask(Task task, String subtaskId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updatedSubtasks = task.subtasks.where((s) => s.id != subtaskId).toList();
      await _firestoreService.updateTask(_userId, task.id, {
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTaskPriority(String taskId, TaskPriority priority) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateTask(_userId, taskId, {
        'priority': priority.name,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateTask(_userId, taskId, {
        'status': status.name,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskNotifierProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final xpService = ref.watch(xpServiceProvider);
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return TaskNotifier(firestoreService, xpService, user?.uid, profile, ref);
});

// ==================== Task Projects ====================

// Task projects stream provider
final taskProjectsProvider = StreamProvider<List<TaskProject>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('taskProjects')
      .orderBy('sortOrder')
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => TaskProject.fromFirestore(doc)).toList());
});

// Active (non-archived) projects provider
final activeProjectsProvider = Provider<List<TaskProject>>((ref) {
  final projects = ref.watch(taskProjectsProvider).valueOrNull ?? [];
  return projects.where((p) => !p.isArchived).toList();
});

// Tasks by project provider
final tasksByProjectProvider = Provider.family<List<Task>, String?>((ref, projectId) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  if (projectId == null) {
    return tasks.where((t) => t.projectId == null && !t.isCompleted).toList();
  }
  return tasks.where((t) => t.projectId == projectId && !t.isCompleted).toList();
});

// Project progress provider
final projectProgressProvider = Provider.family<double, String>((ref, projectId) {
  final tasks = ref.watch(tasksProvider).valueOrNull ?? [];
  final projectTasks = tasks.where((t) => t.projectId == projectId).toList();
  if (projectTasks.isEmpty) return 0.0;
  final completedCount = projectTasks.where((t) => t.isCompleted).length;
  return completedCount / projectTasks.length;
});

// Task project notifier for CRUD operations
class TaskProjectNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;

  TaskProjectNotifier(this._userId) : super(const AsyncValue.data(null));

  Future<String?> createProject({
    required String name,
    String? description,
    required Color color,
    String? icon,
  }) async {
    if (_userId == null) return null;

    state = const AsyncValue.loading();
    try {
      final projectId = const Uuid().v4();
      final project = TaskProject(
        id: projectId,
        userId: _userId,
        name: name,
        description: description,
        color: color,
        icon: icon,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskProjects')
          .doc(projectId)
          .set(project.toFirestore());

      state = const AsyncValue.data(null);
      return projectId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateProject(
    String projectId, {
    String? name,
    String? description,
    Color? color,
    String? icon,
    bool? isArchived,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (color != null) updates['color'] = ProjectColors.toHex(color);
      if (icon != null) updates['icon'] = icon;
      if (isArchived != null) updates['isArchived'] = isArchived;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskProjects')
          .doc(projectId)
          .update(updates);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteProject(String projectId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      // Remove project reference from all tasks with this project
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('tasks')
          .where('projectId', isEqualTo: projectId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in tasksSnapshot.docs) {
        batch.update(doc.reference, {'projectId': null});
      }

      // Delete the project
      batch.delete(FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskProjects')
          .doc(projectId));

      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reorderProjects(List<TaskProject> projects) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < projects.length; i++) {
        batch.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(_userId)
              .collection('taskProjects')
              .doc(projects[i].id),
          {'sortOrder': i},
        );
      }
      await batch.commit();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskProjectNotifierProvider =
    StateNotifierProvider<TaskProjectNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return TaskProjectNotifier(user?.uid);
});

// ==================== Task Templates ====================

// Task templates stream provider
final taskTemplatesProvider = StreamProvider<List<TaskTemplate>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('taskTemplates')
      .orderBy('timesUsed', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => TaskTemplate.fromFirestore(doc)).toList());
});

// Favorite templates provider
final favoriteTemplatesProvider = Provider<List<TaskTemplate>>((ref) {
  final templates = ref.watch(taskTemplatesProvider).valueOrNull ?? [];
  return templates.where((t) => t.isFavorite).toList();
});

// Task template notifier for CRUD operations
class TaskTemplateNotifier extends StateNotifier<AsyncValue<void>> {
  final String? _userId;
  final Ref _ref;

  TaskTemplateNotifier(this._userId, this._ref) : super(const AsyncValue.data(null));

  Future<String?> createTemplate({
    required String name,
    String? description,
    TaskType taskType = TaskType.oneTime,
    TaskFrequency frequency = TaskFrequency.daily,
    List<int> customDays = const [],
    String stat = 'discipline',
    Map<String, int> statRewards = const {},
    int xpReward = 10,
    TaskPriority priority = TaskPriority.medium,
    int? estimatedDuration,
    List<String> defaultSubtasks = const [],
    List<String> tags = const [],
    String? projectId,
  }) async {
    if (_userId == null) return null;

    state = const AsyncValue.loading();
    try {
      final templateId = const Uuid().v4();
      final template = TaskTemplate(
        id: templateId,
        userId: _userId,
        name: name,
        description: description,
        taskType: taskType,
        frequency: frequency,
        customDays: customDays,
        stat: stat,
        statRewards: statRewards,
        xpReward: xpReward,
        priority: priority,
        estimatedDuration: estimatedDuration,
        defaultSubtasks: defaultSubtasks,
        tags: tags,
        projectId: projectId,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskTemplates')
          .doc(templateId)
          .set(template.toFirestore());

      state = const AsyncValue.data(null);
      return templateId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Create a template from an existing task
  Future<String?> createTemplateFromTask(Task task, String templateName) async {
    return createTemplate(
      name: templateName,
      description: task.description,
      taskType: task.type,
      frequency: task.frequency,
      customDays: task.customDays,
      stat: task.stat,
      statRewards: task.statRewards,
      xpReward: task.xpReward,
      priority: task.priority,
      estimatedDuration: task.estimatedDuration,
      defaultSubtasks: task.subtasks.map((s) => s.title).toList(),
      tags: task.tags,
      projectId: task.projectId,
    );
  }

  Future<void> updateTemplate(
    String templateId, {
    String? name,
    String? description,
    TaskType? taskType,
    TaskFrequency? frequency,
    List<int>? customDays,
    String? stat,
    Map<String, int>? statRewards,
    int? xpReward,
    TaskPriority? priority,
    int? estimatedDuration,
    List<String>? defaultSubtasks,
    List<String>? tags,
    String? projectId,
    bool? isFavorite,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (taskType != null) updates['taskType'] = taskType.name;
      if (frequency != null) updates['frequency'] = frequency.name;
      if (customDays != null) updates['customDays'] = customDays;
      if (stat != null) updates['stat'] = stat;
      if (statRewards != null) updates['statRewards'] = statRewards;
      if (xpReward != null) updates['xpReward'] = xpReward;
      if (priority != null) updates['priority'] = priority.name;
      if (estimatedDuration != null) updates['estimatedDuration'] = estimatedDuration;
      if (defaultSubtasks != null) updates['defaultSubtasks'] = defaultSubtasks;
      if (tags != null) updates['tags'] = tags;
      if (projectId != null) updates['projectId'] = projectId;
      if (isFavorite != null) updates['isFavorite'] = isFavorite;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskTemplates')
          .doc(templateId)
          .update(updates);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTemplate(String templateId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskTemplates')
          .doc(templateId)
          .delete();

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleFavorite(String templateId, bool isFavorite) async {
    await updateTemplate(templateId, isFavorite: isFavorite);
  }

  /// Create a task from a template and increment usage count
  Future<void> useTemplate(TaskTemplate template, {String? customTitle, DateTime? dueDate}) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final taskId = const Uuid().v4();
      final task = template.toTask(
        taskId: taskId,
        customTitle: customTitle,
        dueDate: dueDate,
      );

      // Create the task
      final firestoreService = _ref.read(firestoreServiceProvider);
      await firestoreService.createTask(_userId, task);

      // Increment template usage count
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('taskTemplates')
          .doc(template.id)
          .update({'timesUsed': FieldValue.increment(1)});

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final taskTemplateNotifierProvider =
    StateNotifierProvider<TaskTemplateNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return TaskTemplateNotifier(user?.uid, ref);
});
