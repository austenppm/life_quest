import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Helper to extract JSON from AI response, handling markdown code blocks
String? extractJsonFromResponse(String text) {
  // Clean the text first - remove any BOM or weird characters
  var cleaned = text.trim();

  // Try to find JSON in markdown code blocks (```json or ```)
  final codeBlockPatterns = [
    RegExp(r'```json\s*([\s\S]*?)```', caseSensitive: false),
    RegExp(r'```\s*([\s\S]*?)```'),
  ];

  for (final pattern in codeBlockPatterns) {
    final match = pattern.firstMatch(cleaned);
    if (match != null) {
      final content = match.group(1)?.trim();
      if (content != null && content.isNotEmpty) {
        // Try to parse the content directly first
        if (content.startsWith('{') || content.startsWith('[')) {
          return content;
        }
        // Find JSON object or array within
        final jsonObjMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
        if (jsonObjMatch != null) return jsonObjMatch.group(0);
        final jsonArrMatch = RegExp(r'\[[\s\S]*\]').firstMatch(content);
        if (jsonArrMatch != null) return jsonArrMatch.group(0);
      }
    }
  }

  // Try to find raw JSON object (greedy match for outermost braces)
  // Find first { and last }
  final firstBrace = cleaned.indexOf('{');
  final lastBrace = cleaned.lastIndexOf('}');
  if (firstBrace != -1 && lastBrace > firstBrace) {
    return cleaned.substring(firstBrace, lastBrace + 1);
  }

  // Try array
  final firstBracket = cleaned.indexOf('[');
  final lastBracket = cleaned.lastIndexOf(']');
  if (firstBracket != -1 && lastBracket > firstBracket) {
    return cleaned.substring(firstBracket, lastBracket + 1);
  }

  return null;
}

/// Result of AI food analysis
class FoodAnalysis {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;
  final String? reasoning;

  FoodAnalysis({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    this.reasoning,
  });

  factory FoodAnalysis.fromJson(Map<String, dynamic> json) {
    return FoodAnalysis(
      name: json['name'] as String? ?? 'Unknown Food',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      servingSize: json['servingSize'] as String? ?? '1 serving',
      reasoning: json['reasoning'] as String?,
    );
  }
}

/// Result wrapper for food analysis with error handling
class FoodAnalysisResult {
  final FoodAnalysis? analysis;
  final String? error;

  FoodAnalysisResult({this.analysis, this.error});

  bool get isSuccess => analysis != null;
}

/// Result of AI task analysis
class TaskAnalysis {
  final Map<String, int> suggestedStats; // stat name -> XP amount
  final int suggestedXP;
  final String? reasoning;
  final List<String> tags;

  TaskAnalysis({
    required this.suggestedStats,
    required this.suggestedXP,
    this.reasoning,
    this.tags = const [],
  });

