import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'food_entry.dart';

/// An ingredient in a recipe with its nutritional contribution
class RecipeIngredient extends Equatable {
  final String id;
  final String name;
  final double quantity;
  final PortionUnit unit;
  // Nutrition per serving
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final double? sugar;
  final double? sodium;

  const RecipeIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    this.unit = PortionUnit.grams,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber,
    this.sugar,
    this.sodium,
  });

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unit: PortionUnit.fromString(map['unit'] ?? 'grams'),
      calories: map['calories'] ?? 0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      fiber: (map['fiber'] as num?)?.toDouble(),
      sugar: (map['sugar'] as num?)?.toDouble(),
      sodium: (map['sodium'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  RecipeIngredient copyWith({
    String? name,
    double? quantity,
    PortionUnit? unit,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) {
    return RecipeIngredient(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
    );
  }

  @override
  List<Object?> get props => [id, name, quantity, unit, calories, protein, carbs, fat];
}

/// A saved recipe that can be logged to the food diary
class Recipe extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<RecipeIngredient> ingredients;
  final int servings; // Number of servings this recipe makes
  final String? imageUrl;
  final List<String> tags; // e.g., 'high-protein', 'low-carb', 'vegetarian'
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final String? instructions;
  final DateTime createdAt;
  final int timesLogged; // How many times this recipe has been logged
  final bool isFavorite;

  const Recipe({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.ingredients,
    this.servings = 1,
    this.imageUrl,
    this.tags = const [],
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.instructions,
    required this.createdAt,
    this.timesLogged = 0,
    this.isFavorite = false,
  });

  /// Total nutrition for entire recipe
  int get totalCalories => ingredients.fold(0, (sum, i) => sum + i.calories);
  double get totalProtein => ingredients.fold(0.0, (sum, i) => sum + i.protein);
  double get totalCarbs => ingredients.fold(0.0, (sum, i) => sum + i.carbs);
  double get totalFat => ingredients.fold(0.0, (sum, i) => sum + i.fat);
  double get totalFiber => ingredients.fold(0.0, (sum, i) => sum + (i.fiber ?? 0));
  double get totalSugar => ingredients.fold(0.0, (sum, i) => sum + (i.sugar ?? 0));
  double get totalSodium => ingredients.fold(0.0, (sum, i) => sum + (i.sodium ?? 0));

  /// Nutrition per serving
  int get caloriesPerServing => servings > 0 ? (totalCalories / servings).round() : totalCalories;
  double get proteinPerServing => servings > 0 ? totalProtein / servings : totalProtein;
  double get carbsPerServing => servings > 0 ? totalCarbs / servings : totalCarbs;
  double get fatPerServing => servings > 0 ? totalFat / servings : totalFat;

  /// Total time
  int get totalTimeMinutes => (prepTimeMinutes ?? 0) + (cookTimeMinutes ?? 0);

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Recipe(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      ingredients: (data['ingredients'] as List<dynamic>?)
              ?.map((i) => RecipeIngredient.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      servings: data['servings'] ?? 1,
      imageUrl: data['imageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      prepTimeMinutes: data['prepTimeMinutes'],
      cookTimeMinutes: data['cookTimeMinutes'],
      instructions: data['instructions'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      timesLogged: data['timesLogged'] ?? 0,
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'servings': servings,
      'imageUrl': imageUrl,
      'tags': tags,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'instructions': instructions,
      'createdAt': Timestamp.fromDate(createdAt),
      'timesLogged': timesLogged,
      'isFavorite': isFavorite,
    };
  }

  /// Convert recipe to a food entry for logging
  FoodEntry toFoodEntry({
    required DateTime date,
    required MealType mealType,
    int servingsEaten = 1,
  }) {
    final multiplier = servingsEaten / servings;
    return FoodEntry(
      id: '', // Will be assigned when saved
      userId: userId,
      name: name,
      mealType: mealType,
      calories: (totalCalories * multiplier).round(),
      protein: totalProtein * multiplier,
      carbs: totalCarbs * multiplier,
      fat: totalFat * multiplier,
      fiber: totalFiber * multiplier,
      sugar: totalSugar * multiplier,
      sodium: totalSodium * multiplier,
      servingSize: servingsEaten.toDouble(),
      servingUnit: 'serving',
      portionUnit: PortionUnit.serving,
      date: date,
      createdAt: DateTime.now(),
      notes: 'From recipe: $name',
    );
  }

  Recipe copyWith({
    String? name,
    String? description,
    List<RecipeIngredient>? ingredients,
    int? servings,
    String? imageUrl,
    List<String>? tags,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    String? instructions,
    int? timesLogged,
    bool? isFavorite,
  }) {
    return Recipe(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      instructions: instructions ?? this.instructions,
      createdAt: createdAt,
      timesLogged: timesLogged ?? this.timesLogged,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        description,
        ingredients,
        servings,
        imageUrl,
        tags,
        prepTimeMinutes,
        cookTimeMinutes,
        instructions,
        createdAt,
        timesLogged,
        isFavorite,
      ];
}

/// A planned meal for future dates (Meal Planning feature)
class PlannedMeal extends Equatable {
  final String id;
  final String userId;
  final DateTime plannedDate;
  final MealType mealType;
  final String? recipeId; // If from a recipe
  final String? foodName; // If a custom food
  // Nutritional info (copied from recipe or entered manually)
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final int servings;
  final bool isCompleted; // Whether this was actually eaten/logged
  final String? notes;
  final DateTime createdAt;

  const PlannedMeal({
    required this.id,
    required this.userId,
    required this.plannedDate,
    required this.mealType,
    this.recipeId,
    this.foodName,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.servings = 1,
    this.isCompleted = false,
    this.notes,
    required this.createdAt,
  });

  String get displayName => foodName ?? 'Planned Meal';

  factory PlannedMeal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PlannedMeal(
      id: doc.id,
      userId: data['userId'] ?? '',
      plannedDate: (data['plannedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mealType: MealType.fromString(data['mealType'] ?? 'lunch'),
      recipeId: data['recipeId'],
      foodName: data['foodName'],
      calories: data['calories'] ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      servings: data['servings'] ?? 1,
      isCompleted: data['isCompleted'] ?? false,
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'plannedDate': Timestamp.fromDate(plannedDate),
      'mealType': mealType.name,
      'recipeId': recipeId,
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servings': servings,
      'isCompleted': isCompleted,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Convert to food entry when marking as eaten
  FoodEntry toFoodEntry() {
    return FoodEntry(
      id: '',
      userId: userId,
      name: displayName,
      mealType: mealType,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servingSize: servings.toDouble(),
      servingUnit: 'serving',
      portionUnit: PortionUnit.serving,
      date: plannedDate,
      createdAt: DateTime.now(),
      notes: notes,
    );
  }

  PlannedMeal copyWith({
    DateTime? plannedDate,
    MealType? mealType,
    String? recipeId,
    String? foodName,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    int? servings,
    bool? isCompleted,
    String? notes,
  }) {
    return PlannedMeal(
      id: id,
      userId: userId,
      plannedDate: plannedDate ?? this.plannedDate,
      mealType: mealType ?? this.mealType,
      recipeId: recipeId ?? this.recipeId,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      servings: servings ?? this.servings,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        plannedDate,
        mealType,
        recipeId,
        foodName,
        calories,
        protein,
        carbs,
        fat,
        servings,
        isCompleted,
        notes,
        createdAt,
      ];
}
