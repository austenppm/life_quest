import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/food_entry.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'user_provider.dart';

// Food entries stream provider
final foodEntriesProvider = StreamProvider<List<FoodEntry>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.watchFoodEntries(user.uid);
});

// Selected date for food view
final selectedFoodDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Today's food entries
final todayFoodEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final entries = ref.watch(foodEntriesProvider).valueOrNull ?? [];
  final selectedDate = ref.watch(selectedFoodDateProvider);
  return entries.where((e) =>
    e.date.year == selectedDate.year &&
    e.date.month == selectedDate.month &&
    e.date.day == selectedDate.day
  ).toList();
});

// Food by meal type
final breakfastEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final entries = ref.watch(todayFoodEntriesProvider);
  return entries.where((e) => e.mealType == MealType.breakfast).toList();
});

final lunchEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final entries = ref.watch(todayFoodEntriesProvider);
  return entries.where((e) => e.mealType == MealType.lunch).toList();
});

final dinnerEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final entries = ref.watch(todayFoodEntriesProvider);
  return entries.where((e) => e.mealType == MealType.dinner).toList();
});

final snackEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final entries = ref.watch(todayFoodEntriesProvider);
  return entries.where((e) => e.mealType == MealType.snack).toList();
});

// Daily nutrition summary
final dailyNutritionProvider = Provider<DailyNutrition>((ref) {
  final entries = ref.watch(todayFoodEntriesProvider);
  final goals = ref.watch(nutritionGoalsProvider);
  return DailyNutrition.fromEntries(
    entries,
    calorieGoal: goals.calorieGoal,
    proteinGoal: goals.proteinGoal,
    carbsGoal: goals.carbsGoal,
    fatGoal: goals.fatGoal,
  );
});