  factory TaskAnalysis.fromJson(Map<String, dynamic> json) {
    final statsMap = <String, int>{};
    if (json['stats'] != null) {
      (json['stats'] as Map<String, dynamic>).forEach((key, value) {
        statsMap[key.toLowerCase()] = (value as num).toInt();
      });
    }
    
    return TaskAnalysis(
      suggestedStats: statsMap,
      suggestedXP: (json['totalXP'] as num?)?.toInt() ?? 10,
      reasoning: json['reasoning'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Fallback analysis when AI is unavailable
  factory TaskAnalysis.fallback(String taskTitle) {
    final title = taskTitle.toLowerCase();
    final stats = <String, int>{};
    int xp = 10;

    // Physical keywords
    if (_containsAny(title, ['workout', 'gym', 'exercise', 'lift', 'weight', 'push-up', 'squat', 'bench', 'deadlift'])) {
      stats['strength'] = 15;
      xp = 20;
    }
    if (_containsAny(title, ['run', 'jog', 'cardio', 'swim', 'bike', 'cycle', 'yoga', 'stretch', 'dance', 'hiit', 'sprint'])) {
      stats['dexterity'] = 15;
      xp = 20;
    }
    if (_containsAny(title, ['eat', 'meal', 'diet', 'sleep', 'rest', 'water', 'vitamin', 'health', 'nutrition', 'fast'])) {
      stats['constitution'] = 10;
      xp = 15;
    }

    // Mental keywords
    if (_containsAny(title, ['study', 'learn', 'read', 'course', 'book', 'research', 'practice', 'language', 'tutorial'])) {
      stats['intelligence'] = 15;
      xp = 20;
    }
    if (_containsAny(title, ['meditate', 'journal', 'reflect', 'mindful', 'gratitude', 'pray', 'therapy'])) {
      stats['wisdom'] = 15;
      xp = 15;
    }
    if (_containsAny(title, ['focus', 'deep work', 'pomodoro', 'concentrate', 'no distraction', 'flow', 'unplug'])) {
      stats['focus'] = 15;
      xp = 15;
    }

    // Social keywords
    if (_containsAny(title, ['present', 'speak', 'lead', 'meeting', 'pitch', 'negotiate', 'interview'])) {
      stats['charisma'] = 15;
      xp = 20;
    }
    if (_containsAny(title, ['call', 'meet', 'friend', 'family', 'network', 'social', 'party', 'hangout', 'date', 'lunch'])) {
      stats['social'] = 15;
      xp = 15;
    }

    // Lifestyle keywords
    if (_containsAny(title, ['habit', 'routine', 'schedule', 'organize', 'clean', 'plan', 'budget', 'work', 'task', 'email'])) {
      stats['discipline'] = 15;
      xp = 15;
    }
    if (_containsAny(title, ['art', 'draw', 'paint', 'music', 'write', 'create', 'design', 'compose', 'craft', 'photo', 'video'])) {
      stats['creativity'] = 15;
      xp = 20;
    }

    // Default if no matches
    if (stats.isEmpty) {
      stats['discipline'] = 10;
    }

    return TaskAnalysis(
      suggestedStats: stats,
      suggestedXP: xp,
      reasoning: 'Auto-detected from task keywords',
      tags: [],
    );
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }

  /// Get the primary stat (one with highest XP)
  String? get primaryStat {
    if (suggestedStats.isEmpty) return null;
    return suggestedStats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Result of AI quest analysis
class QuestAnalysis {
  final Map<String, int> suggestedStats;
  final int suggestedXP;
  final String suggestedDifficulty;
  final List<String> suggestedSubtasks;
  final String? reasoning;

  QuestAnalysis({
    required this.suggestedStats,
    required this.suggestedXP,
    required this.suggestedDifficulty,
    required this.suggestedSubtasks,
    this.reasoning,
  });

  factory QuestAnalysis.fromJson(Map<String, dynamic> json) {
    final statsMap = <String, int>{};
    if (json['stats'] != null) {
      (json['stats'] as Map<String, dynamic>).forEach((key, value) {
        statsMap[key.toLowerCase()] = (value as num).toInt();
      });
    }
    
    return QuestAnalysis(
      suggestedStats: statsMap,
      suggestedXP: (json['totalXP'] as num?)?.toInt() ?? 50,
      suggestedDifficulty: json['difficulty'] as String? ?? 'medium',
      suggestedSubtasks: (json['subtasks'] as List<dynamic>?)?.cast<String>() ?? [],
      reasoning: json['reasoning'] as String?,
    );
  }
}

/// Legacy support
class QuestSuggestion {
  final String title;
  final String description;
  final String difficulty;
  final List<String> subtasks;
  final String primaryStat;
  final int estimatedDays;

  QuestSuggestion({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.subtasks,
    required this.primaryStat,
    required this.estimatedDays,
  });

  factory QuestSuggestion.fromJson(Map<String, dynamic> json) {
    return QuestSuggestion(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      subtasks: List<String>.from(json['subtasks'] ?? []),
      primaryStat: json['primaryStat'] ?? 'discipline',
      estimatedDays: json['estimatedDays'] ?? 7,
    );
  }
}

class AIService {
  GenerativeModel? _model;
  bool _isInitialized = false;
  String? _currentApiKey;

  AIService() {
    _initialize();
  }

  Future<void> _initialize() async {
    // First check SharedPreferences for user-configured key and model
    final prefs = await SharedPreferences.getInstance();
    String? apiKey = prefs.getString('gemini_api_key');
    String modelName = prefs.getString('gemini_model') ?? 'gemini-2.5-flash';

    print('AIService: Checking for API key in SharedPreferences: ${apiKey != null ? "found (${apiKey.length} chars)" : "not found"}');
    print('AIService: Model configured: $modelName');

    // Fall back to dotenv if not found
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = dotenv.env['GEMINI_API_KEY'];
      print('AIService: Using dotenv API key: ${apiKey != null ? "found (${apiKey.length} chars)" : "not found"}');
    }

    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'your_gemini_api_key_here') {
      _currentApiKey = apiKey;
      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 4096,
        ),
      );
      _isInitialized = true;
      print('AIService: Initialized successfully with model $modelName');
    } else {
      print('AIService: No valid API key found');
    }
  }

  /// Re-initialize with a new API key
  Future<void> reinitialize() async {
    _isInitialized = false;
    _model = null;
    await _initialize();
  }

  bool get isAvailable => _isInitialized && _model != null;

  /// Analyze a task and suggest which stats it should affect and XP amount
  Future<TaskAnalysis> analyzeTask(String title, {String? description}) async {
    if (!isAvailable) {
      return TaskAnalysis.fallback(title);
    }

    try {
      final prompt = '''
Analyze this task and determine which character stats it should improve.

Task: "$title"
${description != null ? 'Description: "$description"' : ''}

Available stats (choose 1-3 that best fit):
- strength (STR): Physical power, weightlifting, carrying heavy things
- dexterity (DEX): Agility, cardio, running, flexibility, balance, sports
- constitution (CON): Health, nutrition, sleep, endurance, stamina
- intelligence (INT): Learning, studying, reading, courses, knowledge, languages
- wisdom (WIS): Mindfulness, meditation, perception, insight, self-reflection
- focus (FOC): Concentration, deep work, attention, avoiding distractions
- charisma (CHA): Leadership, public speaking, persuasion, confidence
- social (SOC): Networking, relationships, communication, friendships
- discipline (DIS): Habits, routines, consistency, work ethic, organization
- creativity (CRE): Art, music, writing, design, innovation, crafts

Respond in JSON format only (no markdown):
{
  "stats": {"statName": xpAmount, ...},
  "totalXP": number (5-50 based on difficulty/effort),
  "reasoning": "brief explanation",
  "tags": ["relevant", "tags"]
}

XP Guidelines:
- Quick/easy tasks (5-15 min): 5-10 XP
- Medium effort (15-45 min): 15-25 XP  
- Significant effort (45+ min): 30-50 XP
- Stat XP should be 5-20 per stat based on relevance
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return TaskAnalysis.fromJson(json);
      }
    } catch (e) {
      print('AI task analysis error: $e');
    }

    return TaskAnalysis.fallback(title);
  }

  /// Analyze a quest and suggest stats, difficulty, and subtasks
  Future<QuestAnalysis> analyzeQuest(String title, {String? description}) async {
    if (!isAvailable) {
      return QuestAnalysis(
        suggestedStats: {'discipline': 20},
        suggestedXP: 50,
        suggestedDifficulty: 'medium',
        suggestedSubtasks: [],
      );
    }

    try {
      final prompt = '''
Analyze this quest/goal and suggest how to gamify it.

Quest: "$title"
${description != null ? 'Description: "$description"' : ''}

Available stats:
strength, dexterity, constitution, intelligence, wisdom, focus, charisma, social, discipline, creativity

Respond in JSON format only (no markdown):
{
  "stats": {"statName": xpAmount, ...},
  "totalXP": number (25-500 based on difficulty),
  "difficulty": "easy" | "medium" | "hard" | "epic" | "legendary",
  "subtasks": ["subtask 1", "subtask 2", ...],
  "reasoning": "brief explanation"
}

Difficulty guidelines:
- easy: Simple goals, few steps (25-50 XP)
- medium: Moderate effort, 1-2 weeks (50-100 XP)
- hard: Significant effort, weeks to month (100-200 XP)
- epic: Major achievement, months (200-350 XP)
- legendary: Life-changing, 6+ months (350-500 XP)

Generate 3-7 actionable subtasks to complete the quest.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
        return QuestAnalysis.fromJson(json);
      }
    } catch (e) {
      print('AI quest analysis error: $e');
    }

    return QuestAnalysis(
      suggestedStats: {'discipline': 20},
      suggestedXP: 50,
      suggestedDifficulty: 'medium',
      suggestedSubtasks: [],
    );
  }

