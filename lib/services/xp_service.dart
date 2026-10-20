import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';
import 'firestore_service.dart';

class XPService {
  final FirestoreService _firestoreService;

  XPService(this._firestoreService);

  // XP required for each level (uses exponential scaling)
  static int xpForLevel(int level) {
    // Base XP: 100, increases by 50% each level
    return (100 * pow(1.5, level - 1)).round();
  }

  // Calculate total XP needed to reach a level from level 1
  static int totalXpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += xpForLevel(i);
    }
    return total;
  }

  // XP required for stat level up
  static int xpForStatLevel(int level) {
    return (50 * pow(1.3, level - 1)).round();
  }

  // Award XP for completing a task
  Future<XPResult> awardTaskXP({
    required String userId,
    required Task task,
    required UserProfile profile,
  }) async {
    int xpGained = task.xpReward;

    // Streak bonus
    if (task.currentStreak > 0) {
      final streakBonus = min(task.currentStreak * 2, 20); // Max 20% bonus
      xpGained = (xpGained * (1 + streakBonus / 100)).round();
    }

    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpGained,
      statName: task.statAffected,
      statXP: (xpGained * 0.5).round(), // Half XP goes to stat
    );
  }

  // Award XP for completing a quest
  Future<XPResult> awardQuestXP({
    required String userId,
    required Quest quest,
    required UserProfile profile,
  }) async {
    int xpGained = quest.xpReward * quest.difficultyMultiplier;

    // Award stat XP from quest rewards
    Map<String, int> statXPGains = {};
    for (var entry in quest.statRewards.entries) {
      statXPGains[entry.key] = entry.value * quest.difficultyMultiplier;
    }

    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpGained,
      statXPMap: statXPGains,
    );
  }

  // Award XP for workout
  Future<XPResult> awardWorkoutXP({
    required String userId,
    required Workout workout,
    required UserProfile profile,
  }) async {
    // Base XP: 5 per minute + bonuses for intensity
    int xpGained = workout.durationMinutes * 5;

    // Bonus for number of exercises
    xpGained += workout.exercises.length * 10;

    // Bonus for total sets
    xpGained += workout.totalSets * 2;

    // Workouts affect multiple stats
    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpGained,
      statXPMap: {
        'dexterity': (xpGained * 0.3).round(),  // Cardio/agility
        'strength': (xpGained * 0.3).round(),   // Raw power
        'constitution': (xpGained * 0.2).round(), // Endurance
        'discipline': (xpGained * 0.1).round(),  // Consistency
      },
    );
  }

  // Award XP for study session
  Future<XPResult> awardStudyXP({
    required String userId,
    required StudySession session,
    required UserProfile profile,
  }) async {
    // Base XP: 3 per minute
    int xpGained = session.calculatedDuration * 3;

    // Focus bonus
    xpGained = (xpGained * session.focusScore / 100).round();

    // Study sessions affect multiple stats
    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpGained,
      statXPMap: {
        'intelligence': (xpGained * 0.4).round(), // Knowledge
        'focus': (xpGained * 0.3).round(),        // Concentration
        'discipline': (xpGained * 0.2).round(),   // Consistency
      },
    );
  }

  // Award XP for work
  Future<XPResult> awardWorkXP({
    required String userId,
    required WorkLog log,
    required UserProfile profile,
  }) async {
    // Base XP: 2 per minute
    int xpGained = log.calculatedDuration * 2;

    // Bonus for tasks completed
    xpGained += log.tasksCompleted.length * 15;

    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpGained,
      statName: 'discipline',
      statXP: (xpGained * 0.4).round(),
    );
  }

  // Core XP awarding logic
  Future<XPResult> _awardXP({
    required String userId,
    required UserProfile profile,
    required int xpAmount,
    String? statName,
    int? statXP,
    String? secondaryStatName,
    int? secondaryStatXP,
    Map<String, int>? statXPMap,
  }) async {
    final result = XPResult(xpGained: xpAmount);

    // Calculate new total XP and check for level up
    int newTotalXP = profile.totalXP + xpAmount;
    int newLevel = profile.level;
    int newXPToNext = profile.xpToNextLevel;

    // Check for level ups
    while (newTotalXP >= newXPToNext) {
      newTotalXP -= newXPToNext;
      newLevel++;
      newXPToNext = xpForLevel(newLevel);
      result.leveledUp = true;
      result.newLevel = newLevel;
    }

    // Calculate stat updates
    UserStats newStats = profile.stats;
    List<String> statsLeveledUp = [];

    // Process stat XP map if provided
    if (statXPMap != null) {
      for (var entry in statXPMap.entries) {
        final statResult = _processStatXP(newStats, entry.key, entry.value);
        newStats = statResult.stats;
        if (statResult.leveledUp) {
          statsLeveledUp.add(entry.key);
        }
      }
    }

    // Process primary stat
    if (statName != null && statXP != null) {
      final statResult = _processStatXP(newStats, statName, statXP);
      newStats = statResult.stats;
      if (statResult.leveledUp) {
        statsLeveledUp.add(statName);
      }
    }

    // Process secondary stat
    if (secondaryStatName != null && secondaryStatXP != null) {
      final statResult = _processStatXP(newStats, secondaryStatName, secondaryStatXP);
      newStats = statResult.stats;
      if (statResult.leveledUp) {
        statsLeveledUp.add(secondaryStatName);
      }
    }

    result.statsLeveledUp = statsLeveledUp;

    // Update Firestore
    await _firestoreService.updateUserProfile(userId, {
      'totalXP': newTotalXP,
      'level': newLevel,
      'xpToNextLevel': newXPToNext,
      'stats': newStats.toMap(),
      'lastActiveAt': FieldValue.serverTimestamp(),
    });

    return result;
  }

  // Process XP for a single stat
  _StatXPResult _processStatXP(UserStats stats, String statName, int xpAmount) {
    final currentLevel = stats.getStatLevel(statName);
    final currentXP = stats.getStatXP(statName);
    final xpNeeded = xpForStatLevel(currentLevel);

    int newXP = currentXP + xpAmount;
    int newLevel = currentLevel;
    bool leveledUp = false;

    // Check for stat level up
    while (newXP >= xpNeeded) {
      newXP -= xpNeeded;
      newLevel++;
      leveledUp = true;
    }

    // Update stats based on which stat it is
    UserStats newStats;
    switch (statName.toLowerCase()) {
      case 'strength':
      case 'str':
        newStats = stats.copyWith(strength: newLevel, strengthXP: newXP);
        break;
      case 'dexterity':
      case 'dex':
      case 'fitness': // Legacy support
        newStats = stats.copyWith(dexterity: newLevel, dexterityXP: newXP);
        break;
      case 'constitution':
      case 'con':
        newStats = stats.copyWith(constitution: newLevel, constitutionXP: newXP);
        break;
      case 'intelligence':
      case 'int':
        newStats = stats.copyWith(intelligence: newLevel, intelligenceXP: newXP);
        break;
      case 'wisdom':
      case 'wis':
        newStats = stats.copyWith(wisdom: newLevel, wisdomXP: newXP);
        break;
      case 'focus':
      case 'foc':
        newStats = stats.copyWith(focus: newLevel, focusXP: newXP);
        break;
      case 'charisma':
      case 'cha':
        newStats = stats.copyWith(charisma: newLevel, charismaXP: newXP);
        break;
      case 'social':
      case 'soc':
        newStats = stats.copyWith(social: newLevel, socialXP: newXP);
        break;
      case 'discipline':
      case 'dis':
        newStats = stats.copyWith(discipline: newLevel, disciplineXP: newXP);
        break;
      case 'creativity':
      case 'cre':
        newStats = stats.copyWith(creativity: newLevel, creativityXP: newXP);
        break;
      default:
        newStats = stats;
    }

    return _StatXPResult(stats: newStats, leveledUp: leveledUp);
  }

  // Award XP for completing a task with multi-stat support
  Future<XPResult> awardTaskXPMultiStat({
    required String userId,
    required Task task,
    required UserProfile profile,
  }) async {
    int xpGained = task.xpReward;

    // Streak bonus
    if (task.currentStreak > 0) {
      final streakBonus = min(task.currentStreak * 2, 20); // Max 20% bonus
      xpGained = (xpGained * (1 + streakBonus / 100)).round();
    }

    // Build stat XP map from task's stat rewards
    Map<String, int> statXPGains = {};
    if (task.statRewards.isNotEmpty) {
      for (var entry in task.statRewards.entries) {
        statXPGains[entry.key] = entry.value;
      }
    } else {
      // Fall back to single stat
      statXPGains[task.stat] = (xpGained * 0.5).round();
    }

    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpGained,
      statXPMap: statXPGains,
    );
  }

  // Award XP for logging weight
  Future<XPResult> awardWeightLogXP({
    required String userId,
    required UserProfile profile,
    required int xpAmount,
  }) async {
    return await _awardXP(
      userId: userId,
      profile: profile,
      xpAmount: xpAmount,
      statXPMap: {
        'constitution': (xpAmount * 0.6).round(),
        'discipline': (xpAmount * 0.4).round(),
      },
    );
  }
}

class XPResult {
  final int xpGained;
  bool leveledUp;
  int? newLevel;
  List<String> statsLeveledUp;

  XPResult({
    required this.xpGained,
    this.leveledUp = false,
    this.newLevel,
    this.statsLeveledUp = const [],
  });
}

class _StatXPResult {
  final UserStats stats;
  final bool leveledUp;

  _StatXPResult({required this.stats, required this.leveledUp});
}
