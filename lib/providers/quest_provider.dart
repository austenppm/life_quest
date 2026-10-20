import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/quest.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/xp_service.dart';
import '../services/notification_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';
import 'task_provider.dart';

// Quests stream provider
final questsProvider = StreamProvider<List<Quest>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchQuests(user.uid);
});

// Active quests provider
final activeQuestsProvider = Provider<List<Quest>>((ref) {
  final quests = ref.watch(questsProvider).valueOrNull ?? [];
  return quests.where((q) => q.status == QuestStatus.active).toList();
});

// Completed quests provider
final completedQuestsProvider = Provider<List<Quest>>((ref) {
  final quests = ref.watch(questsProvider).valueOrNull ?? [];
  return quests.where((q) => q.status == QuestStatus.completed).toList();
});

// Quest notifier
class QuestNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final XPService _xpService;
  final String? _userId;
  final UserProfile? _profile;

  QuestNotifier(
    this._firestoreService,
    this._xpService,
    this._userId,
    this._profile,
  ) : super(const AsyncValue.data(null));

  Future<void> createQuest({
    required String title,
    String? description,
    QuestDifficulty difficulty = QuestDifficulty.medium,
    List<String> subtaskTitles = const [],
    Map<String, int> statRewards = const {},
    int xpReward = 50,
    DateTime? deadline,
    String? iconName,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final subtasks = subtaskTitles
          .map((title) => SubTask(
                id: const Uuid().v4(),
                title: title,
              ))
          .toList();

      final quest = Quest(
        id: const Uuid().v4(),
        userId: _userId,
        title: title,
        description: description,
        difficulty: difficulty,
        subtasks: subtasks,
        statRewards: statRewards,
        xpReward: xpReward,
        deadline: deadline,
        createdAt: DateTime.now(),
        iconName: iconName,
      );

      await _firestoreService.createQuest(_userId, quest);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleSubtask(Quest quest, String subtaskId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updatedSubtasks = quest.subtasks.map((s) {
        if (s.id == subtaskId) {
          return s.copyWith(
            isCompleted: !s.isCompleted,
            completedAt: !s.isCompleted ? DateTime.now() : null,
          );
        }
        return s;
      }).toList();

      await _firestoreService.updateQuest(_userId, quest.id, {
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
      });

      // Check if all subtasks completed
      final allCompleted = updatedSubtasks.every((s) => s.isCompleted);
      if (allCompleted && _profile != null) {
        await completeQuest(quest.copyWith(subtasks: updatedSubtasks));
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSubtask(Quest quest, String title) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final newSubtask = SubTask(
        id: const Uuid().v4(),
        title: title,
      );

      final updatedSubtasks = [...quest.subtasks, newSubtask];

      await _firestoreService.updateQuest(_userId, quest.id, {
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeSubtask(Quest quest, String subtaskId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updatedSubtasks =
          quest.subtasks.where((s) => s.id != subtaskId).toList();

      await _firestoreService.updateQuest(_userId, quest.id, {
        'subtasks': updatedSubtasks.map((s) => s.toMap()).toList(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeQuest(Quest quest) async {
    if (_userId == null || _profile == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateQuest(_userId, quest.id, {
        'status': QuestStatus.completed.name,
        'completedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Award XP
      final xpResult = await _xpService.awardQuestXP(
        userId: _userId,
        quest: quest,
        profile: _profile,
      );

      if (xpResult.leveledUp && xpResult.newLevel != null) {
        await NotificationService.showLevelUpNotification(xpResult.newLevel!);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> abandonQuest(String questId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.updateQuest(_userId, questId, {
        'status': QuestStatus.abandoned.name,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteQuest(String questId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteQuest(_userId, questId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateQuest(
    String questId, {
    String? title,
    String? description,
    QuestDifficulty? difficulty,
    Map<String, int>? statRewards,
    int? xpReward,
    DateTime? deadline,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (difficulty != null) updates['difficulty'] = difficulty.name;
      if (statRewards != null) updates['statRewards'] = statRewards;
      if (xpReward != null) updates['xpReward'] = xpReward;
      if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);

      await _firestoreService.updateQuest(_userId, questId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final questNotifierProvider =
    StateNotifierProvider<QuestNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final xpService = ref.watch(xpServiceProvider);
  final user = ref.watch(currentUserProvider);
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return QuestNotifier(firestoreService, xpService, user?.uid, profile);
});