  /// Get motivational message based on user's current stats and progress
  Future<String> getMotivationalMessage({
    required UserProfile profile,
    int? tasksCompletedToday,
    int? currentStreak,
  }) async {
    final level = profile.level;
    final streak = currentStreak ?? 0;
    
    if (!isAvailable) {
      final messages = [
        "Keep pushing! Every task completed makes you stronger. 💪",
        "Your consistency is building something great! 🔥",
        "Level $level and climbing! The adventure continues! ⚔️",
        "Streak: $streak days! You're unstoppable! 🏆",
        "Your stats are growing! Keep grinding! 📈",
      ];
      return messages[DateTime.now().second % messages.length];
    }

    try {
      final prompt = '''
Generate a short, encouraging RPG-style message (1-2 sentences) for a player:
- Level: $level
- Current streak: $streak days
- Tasks done today: ${tasksCompletedToday ?? 0}
- Strongest stat: ${_getStrongestStat(profile.stats)}

Make it feel like a game notification. Be encouraging and specific. Use an emoji.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? "Your quest continues! Stay strong, adventurer! ⚔️";
    } catch (e) {
      return "Keep adventuring! 🎮";
    }
  }

  /// Suggest daily tasks based on user's goals and weak stats
  Future<List<String>> suggestDailyTasks({
    required UserProfile profile,
    List<String>? recentTasks,
  }) async {
    final stats = profile.stats;
    
    if (!isAvailable) {
      // Find weakest stats
      final sortedStats = stats.allStats..sort((a, b) => a.value.compareTo(b.value));
      final weakestStat = sortedStats.first.key;

      final suggestions = {
        'strength': ['Do 20 push-ups', 'Lift weights for 30 min'],
        'dexterity': ['Go for a 20 min run', '15 min yoga session'],
        'constitution': ['Drink 8 glasses of water', 'Sleep 8 hours tonight'],
        'intelligence': ['Read for 30 minutes', 'Learn something new'],
        'wisdom': ['10 min meditation', 'Write in journal'],
        'focus': ['1 hour deep work session', 'No phone for 2 hours'],
        'charisma': ['Practice a presentation', 'Speak up in a meeting'],
        'social': ['Message an old friend', 'Have lunch with someone'],
        'discipline': ['Complete morning routine', 'Plan tomorrow'],
        'creativity': ['Sketch for 15 min', 'Write 500 words'],
      };

      return suggestions[weakestStat] ?? ['Complete a task today!'];
    }

    try {
      final statsMap = {for (var e in stats.allStats) e.key: e.value};
      
      final prompt = '''
Suggest 3 specific daily tasks for a user with these stats: $statsMap

${recentTasks != null ? 'Recent tasks they\'ve done: ${recentTasks.join(", ")}' : ''}

Suggest tasks that:
1. Target their weakest stats
2. Are different from recent tasks
3. Are achievable in one day
4. Are specific and actionable

Return just a JSON array of task strings (no markdown):
["task 1", "task 2", "task 3"]
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
      if (jsonMatch != null) {
        final list = jsonDecode(jsonMatch.group(0)!) as List;
        return list.cast<String>();
      }
    } catch (e) {
      print('AI suggestion error: $e');
    }

    return ['Complete a task today!'];
  }

  /// Generate quest suggestions
  Future<List<QuestSuggestion>> generateQuestSuggestions({
    required UserProfile profile,
    required List<String> userGoals,
    int count = 3,
  }) async {
    if (!isAvailable) return [];

    try {
      final statsMap = {for (var e in profile.stats.allStats) e.key: e.value};
      
      final prompt = '''
Generate $count quest suggestions for a user:
- Level: ${profile.level}
- Stats: $statsMap
- Goals: ${userGoals.join(', ')}

Respond in JSON format only (no markdown):
[
  {
    "title": "Quest title",
    "description": "Brief description",
    "difficulty": "easy|medium|hard|epic",
    "subtasks": ["subtask 1", "subtask 2", "subtask 3"],
    "primaryStat": "stat name",
    "estimatedDays": number
  }
]
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
      if (jsonMatch != null) {
        final list = jsonDecode(jsonMatch.group(0)!) as List;
        return list.map((json) => QuestSuggestion.fromJson(json)).toList();
      }
    } catch (e) {
      print('AI quest suggestion error: $e');
    }

    return [];
  }

  /// Get daily tip based on user's weak areas
  Future<String?> getDailyTip(UserProfile profile) async {
    if (!isAvailable) return null;

    try {
      final weakestStat = _getWeakestStat(profile.stats);

      final prompt = '''
Give one brief, actionable tip (1-2 sentences) to improve someone's $weakestStat.
Make it specific and immediately actionable today.
Don't start with "Tip:" or similar.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      return null;
    }
  }

