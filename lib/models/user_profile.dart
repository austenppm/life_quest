import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final int level;
  final int totalXP;
  final int xpToNextLevel;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final UserStats stats;
  final UserSettings settings;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.level = 1,
    this.totalXP = 0,
    this.xpToNextLevel = 100,
    required this.createdAt,
    required this.lastActiveAt,
    required this.stats,
    required this.settings,
  });

  factory UserProfile.newUser({
    required String id,
    required String email,
    required String displayName,
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      createdAt: now,
      lastActiveAt: now,
      stats: const UserStats(),
      settings: const UserSettings(),
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Adventurer',
      avatarUrl: data['avatarUrl'],
      level: data['level'] ?? 1,
      totalXP: data['totalXP'] ?? 0,
      xpToNextLevel: data['xpToNextLevel'] ?? 100,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: UserStats.fromMap(data['stats'] ?? {}),
      settings: UserSettings.fromMap(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'level': level,
      'totalXP': totalXP,
      'xpToNextLevel': xpToNextLevel,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'stats': stats.toMap(),
      'settings': settings.toMap(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? avatarUrl,
    int? level,
    int? totalXP,
    int? xpToNextLevel,
    DateTime? lastActiveAt,
    UserStats? stats,
    UserSettings? settings,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      totalXP: totalXP ?? this.totalXP,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
    );
  }

  double get levelProgress => totalXP / xpToNextLevel;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        avatarUrl,
        level,
        totalXP,
        xpToNextLevel,
        createdAt,
        lastActiveAt,
        stats,
        settings,
      ];
}

class UserStats extends Equatable {
  // Physical Stats
  final int strength;      // STR - Physical power, weightlifting, carrying
  final int dexterity;     // DEX - Agility, reflexes, cardio, flexibility
  final int constitution;  // CON - Health, stamina, endurance, nutrition
  
  // Mental Stats
  final int intelligence;  // INT - Learning, memory, reasoning, study
  final int wisdom;        // WIS - Perception, insight, mindfulness
  final int focus;         // FOC - Concentration, deep work, attention
  
  // Social Stats
  final int charisma;      // CHA - Leadership, persuasion, confidence
  final int social;        // SOC - Networking, relationships, communication
  
  // Lifestyle Stats
  final int discipline;    // DIS - Habits, consistency, work ethic
  final int creativity;    // CRE - Art, music, writing, innovation

  // XP within each stat
  final int strengthXP;
  final int dexterityXP;
  final int constitutionXP;
  final int intelligenceXP;
  final int wisdomXP;
  final int focusXP;
  final int charismaXP;
  final int socialXP;
  final int disciplineXP;
  final int creativityXP;

  const UserStats({
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.focus = 10,
    this.charisma = 10,
    this.social = 10,
    this.discipline = 10,
    this.creativity = 10,
    this.strengthXP = 0,
    this.dexterityXP = 0,
    this.constitutionXP = 0,
    this.intelligenceXP = 0,
    this.wisdomXP = 0,
    this.focusXP = 0,
    this.charismaXP = 0,
    this.socialXP = 0,
    this.disciplineXP = 0,
    this.creativityXP = 0,
  });

  // D&D-style modifiers: (stat - 10) / 2
  int get strengthMod => (strength - 10) ~/ 2;
  int get dexterityMod => (dexterity - 10) ~/ 2;
  int get constitutionMod => (constitution - 10) ~/ 2;
  int get intelligenceMod => (intelligence - 10) ~/ 2;
  int get wisdomMod => (wisdom - 10) ~/ 2;
  int get focusMod => (focus - 10) ~/ 2;
  int get charismaMod => (charisma - 10) ~/ 2;
  int get socialMod => (social - 10) ~/ 2;
  int get disciplineMod => (discipline - 10) ~/ 2;
  int get creativityMod => (creativity - 10) ~/ 2;