// Nutrition goals notifier with persistence
class NutritionGoalsNotifier extends StateNotifier<NutritionGoals> {
  NutritionGoalsNotifier() : super(const NutritionGoals()) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = NutritionGoals(
      calorieGoal: prefs.getInt('calorieGoal') ?? 2000,
      proteinPercent: prefs.getDouble('proteinPercent') ?? 30.0,
      carbsPercent: prefs.getDouble('carbsPercent') ?? 40.0,
      fatPercent: prefs.getDouble('fatPercent') ?? 30.0,
    );
  }

  Future<void> setCalorieGoal(int goal) async {
    state = state.copyWith(calorieGoal: goal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calorieGoal', goal);
  }

  Future<void> setMacroPercentages({
    required double proteinPercent,
    required double carbsPercent,
    required double fatPercent,
  }) async {
    state = state.copyWith(
      proteinPercent: proteinPercent,
      carbsPercent: carbsPercent,
      fatPercent: fatPercent,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('proteinPercent', proteinPercent);
    await prefs.setDouble('carbsPercent', carbsPercent);
    await prefs.setDouble('fatPercent', fatPercent);
  }

  // Legacy methods for backward compatibility
  Future<void> setProteinGoal(double goal) async {
    // Convert grams to percentage based on current calories
    // Protein has 4 cal/g
    final percent = (goal * 4 / state.calorieGoal * 100).clamp(0.0, 100.0);
    await setMacroPercentages(
      proteinPercent: percent,
      carbsPercent: state.carbsPercent,
      fatPercent: state.fatPercent,
    );
  }

  Future<void> setCarbsGoal(double goal) async {
    // Carbs have 4 cal/g
    final percent = (goal * 4 / state.calorieGoal * 100).clamp(0.0, 100.0);
    await setMacroPercentages(
      proteinPercent: state.proteinPercent,
      carbsPercent: percent,
      fatPercent: state.fatPercent,
    );
  }

  Future<void> setFatGoal(double goal) async {
    // Fat has 9 cal/g
    final percent = (goal * 9 / state.calorieGoal * 100).clamp(0.0, 100.0);
    await setMacroPercentages(
      proteinPercent: state.proteinPercent,
      carbsPercent: state.carbsPercent,
      fatPercent: percent,
    );
  }
}

class NutritionGoals {
  final int calorieGoal;
  final double proteinPercent; // % of calories from protein
  final double carbsPercent;   // % of calories from carbs
  final double fatPercent;     // % of calories from fat

  const NutritionGoals({
    this.calorieGoal = 2000,
    this.proteinPercent = 30.0,  // 30% protein
    this.carbsPercent = 40.0,    // 40% carbs
    this.fatPercent = 30.0,      // 30% fat
  });

  // Calculate grams from percentages
  // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
  double get proteinGoal => (calorieGoal * proteinPercent / 100) / 4;
  double get carbsGoal => (calorieGoal * carbsPercent / 100) / 4;
  double get fatGoal => (calorieGoal * fatPercent / 100) / 9;

  // Calories from each macro
  int get proteinCalories => (proteinGoal * 4).round();
  int get carbsCalories => (carbsGoal * 4).round();
  int get fatCalories => (fatGoal * 9).round();

  NutritionGoals copyWith({
    int? calorieGoal,
    double? proteinPercent,
    double? carbsPercent,
    double? fatPercent,
  }) {
    return NutritionGoals(
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinPercent: proteinPercent ?? this.proteinPercent,
      carbsPercent: carbsPercent ?? this.carbsPercent,
      fatPercent: fatPercent ?? this.fatPercent,
    );
  }
}

final nutritionGoalsProvider = StateNotifierProvider<NutritionGoalsNotifier, NutritionGoals>((ref) {
  return NutritionGoalsNotifier();
});

// Legacy providers for backward compatibility
final calorieGoalProvider = Provider<int>((ref) => ref.watch(nutritionGoalsProvider).calorieGoal);
final proteinGoalProvider = Provider<double>((ref) => ref.watch(nutritionGoalsProvider).proteinGoal);
final carbsGoalProvider = Provider<double>((ref) => ref.watch(nutritionGoalsProvider).carbsGoal);
final fatGoalProvider = Provider<double>((ref) => ref.watch(nutritionGoalsProvider).fatGoal);

// Weekly calorie summary
final weeklyCaloriesProvider = Provider<List<int>>((ref) {
  final entries = ref.watch(foodEntriesProvider).valueOrNull ?? [];
  final now = DateTime.now();

  // Get calories for last 7 days
  return List.generate(7, (i) {
    final date = now.subtract(Duration(days: 6 - i));
    final dayEntries = entries.where((e) =>
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day
    ).toList();
    return dayEntries.fold(0, (sum, e) => sum + e.calories);
  });
});

// Recent unique foods (for quick add)
final recentFoodsProvider = Provider<List<FoodEntry>>((ref) {
  final entries = ref.watch(foodEntriesProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];

  // Get unique foods by name, sorted by most recent
  final sortedEntries = List<FoodEntry>.from(entries)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final seenNames = <String>{};
  final uniqueFoods = <FoodEntry>[];

  for (final entry in sortedEntries) {
    final normalizedName = entry.name.toLowerCase().trim();
    if (!seenNames.contains(normalizedName)) {
      seenNames.add(normalizedName);
      uniqueFoods.add(entry);
      if (uniqueFoods.length >= 50) break; // Limit to 50 recent foods
    }
  }

  return uniqueFoods;
});

// Frequently eaten foods (by count)
final frequentFoodsProvider = Provider<List<MapEntry<String, List<FoodEntry>>>>((ref) {
  final entries = ref.watch(foodEntriesProvider).valueOrNull ?? [];
  if (entries.isEmpty) return [];

  // Group by name and count occurrences
  final foodCounts = <String, List<FoodEntry>>{};
  for (final entry in entries) {
    final normalizedName = entry.name.toLowerCase().trim();
    foodCounts.putIfAbsent(normalizedName, () => []);
    foodCounts[normalizedName]!.add(entry);
  }

  // Sort by frequency
  final sorted = foodCounts.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  return sorted.take(20).toList(); // Top 20 frequent foods
});

// Favorite foods provider (stored in SharedPreferences)
final favoriteFoodNamesProvider = StateProvider<Set<String>>((ref) => {});

class FavoriteFoodsNotifier extends StateNotifier<Set<String>> {
  FavoriteFoodsNotifier() : super({}) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favoriteFoods') ?? [];
    state = Set.from(favorites);
  }

  Future<void> toggleFavorite(String foodName) async {
    final normalizedName = foodName.toLowerCase().trim();
    final newState = Set<String>.from(state);
    if (newState.contains(normalizedName)) {
      newState.remove(normalizedName);
    } else {
      newState.add(normalizedName);
    }
    state = newState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favoriteFoods', newState.toList());
  }

  bool isFavorite(String foodName) {
    return state.contains(foodName.toLowerCase().trim());
  }
}

final favoriteFoodsNotifierProvider =
    StateNotifierProvider<FavoriteFoodsNotifier, Set<String>>((ref) {
  return FavoriteFoodsNotifier();
});

// Get favorite food entries
final favoriteFoodEntriesProvider = Provider<List<FoodEntry>>((ref) {
  final recentFoods = ref.watch(recentFoodsProvider);
  final favorites = ref.watch(favoriteFoodsNotifierProvider);

  return recentFoods.where((entry) =>
    favorites.contains(entry.name.toLowerCase().trim())
  ).toList();
});