  String _getStrongestStat(UserStats stats) {
    final statsList = stats.allStats..sort((a, b) => b.value.compareTo(a.value));
    return statsList.first.key;
  }

  String _getWeakestStat(UserStats stats) {
    final statsList = stats.allStats..sort((a, b) => a.value.compareTo(b.value));
    return statsList.first.key;
  }

  /// Parse food info from plain text response
  FoodAnalysis? _parseFromText(String text) {
    try {
      final lower = text.toLowerCase();

      // Extract calories - look for patterns like "555 calories", "555 kcal", "calories: 555"
      int? calories;
      final calPatterns = [
        RegExp(r'(\d+)\s*(?:calories|kcal|cal)\b', caseSensitive: false),
        RegExp(r'calories[:\s]+(\d+)', caseSensitive: false),
        RegExp(r'"calories"[:\s]+(\d+)', caseSensitive: false),
      ];
      for (final pattern in calPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          calories = int.tryParse(match.group(1) ?? '');
          if (calories != null) break;
        }
      }

      // Extract protein
      double? protein;
      final proteinPatterns = [
        RegExp(r'(\d+(?:\.\d+)?)\s*g?\s*protein', caseSensitive: false),
        RegExp(r'protein[:\s]+(\d+(?:\.\d+)?)', caseSensitive: false),
        RegExp(r'"protein"[:\s]+(\d+(?:\.\d+)?)', caseSensitive: false),
      ];
      for (final pattern in proteinPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          protein = double.tryParse(match.group(1) ?? '');
          if (protein != null) break;
        }
      }

      // Extract carbs
      double? carbs;
      final carbPatterns = [
        RegExp(r'(\d+(?:\.\d+)?)\s*g?\s*carb', caseSensitive: false),
        RegExp(r'carb(?:s|ohydrates)?[:\s]+(\d+(?:\.\d+)?)', caseSensitive: false),
        RegExp(r'"carbs"[:\s]+(\d+(?:\.\d+)?)', caseSensitive: false),
      ];
      for (final pattern in carbPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          carbs = double.tryParse(match.group(1) ?? '');
          if (carbs != null) break;
        }
      }

      // Extract fat
      double? fat;
      final fatPatterns = [
        RegExp(r'(\d+(?:\.\d+)?)\s*g?\s*fat', caseSensitive: false),
        RegExp(r'fat[:\s]+(\d+(?:\.\d+)?)', caseSensitive: false),
        RegExp(r'"fat"[:\s]+(\d+(?:\.\d+)?)', caseSensitive: false),
      ];
      for (final pattern in fatPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          fat = double.tryParse(match.group(1) ?? '');
          if (fat != null) break;
        }
      }

      // Extract name - look for quoted name or first capitalized phrase
      String name = 'Food';
      final namePatterns = [
        RegExp(r'"name"[:\s]+"([^"]+)"', caseSensitive: false),
        RegExp(r'name[:\s]+"([^"]+)"', caseSensitive: false),
        RegExp(r'^[*\s]*([A-Z][A-Za-z\s]+?)(?:\n|,|\.|:|\()', multiLine: true),
      ];
      for (final pattern in namePatterns) {
        final match = pattern.firstMatch(text);
        if (match != null && match.group(1) != null) {
          name = match.group(1)!.trim();
          if (name.length > 2 && name.length < 50) break;
        }
      }

      // Need at least calories to be valid
      if (calories != null && calories > 0) {
        return FoodAnalysis(
          name: name,
          calories: calories,
          protein: protein ?? 0,
          carbs: carbs ?? 0,
          fat: fat ?? 0,
          servingSize: '1 serving',
          reasoning: 'Parsed from text response',
        );
      }
    } catch (e) {
      print('AIService._parseFromText error: $e');
    }
    return null;
  }

  /// Check if AI is configured and return status message
  String get statusMessage {
    if (_isInitialized && _model != null) {
      return 'AI is ready';
    }
    return 'AI not configured. Please add your Gemini API key in Settings > AI Settings.';
  }

  /// Analyze food from image and optional description
  Future<FoodAnalysisResult> analyzeFood({
    Uint8List? imageBytes,
    String? description,
  }) async {
    print('AIService.analyzeFood: imageBytes=${imageBytes?.length ?? 0}, description=${description ?? "none"}');
    print('AIService.analyzeFood: isAvailable=$isAvailable');

    if (!isAvailable) {
      print('AIService.analyzeFood: AI not available');
      return FoodAnalysisResult(
        analysis: null,
        error: 'AI not configured. Please add your Gemini API key in Settings > AI Settings.',
      );
    }
    if (imageBytes == null && (description == null || description.isEmpty)) {
      return FoodAnalysisResult(
        analysis: null,
        error: 'Please add a photo or description.',
      );
    }
    print('AIService.analyzeFood: Calling Gemini API...');

    try {
      final prompt = '''
You are a nutrition expert who is extensively knowledgeable about all the nutritional reference about food. You also have access to endless resources about finding out the correct nutrition. Analyze this food and provide accurate nutritional estimates.

${description != null && description.isNotEmpty ? 'User description: "$description"' : ''}

INSTRUCTIONS:
1. Identify all foods/ingredients visible in the image or mentioned in the description
2. Estimate the portion size (use common reference sizes: fist = 1 cup, palm = 3oz meat, thumb = 1 tbsp)
3. Calculate total nutritional values for the entire meal/serving shown

NUTRITIONAL REFERENCE (per 100g):
- Rice: 130 kcal, 2.7g protein, 28g carbs, 0.3g fat
- Chicken breast: 165 kcal, 31g protein, 0g carbs, 3.6g fat
- Beef: 250 kcal, 26g protein, 0g carbs, 15g fat
- Bread: 265 kcal, 9g protein, 49g carbs, 3.2g fat
- Egg: 155 kcal, 13g protein, 1.1g carbs, 11g fat
- Vegetables (avg): 25 kcal, 1.5g protein, 5g carbs, 0.3g fat
- Cooking oil: 884 kcal, 0g protein, 0g carbs, 100g fat

Respond in JSON format only (no markdown, no code blocks):
{
  "name": "Specific name of dish (e.g., 'Chicken Fried Rice with Vegetables')",
  "calories": number (total kcal for the portion shown),
  "protein": number (grams, 1 decimal),
  "carbs": number (grams, 1 decimal),
  "fat": number (grams, 1 decimal),
  "servingSize": "estimated portion description",
  "reasoning": "List main ingredients identified and how you calculated (e.g., '~200g rice + ~100g chicken + vegetables + oil')"
}

Be accurate based on visible portion sizes. Account for cooking oils and sauces which add significant calories.
''';

      final content = <Part>[];

      if (imageBytes != null) {
        content.add(DataPart('image/jpeg', imageBytes));
      }
      content.add(TextPart(prompt));

      final response = await _model!.generateContent([Content.multi(content)]);
      final text = response.text ?? '';
      print('AIService.analyzeFood: Response received (${text.length} chars)');
      print('AIService.analyzeFood: Raw response: $text');

      // Try JSON first
      final jsonStr = extractJsonFromResponse(text);
      if (jsonStr != null) {
        print('AIService.analyzeFood: Found JSON in response');
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final analysis = FoodAnalysis.fromJson(json);
          print('AIService.analyzeFood: Parsed food: ${analysis.name}, ${analysis.calories} cal');
          return FoodAnalysisResult(analysis: analysis);
        } catch (parseError) {
          print('AIService.analyzeFood: JSON decode error: $parseError, trying text parse');
        }
      }

      // Fallback: parse from plain text
      print('AIService.analyzeFood: Trying text parsing fallback');
      final textAnalysis = _parseFromText(text);
      if (textAnalysis != null) {
        print('AIService.analyzeFood: Text parse succeeded: ${textAnalysis.name}');
        return FoodAnalysisResult(analysis: textAnalysis);
      }

      print('AIService.analyzeFood: All parsing failed');
      return FoodAnalysisResult(
        analysis: null,
        error: 'Could not parse response. AI said: ${text.length > 300 ? text.substring(0, 300) + "..." : text}',
      );
    } catch (e) {
      print('AIService.analyzeFood ERROR: $e');
      return FoodAnalysisResult(
        analysis: null,
        error: 'AI error: ${e.toString()}',
      );
    }
  }
}