  String formatMod(int mod) => mod >= 0 ? '+$mod' : '$mod';

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      strength: map['strength'] ?? 10,
      dexterity: map['dexterity'] ?? 10,
      constitution: map['constitution'] ?? 10,
      intelligence: map['intelligence'] ?? 10,
      wisdom: map['wisdom'] ?? 10,
      focus: map['focus'] ?? 10,
      charisma: map['charisma'] ?? 10,
      social: map['social'] ?? 10,
      discipline: map['discipline'] ?? 10,
      creativity: map['creativity'] ?? 10,
      strengthXP: map['strengthXP'] ?? 0,
      dexterityXP: map['dexterityXP'] ?? 0,
      constitutionXP: map['constitutionXP'] ?? 0,
      intelligenceXP: map['intelligenceXP'] ?? 0,
      wisdomXP: map['wisdomXP'] ?? 0,
      focusXP: map['focusXP'] ?? 0,
      charismaXP: map['charismaXP'] ?? 0,
      socialXP: map['socialXP'] ?? 0,
      disciplineXP: map['disciplineXP'] ?? 0,
      creativityXP: map['creativityXP'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'focus': focus,
      'charisma': charisma,
      'social': social,
      'discipline': discipline,
      'creativity': creativity,
      'strengthXP': strengthXP,
      'dexterityXP': dexterityXP,
      'constitutionXP': constitutionXP,
      'intelligenceXP': intelligenceXP,
      'wisdomXP': wisdomXP,
      'focusXP': focusXP,
      'charismaXP': charismaXP,
      'socialXP': socialXP,
      'disciplineXP': disciplineXP,
      'creativityXP': creativityXP,
    };
  }

  int getStatLevel(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
      case 'str':
        return strength;
      case 'dexterity':
      case 'dex':
        return dexterity;
      case 'constitution':
      case 'con':
        return constitution;
      case 'intelligence':
      case 'int':
        return intelligence;
      case 'wisdom':
      case 'wis':
        return wisdom;
      case 'focus':
      case 'foc':
        return focus;
      case 'charisma':
      case 'cha':
        return charisma;
      case 'social':
      case 'soc':
        return social;
      case 'discipline':
      case 'dis':
        return discipline;
      case 'creativity':
      case 'cre':
        return creativity;
      default:
        return 10;
    }
  }

  int getStatXP(String stat) {
    switch (stat.toLowerCase()) {
      case 'strength':
      case 'str':
        return strengthXP;
      case 'dexterity':
      case 'dex':
        return dexterityXP;
      case 'constitution':
      case 'con':
        return constitutionXP;
      case 'intelligence':
      case 'int':
        return intelligenceXP;
      case 'wisdom':
      case 'wis':
        return wisdomXP;
      case 'focus':
      case 'foc':
        return focusXP;
      case 'charisma':
      case 'cha':
        return charismaXP;
      case 'social':
      case 'soc':
        return socialXP;
      case 'discipline':
      case 'dis':
        return disciplineXP;
      case 'creativity':
      case 'cre':
        return creativityXP;
      default:
        return 0;
    }
  }

  int getStatMod(String stat) {
    return (getStatLevel(stat) - 10) ~/ 2;
  }

  int get totalStatPoints =>
      strength + dexterity + constitution + intelligence + wisdom +
      focus + charisma + social + discipline + creativity;

  List<MapEntry<String, int>> get allStats => [
        MapEntry('strength', strength),
        MapEntry('dexterity', dexterity),
        MapEntry('constitution', constitution),
        MapEntry('intelligence', intelligence),
        MapEntry('wisdom', wisdom),
        MapEntry('focus', focus),
        MapEntry('charisma', charisma),
        MapEntry('social', social),
        MapEntry('discipline', discipline),
        MapEntry('creativity', creativity),
      ];

  // Physical stats
  List<MapEntry<String, int>> get physicalStats => [
        MapEntry('strength', strength),
        MapEntry('dexterity', dexterity),
        MapEntry('constitution', constitution),
      ];

  // Mental stats
  List<MapEntry<String, int>> get mentalStats => [
        MapEntry('intelligence', intelligence),
        MapEntry('wisdom', wisdom),
        MapEntry('focus', focus),
      ];

  // Social stats
  List<MapEntry<String, int>> get socialStats => [
        MapEntry('charisma', charisma),
        MapEntry('social', social),
      ];

  // Lifestyle stats
  List<MapEntry<String, int>> get lifestyleStats => [
        MapEntry('discipline', discipline),
        MapEntry('creativity', creativity),
      ];

  static const List<String> statNames = [
    'strength', 'dexterity', 'constitution', 'intelligence', 'wisdom',
    'focus', 'charisma', 'social', 'discipline', 'creativity'
  ];

  static const List<String> statAbbreviations = [
    'STR', 'DEX', 'CON', 'INT', 'WIS', 'FOC', 'CHA', 'SOC', 'DIS', 'CRE'
  ];

  static const Map<String, String> statCategories = {
    'strength': 'Physical',
    'dexterity': 'Physical',
    'constitution': 'Physical',
    'intelligence': 'Mental',
    'wisdom': 'Mental',
    'focus': 'Mental',
    'charisma': 'Social',
    'social': 'Social',
    'discipline': 'Lifestyle',
    'creativity': 'Lifestyle',
  };

  UserStats copyWith({
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? focus,
    int? charisma,
    int? social,
    int? discipline,
    int? creativity,
    int? strengthXP,
    int? dexterityXP,
    int? constitutionXP,
    int? intelligenceXP,
    int? wisdomXP,
    int? focusXP,
    int? charismaXP,
    int? socialXP,
    int? disciplineXP,
    int? creativityXP,
  }) {
    return UserStats(
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      focus: focus ?? this.focus,
      charisma: charisma ?? this.charisma,
      social: social ?? this.social,
      discipline: discipline ?? this.discipline,
      creativity: creativity ?? this.creativity,
      strengthXP: strengthXP ?? this.strengthXP,
      dexterityXP: dexterityXP ?? this.dexterityXP,
      constitutionXP: constitutionXP ?? this.constitutionXP,
      intelligenceXP: intelligenceXP ?? this.intelligenceXP,
      wisdomXP: wisdomXP ?? this.wisdomXP,
      focusXP: focusXP ?? this.focusXP,
      charismaXP: charismaXP ?? this.charismaXP,
      socialXP: socialXP ?? this.socialXP,
      disciplineXP: disciplineXP ?? this.disciplineXP,
      creativityXP: creativityXP ?? this.creativityXP,
    );
  }

  @override
  List<Object> get props => [
        strength, dexterity, constitution, intelligence, wisdom,
        focus, charisma, social, discipline, creativity,
        strengthXP, dexterityXP, constitutionXP, intelligenceXP, wisdomXP,
        focusXP, charismaXP, socialXP, disciplineXP, creativityXP,
      ];
}

class UserSettings extends Equatable {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String theme;
  final bool dailyReminderEnabled;
  final String dailyReminderTime;

  const UserSettings({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.theme = 'dark',
    this.dailyReminderEnabled = true,
    this.dailyReminderTime = '09:00',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      theme: map['theme'] ?? 'dark',
      dailyReminderEnabled: map['dailyReminderEnabled'] ?? true,
      dailyReminderTime: map['dailyReminderTime'] ?? '09:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'theme': theme,
      'dailyReminderEnabled': dailyReminderEnabled,
      'dailyReminderTime': dailyReminderTime,
    };
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? theme,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      theme: theme ?? this.theme,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
    );
  }

  @override
  List<Object> get props => [
        notificationsEnabled,
        soundEnabled,
        vibrationEnabled,
        theme,
        dailyReminderEnabled,
        dailyReminderTime,
      ];
}
