import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AchievementCategory {
  tasks,
  quests,
  fitness,
  study,
  work,
  streaks,
  social,
  milestones,
}

enum AchievementRarity { common, uncommon, rare, epic, legendary }

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconName;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int xpReward;
  final Map<String, dynamic> requirement;
  final bool isSecret;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.category,
    this.rarity = AchievementRarity.common,
    this.xpReward = 50,
    this.requirement = const {},
    this.isSecret = false,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      iconName: map['iconName'] ?? 'star',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => AchievementCategory.milestones,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == map['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      xpReward: map['xpReward'] ?? 50,
      requirement: Map<String, dynamic>.from(map['requirement'] ?? {}),
      isSecret: map['isSecret'] ?? false,
    );
  }

  String get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return '#9E9E9E';
      case AchievementRarity.uncommon:
        return '#4CAF50';
      case AchievementRarity.rare:
        return '#2196F3';
      case AchievementRarity.epic:
        return '#9C27B0';
      case AchievementRarity.legendary:
        return '#FF9800';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        iconName,
        category,
        rarity,
        xpReward,
        requirement,
        isSecret,
      ];
}

class UserAchievement extends Equatable {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final int progress;
  final int target;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.progress = 0,
    this.target = 1,
  });

  factory UserAchievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserAchievement(
      id: doc.id,
      userId: data['userId'] ?? '',
      achievementId: data['achievementId'] ?? '',
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: data['progress'] ?? 0,
      target: data['target'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'progress': progress,
      'target': target,
    };
  }

  bool get isUnlocked => progress >= target;
  double get progressPercent => target > 0 ? progress / target : 0;

  @override
  List<Object?> get props =>
      [id, userId, achievementId, unlockedAt, progress, target];
}

// Predefined achievements
class Achievements {
  static const List<Achievement> all = [
    // Task achievements
    Achievement(
      id: 'first_task',
      title: 'First Steps',
      description: 'Complete your first task',
      iconName: 'check_circle',
      category: AchievementCategory.tasks,
      rarity: AchievementRarity.common,
      xpReward: 25,
      requirement: {'tasksCompleted': 1},
    ),
    Achievement(
      id: 'task_master_10',
      title: 'Getting Things Done',
      description: 'Complete 10 tasks',
      iconName: 'task_alt',
      category: AchievementCategory.tasks,
      rarity: AchievementRarity.uncommon,
      xpReward: 50,
      requirement: {'tasksCompleted': 10},
    ),
    Achievement(
      id: 'task_master_100',
      title: 'Task Master',
      description: 'Complete 100 tasks',
      iconName: 'verified',
      category: AchievementCategory.tasks,
      rarity: AchievementRarity.rare,
      xpReward: 200,
      requirement: {'tasksCompleted': 100},
    ),

    // Streak achievements
    Achievement(
      id: 'streak_3',
      title: 'Consistent',
      description: 'Maintain a 3-day streak',
      iconName: 'local_fire_department',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.common,
      xpReward: 30,
      requirement: {'streak': 3},
    ),
    Achievement(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      iconName: 'whatshot',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.uncommon,
      xpReward: 75,
      requirement: {'streak': 7},
    ),
    Achievement(
      id: 'streak_30',
      title: 'Monthly Master',
      description: 'Maintain a 30-day streak',
      iconName: 'military_tech',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.rare,
      xpReward: 300,
      requirement: {'streak': 30},
    ),
    Achievement(
      id: 'streak_100',
      title: 'Unstoppable',
      description: 'Maintain a 100-day streak',
      iconName: 'emoji_events',
      category: AchievementCategory.streaks,
      rarity: AchievementRarity.legendary,
      xpReward: 1000,
      requirement: {'streak': 100},
    ),

    // Quest achievements
    Achievement(
      id: 'first_quest',
      title: 'Adventurer',
      description: 'Complete your first quest',
      iconName: 'explore',
      category: AchievementCategory.quests,
      rarity: AchievementRarity.common,
      xpReward: 50,
      requirement: {'questsCompleted': 1},
    ),
    Achievement(
      id: 'quest_master',
      title: 'Quest Master',
      description: 'Complete 10 quests',
      iconName: 'auto_awesome',
      category: AchievementCategory.quests,
      rarity: AchievementRarity.rare,
      xpReward: 250,
      requirement: {'questsCompleted': 10},
    ),

    // Fitness achievements
    Achievement(
      id: 'first_workout',
      title: 'Fitness Beginner',
      description: 'Log your first workout',
      iconName: 'fitness_center',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.common,
      xpReward: 25,
      requirement: {'workoutsLogged': 1},
    ),
    Achievement(
      id: 'workout_10',
      title: 'Gym Regular',
      description: 'Log 10 workouts',
      iconName: 'sports_gymnastics',
      category: AchievementCategory.fitness,
      rarity: AchievementRarity.uncommon,
      xpReward: 100,
      requirement: {'workoutsLogged': 10},
    ),

    // Study achievements
    Achievement(
      id: 'first_study',
      title: 'Scholar',
      description: 'Log your first study session',
      iconName: 'school',
      category: AchievementCategory.study,
      rarity: AchievementRarity.common,
      xpReward: 25,
      requirement: {'studySessionsLogged': 1},
    ),
    Achievement(
      id: 'study_hours_10',
      title: 'Bookworm',
      description: 'Study for 10 hours total',
      iconName: 'menu_book',
      category: AchievementCategory.study,
      rarity: AchievementRarity.uncommon,
      xpReward: 100,
      requirement: {'studyHours': 10},
    ),

    // Level milestones
    Achievement(
      id: 'level_5',
      title: 'Rising Star',
      description: 'Reach level 5',
      iconName: 'star',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.common,
      xpReward: 50,
      requirement: {'level': 5},
    ),
    Achievement(
      id: 'level_10',
      title: 'Dedicated',
      description: 'Reach level 10',
      iconName: 'star_half',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.uncommon,
      xpReward: 100,
      requirement: {'level': 10},
    ),
    Achievement(
      id: 'level_25',
      title: 'Experienced',
      description: 'Reach level 25',
      iconName: 'stars',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.rare,
      xpReward: 250,
      requirement: {'level': 25},
    ),
    Achievement(
      id: 'level_50',
      title: 'Veteran',
      description: 'Reach level 50',
      iconName: 'workspace_premium',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.epic,
      xpReward: 500,
      requirement: {'level': 50},
    ),
    Achievement(
      id: 'level_100',
      title: 'Legend',
      description: 'Reach level 100',
      iconName: 'diamond',
      category: AchievementCategory.milestones,
      rarity: AchievementRarity.legendary,
      xpReward: 1000,
      requirement: {'level': 100},
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<Achievement> getByCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }
}