final aiServiceProvider = Provider<AIService>((ref) => AIService());

/// Result of parsing a voice food description
class VoiceFoodResult {
  final List<FoodAnalysis> foods;
  final String? error;

  VoiceFoodResult({required this.foods, this.error});
}

/// Result of parsing a voice command
class VoiceCommandResult {
  final String action; // 'add_food', 'add_task', 'check_stats', 'log_workout', etc.
  final Map<String, dynamic> parameters;
  final String? response; // What to say back to the user

  VoiceCommandResult({
    required this.action,
    this.parameters = const {},
    this.response,
  });
}

extension AIServiceVoice on AIService {
  /// Parse a voice description of food and return nutritional info
  Future<VoiceFoodResult> parseFoodFromVoice(String voiceInput) async {
    print('AIService.parseFoodFromVoice: Input = "$voiceInput"');
    print('AIService.parseFoodFromVoice: isAvailable = $isAvailable');

    if (!isAvailable) {
      print('AIService.parseFoodFromVoice: AI not available, using fallback');
      // Fallback: try to parse simple descriptions
      return _fallbackFoodParse(voiceInput);
    }

    try {
      print('AIService.parseFoodFromVoice: Calling Gemini API...');
      final prompt = '''
Parse this voice description of food and estimate nutritional information.

User said: "$voiceInput"

The user might describe one or multiple food items. Parse each item separately.
Extract food items even from casual phrases like "I had chicken and rice" or "ate some pizza".

Respond in JSON format only (no markdown, no code blocks):
{
  "foods": [
    {
      "name": "food name",
      "calories": number,
      "protein": number (grams),
      "carbs": number (grams),
      "fat": number (grams),
      "servingSize": "description of portion"
    }
  ]
}

Common reference values:
- "a chicken breast" = ~165 cal, 31g protein, 0g carbs, 3.6g fat
- "a cup of rice" = ~200 cal, 4g protein, 45g carbs, 0.4g fat
- "an egg" = ~70 cal, 6g protein, 0.5g carbs, 5g fat
- "a slice of bread" = ~80 cal, 3g protein, 15g carbs, 1g fat
- "a banana" = ~105 cal, 1g protein, 27g carbs, 0.4g fat
- "a glass of milk" = ~150 cal, 8g protein, 12g carbs, 8g fat
- "chicken and rice" = chicken (~165 cal) + rice (~200 cal)
- "burger" = ~450 cal, 25g protein, 40g carbs, 20g fat
- "pizza slice" = ~285 cal, 12g protein, 36g carbs, 10g fat
- "salad" = ~100 cal, 3g protein, 10g carbs, 5g fat
- "sandwich" = ~350 cal, 15g protein, 40g carbs, 12g fat

Parse quantities like "two eggs", "a bowl of", "large portion", etc.
If portion size is unclear, assume a standard serving.
ALWAYS return at least one food item if any food is mentioned.
''';

      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      print('AIService.parseFoodFromVoice: Response received (${text.length} chars)');
      print('AIService.parseFoodFromVoice: Raw response: $text');

      // Try to extract JSON, handling markdown code blocks
      final jsonStr = extractJsonFromResponse(text);
      if (jsonStr != null) {
        print('AIService.parseFoodFromVoice: Found JSON in response');
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        final foodsList = (json['foods'] as List<dynamic>?) ?? [];
        final foods = foodsList.map((f) => FoodAnalysis.fromJson(f)).toList();
        print('AIService.parseFoodFromVoice: Parsed ${foods.length} foods');
        if (foods.isNotEmpty) {
          return VoiceFoodResult(foods: foods);
        }
      } else {
        print('AIService.parseFoodFromVoice: No JSON found in response');
      }
    } catch (e) {
      print('AIService.parseFoodFromVoice ERROR: $e');
    }

    print('AIService.parseFoodFromVoice: Falling back to local parsing');
    // Always fall back to local parsing
    return _fallbackFoodParse(voiceInput);
  }