// Food notifier for CRUD operations
class FoodNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final String? _userId;

  FoodNotifier(this._firestoreService, this._userId)
      : super(const AsyncValue.data(null));

  Future<void> addFoodEntry({
    required String name,
    required MealType mealType,
    required int calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    double? fiber,
    double? sugar,
    double servingSize = 1,
    String servingUnit = 'serving',
    DateTime? date,
    String? notes,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final entryDate = date ?? DateTime.now();
      final entry = FoodEntry(
        id: const Uuid().v4(),
        userId: _userId,
        name: name,
        mealType: mealType,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        servingSize: servingSize,
        servingUnit: servingUnit,
        date: entryDate,
        createdAt: DateTime.now(),
        notes: notes,
      );

      await _firestoreService.createFoodEntry(_userId, entry);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateFoodEntry(
    String entryId, {
    String? name,
    MealType? mealType,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? saturatedFat,
    double? polyunsaturatedFat,
    double? monounsaturatedFat,
    double? transFat,
    double? cholesterol,
    double? sodium,
    double? potassium,
    double? servingSize,
    String? servingUnit,
    PortionUnit? portionUnit,
    DateTime? date,
    String? notes,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (mealType != null) updates['mealType'] = mealType.name;
      if (calories != null) updates['calories'] = calories;
      if (protein != null) updates['protein'] = protein;
      if (carbs != null) updates['carbs'] = carbs;
      if (fat != null) updates['fat'] = fat;
      if (fiber != null) updates['fiber'] = fiber;
      if (sugar != null) updates['sugar'] = sugar;
      if (saturatedFat != null) updates['saturatedFat'] = saturatedFat;
      if (polyunsaturatedFat != null) updates['polyunsaturatedFat'] = polyunsaturatedFat;
      if (monounsaturatedFat != null) updates['monounsaturatedFat'] = monounsaturatedFat;
      if (transFat != null) updates['transFat'] = transFat;
      if (cholesterol != null) updates['cholesterol'] = cholesterol;
      if (sodium != null) updates['sodium'] = sodium;
      if (potassium != null) updates['potassium'] = potassium;
      if (servingSize != null) updates['servingSize'] = servingSize;
      if (servingUnit != null) updates['servingUnit'] = servingUnit;
      if (portionUnit != null) updates['portionUnit'] = portionUnit.name;
      if (date != null) updates['date'] = Timestamp.fromDate(date);
      if (notes != null) updates['notes'] = notes;

      await _firestoreService.updateFoodEntry(_userId, entryId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Move a food entry to a different date and/or meal type
  Future<void> moveFoodEntry(
    String entryId, {
    DateTime? newDate,
    MealType? newMealType,
  }) async {
    if (_userId == null) return;
    if (newDate == null && newMealType == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};
      if (newDate != null) updates['date'] = Timestamp.fromDate(newDate);
      if (newMealType != null) updates['mealType'] = newMealType.name;

      await _firestoreService.updateFoodEntry(_userId, entryId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Copy a food entry to a different date and/or meal type
  Future<void> copyFoodEntry(
    FoodEntry original, {
    required DateTime targetDate,
    required MealType targetMealType,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final copy = FoodEntry(
        id: const Uuid().v4(),
        userId: _userId,
        name: original.name,
        mealType: targetMealType,
        calories: original.calories,
        protein: original.protein,
        carbs: original.carbs,
        fat: original.fat,
        fiber: original.fiber,
        sugar: original.sugar,
        saturatedFat: original.saturatedFat,
        polyunsaturatedFat: original.polyunsaturatedFat,
        monounsaturatedFat: original.monounsaturatedFat,
        transFat: original.transFat,
        cholesterol: original.cholesterol,
        sodium: original.sodium,
        potassium: original.potassium,
        servingSize: original.servingSize,
        servingUnit: original.servingUnit,
        portionUnit: original.portionUnit,
        date: targetDate,
        createdAt: DateTime.now(),
        notes: original.notes,
        imageUrl: original.imageUrl,
      );

      await _firestoreService.createFoodEntry(_userId, copy);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteFoodEntry(String entryId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _firestoreService.deleteFoodEntry(_userId, entryId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> quickAddFood(Map<String, dynamic> foodData, MealType mealType, DateTime date) async {
    await addFoodEntry(
      name: foodData['name'],
      mealType: mealType,
      calories: foodData['calories'],
      protein: (foodData['protein'] as num).toDouble(),
      carbs: (foodData['carbs'] as num).toDouble(),
      fat: (foodData['fat'] as num).toDouble(),
      date: date,
    );
  }
}

final foodNotifierProvider =
    StateNotifierProvider<FoodNotifier, AsyncValue<void>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(currentUserProvider);
  return FoodNotifier(firestoreService, user?.uid);
});