  VoiceFoodResult _fallbackFoodParse(String input) {
    final lower = input.toLowerCase();
    final foods = <FoodAnalysis>[];

    // Extended keyword matching for common foods
    final foodPatterns = {
      // Proteins
      'chicken': FoodAnalysis(name: 'Chicken', calories: 165, protein: 31, carbs: 0, fat: 4, servingSize: '100g'),
      'beef': FoodAnalysis(name: 'Beef', calories: 250, protein: 26, carbs: 0, fat: 15, servingSize: '100g'),
      'pork': FoodAnalysis(name: 'Pork', calories: 240, protein: 25, carbs: 0, fat: 14, servingSize: '100g'),
      'steak': FoodAnalysis(name: 'Steak', calories: 270, protein: 26, carbs: 0, fat: 18, servingSize: '150g'),
      'fish': FoodAnalysis(name: 'Fish', calories: 150, protein: 25, carbs: 0, fat: 5, servingSize: '100g'),
      'salmon': FoodAnalysis(name: 'Salmon', calories: 200, protein: 22, carbs: 0, fat: 12, servingSize: '100g'),
      'tuna': FoodAnalysis(name: 'Tuna', calories: 130, protein: 28, carbs: 0, fat: 1, servingSize: '100g'),
      'shrimp': FoodAnalysis(name: 'Shrimp', calories: 100, protein: 20, carbs: 1, fat: 1, servingSize: '100g'),
      'egg': FoodAnalysis(name: 'Egg', calories: 70, protein: 6, carbs: 1, fat: 5, servingSize: '1 egg'),
      'tofu': FoodAnalysis(name: 'Tofu', calories: 80, protein: 8, carbs: 2, fat: 4, servingSize: '100g'),

      // Carbs
      'rice': FoodAnalysis(name: 'Rice', calories: 200, protein: 4, carbs: 45, fat: 0, servingSize: '1 cup'),
      'bread': FoodAnalysis(name: 'Bread', calories: 80, protein: 3, carbs: 15, fat: 1, servingSize: '1 slice'),
      'toast': FoodAnalysis(name: 'Toast', calories: 80, protein: 3, carbs: 15, fat: 1, servingSize: '1 slice'),
      'pasta': FoodAnalysis(name: 'Pasta', calories: 300, protein: 10, carbs: 55, fat: 5, servingSize: '1 plate'),
      'noodle': FoodAnalysis(name: 'Noodles', calories: 280, protein: 8, carbs: 50, fat: 3, servingSize: '1 bowl'),
      'potato': FoodAnalysis(name: 'Potato', calories: 160, protein: 4, carbs: 37, fat: 0, servingSize: '1 medium'),
      'oatmeal': FoodAnalysis(name: 'Oatmeal', calories: 150, protein: 5, carbs: 27, fat: 3, servingSize: '1 bowl'),
      'cereal': FoodAnalysis(name: 'Cereal', calories: 150, protein: 3, carbs: 30, fat: 2, servingSize: '1 bowl'),

      // Fruits
      'banana': FoodAnalysis(name: 'Banana', calories: 105, protein: 1, carbs: 27, fat: 0, servingSize: '1 medium'),
      'apple': FoodAnalysis(name: 'Apple', calories: 95, protein: 0, carbs: 25, fat: 0, servingSize: '1 medium'),
      'orange': FoodAnalysis(name: 'Orange', calories: 60, protein: 1, carbs: 15, fat: 0, servingSize: '1 medium'),
      'mango': FoodAnalysis(name: 'Mango', calories: 100, protein: 1, carbs: 25, fat: 0, servingSize: '1 cup'),
      'berry': FoodAnalysis(name: 'Berries', calories: 60, protein: 1, carbs: 14, fat: 0, servingSize: '1 cup'),
      'grape': FoodAnalysis(name: 'Grapes', calories: 100, protein: 1, carbs: 27, fat: 0, servingSize: '1 cup'),
      'watermelon': FoodAnalysis(name: 'Watermelon', calories: 45, protein: 1, carbs: 11, fat: 0, servingSize: '1 cup'),
      'fruit': FoodAnalysis(name: 'Mixed Fruit', calories: 80, protein: 1, carbs: 20, fat: 0, servingSize: '1 cup'),

      // Vegetables
      'salad': FoodAnalysis(name: 'Salad', calories: 100, protein: 3, carbs: 10, fat: 5, servingSize: '1 bowl'),
      'vegetable': FoodAnalysis(name: 'Vegetables', calories: 50, protein: 2, carbs: 10, fat: 0, servingSize: '1 cup'),
      'broccoli': FoodAnalysis(name: 'Broccoli', calories: 55, protein: 4, carbs: 11, fat: 0, servingSize: '1 cup'),
      'spinach': FoodAnalysis(name: 'Spinach', calories: 25, protein: 3, carbs: 4, fat: 0, servingSize: '1 cup'),
      'carrot': FoodAnalysis(name: 'Carrots', calories: 50, protein: 1, carbs: 12, fat: 0, servingSize: '1 cup'),
      'corn': FoodAnalysis(name: 'Corn', calories: 130, protein: 5, carbs: 27, fat: 2, servingSize: '1 cup'),

      // Dairy
      'milk': FoodAnalysis(name: 'Milk', calories: 150, protein: 8, carbs: 12, fat: 8, servingSize: '1 glass'),
      'yogurt': FoodAnalysis(name: 'Yogurt', calories: 100, protein: 10, carbs: 6, fat: 3, servingSize: '1 cup'),
      'cheese': FoodAnalysis(name: 'Cheese', calories: 110, protein: 7, carbs: 1, fat: 9, servingSize: '1 oz'),

      // Fast food / Meals
      'pizza': FoodAnalysis(name: 'Pizza', calories: 285, protein: 12, carbs: 36, fat: 10, servingSize: '1 slice'),
      'burger': FoodAnalysis(name: 'Burger', calories: 450, protein: 25, carbs: 40, fat: 20, servingSize: '1 burger'),
      'hamburger': FoodAnalysis(name: 'Hamburger', calories: 450, protein: 25, carbs: 40, fat: 20, servingSize: '1 burger'),
      'sandwich': FoodAnalysis(name: 'Sandwich', calories: 350, protein: 15, carbs: 40, fat: 12, servingSize: '1 sandwich'),
      'taco': FoodAnalysis(name: 'Taco', calories: 200, protein: 10, carbs: 20, fat: 10, servingSize: '1 taco'),
      'burrito': FoodAnalysis(name: 'Burrito', calories: 450, protein: 18, carbs: 50, fat: 18, servingSize: '1 burrito'),
      'fries': FoodAnalysis(name: 'French Fries', calories: 300, protein: 4, carbs: 40, fat: 15, servingSize: '1 serving'),
      'wings': FoodAnalysis(name: 'Chicken Wings', calories: 300, protein: 25, carbs: 5, fat: 20, servingSize: '6 pieces'),
      'nugget': FoodAnalysis(name: 'Chicken Nuggets', calories: 280, protein: 15, carbs: 18, fat: 17, servingSize: '6 pieces'),
      'hot dog': FoodAnalysis(name: 'Hot Dog', calories: 290, protein: 10, carbs: 24, fat: 18, servingSize: '1 hot dog'),
      'wrap': FoodAnalysis(name: 'Wrap', calories: 350, protein: 15, carbs: 35, fat: 15, servingSize: '1 wrap'),
      'soup': FoodAnalysis(name: 'Soup', calories: 150, protein: 8, carbs: 15, fat: 5, servingSize: '1 bowl'),
      'curry': FoodAnalysis(name: 'Curry', calories: 350, protein: 20, carbs: 30, fat: 15, servingSize: '1 serving'),
      'fried rice': FoodAnalysis(name: 'Fried Rice', calories: 350, protein: 8, carbs: 50, fat: 12, servingSize: '1 plate'),
      'sushi': FoodAnalysis(name: 'Sushi', calories: 250, protein: 12, carbs: 35, fat: 6, servingSize: '6 pieces'),

      // Drinks
      'coffee': FoodAnalysis(name: 'Coffee', calories: 5, protein: 0, carbs: 0, fat: 0, servingSize: '1 cup'),
      'tea': FoodAnalysis(name: 'Tea', calories: 2, protein: 0, carbs: 0, fat: 0, servingSize: '1 cup'),
      'juice': FoodAnalysis(name: 'Juice', calories: 110, protein: 1, carbs: 26, fat: 0, servingSize: '1 glass'),
      'smoothie': FoodAnalysis(name: 'Smoothie', calories: 200, protein: 5, carbs: 40, fat: 3, servingSize: '1 glass'),
      'soda': FoodAnalysis(name: 'Soda', calories: 140, protein: 0, carbs: 39, fat: 0, servingSize: '1 can'),
      'water': FoodAnalysis(name: 'Water', calories: 0, protein: 0, carbs: 0, fat: 0, servingSize: '1 glass'),
      'beer': FoodAnalysis(name: 'Beer', calories: 150, protein: 1, carbs: 13, fat: 0, servingSize: '1 bottle'),
      'wine': FoodAnalysis(name: 'Wine', calories: 125, protein: 0, carbs: 4, fat: 0, servingSize: '1 glass'),

      // Snacks
      'chips': FoodAnalysis(name: 'Chips', calories: 150, protein: 2, carbs: 15, fat: 10, servingSize: '1 oz'),
      'cookie': FoodAnalysis(name: 'Cookie', calories: 80, protein: 1, carbs: 12, fat: 4, servingSize: '1 cookie'),
      'cake': FoodAnalysis(name: 'Cake', calories: 350, protein: 4, carbs: 50, fat: 15, servingSize: '1 slice'),
      'ice cream': FoodAnalysis(name: 'Ice Cream', calories: 200, protein: 4, carbs: 25, fat: 10, servingSize: '1 scoop'),
      'chocolate': FoodAnalysis(name: 'Chocolate', calories: 150, protein: 2, carbs: 15, fat: 9, servingSize: '1 oz'),
      'candy': FoodAnalysis(name: 'Candy', calories: 100, protein: 0, carbs: 25, fat: 0, servingSize: '1 serving'),
      'donut': FoodAnalysis(name: 'Donut', calories: 250, protein: 3, carbs: 30, fat: 12, servingSize: '1 donut'),
      'popcorn': FoodAnalysis(name: 'Popcorn', calories: 100, protein: 3, carbs: 20, fat: 1, servingSize: '2 cups'),
      'nuts': FoodAnalysis(name: 'Nuts', calories: 170, protein: 6, carbs: 6, fat: 15, servingSize: '1 oz'),
      'peanut': FoodAnalysis(name: 'Peanuts', calories: 170, protein: 7, carbs: 5, fat: 14, servingSize: '1 oz'),
      'almond': FoodAnalysis(name: 'Almonds', calories: 165, protein: 6, carbs: 6, fat: 14, servingSize: '1 oz'),

      // Breakfast
      'pancake': FoodAnalysis(name: 'Pancakes', calories: 220, protein: 6, carbs: 30, fat: 8, servingSize: '2 pancakes'),
      'waffle': FoodAnalysis(name: 'Waffle', calories: 220, protein: 5, carbs: 25, fat: 11, servingSize: '1 waffle'),
      'bacon': FoodAnalysis(name: 'Bacon', calories: 90, protein: 6, carbs: 0, fat: 7, servingSize: '2 slices'),
      'sausage': FoodAnalysis(name: 'Sausage', calories: 180, protein: 10, carbs: 2, fat: 15, servingSize: '2 links'),
      'omelet': FoodAnalysis(name: 'Omelet', calories: 200, protein: 14, carbs: 2, fat: 15, servingSize: '1 omelet'),
      'croissant': FoodAnalysis(name: 'Croissant', calories: 230, protein: 5, carbs: 26, fat: 12, servingSize: '1 croissant'),
      'bagel': FoodAnalysis(name: 'Bagel', calories: 280, protein: 10, carbs: 55, fat: 2, servingSize: '1 bagel'),
      'muffin': FoodAnalysis(name: 'Muffin', calories: 350, protein: 5, carbs: 55, fat: 12, servingSize: '1 muffin'),
    };

    for (final entry in foodPatterns.entries) {
      if (lower.contains(entry.key)) {
        foods.add(entry.value);
      }
    }

    if (foods.isEmpty) {
      return VoiceFoodResult(
        foods: [],
        error: 'Could not recognize the food. Please configure your Gemini API key in Settings > AI Settings for better food recognition, or try using common food names like "chicken", "rice", "pizza", etc.',
      );
    }

    return VoiceFoodResult(foods: foods);
  }

  /// Parse a voice command and determine the action
  Future<VoiceCommandResult> parseVoiceCommand(String voiceInput) async {
    final lower = voiceInput.toLowerCase();

    // Quick pattern matching for common commands
    // Food logging - detect phrases like "I had...", "I ate...", "add food..."
    final foodIndicators = ['i had', 'i ate', 'i eat', 'had some', 'ate some', 'eating', 'for breakfast', 'for lunch', 'for dinner', 'for snack'];
    final containsFoodIndicator = foodIndicators.any((indicator) => lower.contains(indicator));
    final containsFoodKeyword = lower.contains('food') || lower.contains('meal') || lower.contains('calories');

    if (containsFoodIndicator || (lower.contains('add') && containsFoodKeyword)) {
      return VoiceCommandResult(
        action: 'add_food',
        parameters: {'description': voiceInput},
        response: 'Let me log that food for you.',
      );
    }

    if (lower.contains('add') && lower.contains('task')) {
      return VoiceCommandResult(
        action: 'add_task',
        parameters: {'description': voiceInput},
        response: 'Creating a new task.',
      );
    }

    if (lower.contains('stats') || lower.contains('level') || lower.contains('progress')) {
      return VoiceCommandResult(
        action: 'check_stats',
        parameters: {},
        response: 'Opening your character stats.',
      );
    }

    if (lower.contains('workout') || lower.contains('exercise') || lower.contains('gym')) {
      return VoiceCommandResult(
        action: 'log_workout',
        parameters: {'description': voiceInput},
        response: 'Let me help you log your workout.',
      );
    }

    if (lower.contains('calorie') || lower.contains('nutrition') || lower.contains('macro')) {
      return VoiceCommandResult(
        action: 'check_nutrition',
        parameters: {},
        response: 'Here is your nutrition summary.',
      );
    }

    if (lower.contains('quest') || lower.contains('goal')) {
      return VoiceCommandResult(
        action: 'check_quests',
        parameters: {},
        response: 'Showing your active quests.',
      );
    }

    // If AI available, use it for more complex parsing
    if (isAvailable) {
      try {
        final prompt = '''
Parse this voice command for a life gamification app.

User said: "$voiceInput"

Available actions:
- add_food: Log food/meals
- add_task: Create a task
- complete_task: Mark task done
- check_stats: View character stats
- log_workout: Record exercise
- check_nutrition: View food/calorie summary
- check_quests: View goals/quests
- unknown: Can't determine

Respond in JSON (no markdown):
{
  "action": "action_name",
  "parameters": {"key": "value"},
  "response": "What to say back to user"
}
''';

        final response = await _model!.generateContent([Content.text(prompt)]);
        final text = response.text ?? '';
        print('AIService.parseVoiceCommand: Raw response: $text');

        final jsonStr = extractJsonFromResponse(text);
        if (jsonStr != null) {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          return VoiceCommandResult(
            action: json['action'] ?? 'unknown',
            parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
            response: json['response'] as String?,
          );
        }
      } catch (e) {
        print('Voice command parse error: $e');
      }
    }

    return VoiceCommandResult(
      action: 'unknown',
      parameters: {'text': voiceInput},
      response: 'I\'m not sure what you want to do. Try saying "add food", "log workout", or "check stats".',
    );
  }
}
