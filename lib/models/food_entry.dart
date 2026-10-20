import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Meal types supporting up to 10 slots like FatSecret Premium
enum MealType {
  breakfast('Breakfast', 1),
  morningSnack('Morning Snack', 2),
  lunch('Lunch', 3),
  afternoonSnack('Afternoon Snack', 4),
  dinner('Dinner', 5),
  eveningSnack('Evening Snack', 6),
  snack('Snack', 7),  // Legacy/general snack
  preWorkout('Pre-Workout', 8),
  postWorkout('Post-Workout', 9),
  supper('Supper', 10);

  final String displayName;
  final int sortOrder;

  const MealType(this.displayName, this.sortOrder);

  /// Get standard 4 meal types (for basic view)
  static List<MealType> get standard => [breakfast, lunch, dinner, snack];

  /// Get all 10 meal types (for premium/detailed view)
  static List<MealType> get all => MealType.values..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Parse from string (supports both enum name and display name)
  static MealType fromString(String value) {
    return MealType.values.firstWhere(
      (e) => e.name == value || e.displayName.toLowerCase() == value.toLowerCase(),
      orElse: () => MealType.snack,
    );
  }
}

/// Portion unit types for flexible food logging
enum PortionUnit {
  // Weight
  grams('g', 'Grams'),
  kilograms('kg', 'Kilograms'),
  ounces('oz', 'Ounces'),
  pounds('lb', 'Pounds'),
  // Volume
  milliliters('ml', 'Milliliters'),
  liters('L', 'Liters'),
  cups('cup', 'Cups'),
  tablespoons('tbsp', 'Tablespoons'),
  teaspoons('tsp', 'Teaspoons'),
  fluidOunces('fl oz', 'Fluid Ounces'),
  // Size descriptors
  small('sm', 'Small'),
  medium('med', 'Medium'),
  large('lg', 'Large'),
  extraLarge('xl', 'Extra Large'),
  // Count
  piece('pc', 'Piece'),
  slice('slice', 'Slice'),
  serving('serving', 'Serving'),
  whole('whole', 'Whole'),
  container('container', 'Container'),
  package('pkg', 'Package'),
  scoop('scoop', 'Scoop'),
  bowl('bowl', 'Bowl'),
  plate('plate', 'Plate');

  final String abbreviation;
  final String displayName;
  const PortionUnit(this.abbreviation, this.displayName);

  static PortionUnit fromString(String value) {
    return PortionUnit.values.firstWhere(
      (e) => e.name == value || e.abbreviation == value || e.displayName == value,
      orElse: () => PortionUnit.serving,
    );
  }
}

class FoodEntry extends Equatable {
  final String id;
  final String userId;
  final String name;
  final MealType mealType;
  final int calories;
  final double protein;  // grams
  final double carbs;    // grams
  final double fat;      // grams
  final double? fiber;   // grams
  final double? sugar;   // grams
  // Extended nutritional info (13 nutrients like FatSecret)
  final double? saturatedFat;      // grams
  final double? polyunsaturatedFat; // grams
  final double? monounsaturatedFat; // grams
  final double? transFat;          // grams
  final double? cholesterol;       // mg
  final double? sodium;            // mg
  final double? potassium;         // mg
  final double servingSize;        // 0-9999 with up to 5 decimal places
  final String servingUnit;
  final PortionUnit portionUnit;
  final DateTime date;
  final DateTime createdAt;
  final String? notes;
  final String? imageUrl;

  const FoodEntry({
    required this.id,
    required this.userId,
    required this.name,
    required this.mealType,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber,
    this.sugar,
    this.saturatedFat,
    this.polyunsaturatedFat,
    this.monounsaturatedFat,
    this.transFat,
    this.cholesterol,
    this.sodium,
    this.potassium,
    this.servingSize = 1,
    this.servingUnit = 'serving',
    this.portionUnit = PortionUnit.serving,
    required this.date,
    required this.createdAt,
    this.notes,
    this.imageUrl,
  });

  factory FoodEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FoodEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      mealType: MealType.values.firstWhere(
        (e) => e.name == data['mealType'],
        orElse: () => MealType.snack,
      ),
      calories: data['calories'] ?? 0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0,
      carbs: (data['carbs'] as num?)?.toDouble() ?? 0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0,
      fiber: (data['fiber'] as num?)?.toDouble(),
      sugar: (data['sugar'] as num?)?.toDouble(),
      saturatedFat: (data['saturatedFat'] as num?)?.toDouble(),
      polyunsaturatedFat: (data['polyunsaturatedFat'] as num?)?.toDouble(),
      monounsaturatedFat: (data['monounsaturatedFat'] as num?)?.toDouble(),
      transFat: (data['transFat'] as num?)?.toDouble(),
      cholesterol: (data['cholesterol'] as num?)?.toDouble(),
      sodium: (data['sodium'] as num?)?.toDouble(),
      potassium: (data['potassium'] as num?)?.toDouble(),
      servingSize: (data['servingSize'] as num?)?.toDouble() ?? 1,
      servingUnit: data['servingUnit'] ?? 'serving',
      portionUnit: PortionUnit.fromString(data['portionUnit'] ?? 'serving'),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'mealType': mealType.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'saturatedFat': saturatedFat,
      'polyunsaturatedFat': polyunsaturatedFat,
      'monounsaturatedFat': monounsaturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'sodium': sodium,
      'potassium': potassium,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'portionUnit': portionUnit.name,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'imageUrl': imageUrl,
    };
  }

  FoodEntry copyWith({
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
    String? imageUrl,
  }) {
    return FoodEntry(
      id: id,
      userId: userId,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      polyunsaturatedFat: polyunsaturatedFat ?? this.polyunsaturatedFat,
      monounsaturatedFat: monounsaturatedFat ?? this.monounsaturatedFat,
      transFat: transFat ?? this.transFat,
      cholesterol: cholesterol ?? this.cholesterol,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      portionUnit: portionUnit ?? this.portionUnit,
      date: date ?? this.date,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, name, mealType, calories, protein, carbs, fat,
        fiber, sugar, saturatedFat, polyunsaturatedFat, monounsaturatedFat,
        transFat, cholesterol, sodium, potassium, servingSize, servingUnit,
        portionUnit, date, createdAt, notes, imageUrl,
      ];

  /// Get formatted serving size string (up to 5 decimal places, trimmed)
  String get formattedServingSize {
    if (servingSize == servingSize.roundToDouble()) {
      return servingSize.toInt().toString();
    }
    // Format with up to 5 decimal places, trim trailing zeros
    String formatted = servingSize.toStringAsFixed(5);
    formatted = formatted.replaceAll(RegExp(r'0+$'), '');
    formatted = formatted.replaceAll(RegExp(r'\.$'), '');
    return formatted;
  }

  /// Total calories as per serving (for display)
  int get totalCaloriesForServing => calories;

  /// Has any extended nutritional info
  bool get hasExtendedNutrition =>
      saturatedFat != null ||
      polyunsaturatedFat != null ||
      monounsaturatedFat != null ||
      transFat != null ||
      cholesterol != null ||
      sodium != null ||
      potassium != null;
}

class DailyNutrition {
  final DateTime date;
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final int calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  DailyNutrition({
    required this.date,
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.calorieGoal = 2000,
    this.proteinGoal = 50,
    this.carbsGoal = 250,
    this.fatGoal = 65,
  });

  double get calorieProgress => totalCalories / calorieGoal;
  double get proteinProgress => totalProtein / proteinGoal;
  double get carbsProgress => totalCarbs / carbsGoal;
  double get fatProgress => totalFat / fatGoal;

  int get remainingCalories => calorieGoal - totalCalories;

  factory DailyNutrition.fromEntries(List<FoodEntry> entries, {
    int calorieGoal = 2000,
    double proteinGoal = 50,
    double carbsGoal = 250,
    double fatGoal = 65,
  }) {
    if (entries.isEmpty) {
      return DailyNutrition(
        date: DateTime.now(),
        calorieGoal: calorieGoal,
        proteinGoal: proteinGoal,
        carbsGoal: carbsGoal,
        fatGoal: fatGoal,
      );
    }

    return DailyNutrition(
      date: entries.first.date,
      totalCalories: entries.fold(0, (sum, e) => sum + e.calories),
      totalProtein: entries.fold(0.0, (sum, e) => sum + e.protein),
      totalCarbs: entries.fold(0.0, (sum, e) => sum + e.carbs),
      totalFat: entries.fold(0.0, (sum, e) => sum + e.fat),
      calorieGoal: calorieGoal,
      proteinGoal: proteinGoal,
      carbsGoal: carbsGoal,
      fatGoal: fatGoal,
    );
  }
}

// Common food database for quick add
class CommonFoods {
  static const List<Map<String, dynamic>> items = [
    // Breakfast
    {'name': 'Eggs (2 large)', 'calories': 143, 'protein': 12.6, 'carbs': 0.7, 'fat': 9.5, 'meal': 'breakfast'},
    {'name': 'Oatmeal (1 cup)', 'calories': 154, 'protein': 5.0, 'carbs': 27.0, 'fat': 2.6, 'meal': 'breakfast'},
    {'name': 'Banana', 'calories': 105, 'protein': 1.3, 'carbs': 27.0, 'fat': 0.4, 'meal': 'breakfast'},
    {'name': 'Greek Yogurt (1 cup)', 'calories': 100, 'protein': 17.0, 'carbs': 6.0, 'fat': 0.7, 'meal': 'breakfast'},
    {'name': 'Toast (2 slices)', 'calories': 158, 'protein': 5.0, 'carbs': 30.0, 'fat': 2.0, 'meal': 'breakfast'},
    {'name': 'Coffee with milk', 'calories': 20, 'protein': 0.6, 'carbs': 1.6, 'fat': 1.0, 'meal': 'breakfast'},
    
    // Lunch
    {'name': 'Chicken Breast (6 oz)', 'calories': 280, 'protein': 52.0, 'carbs': 0.0, 'fat': 6.0, 'meal': 'lunch'},
    {'name': 'Brown Rice (1 cup)', 'calories': 216, 'protein': 5.0, 'carbs': 45.0, 'fat': 1.8, 'meal': 'lunch'},
    {'name': 'Salad (mixed greens)', 'calories': 20, 'protein': 1.5, 'carbs': 3.5, 'fat': 0.2, 'meal': 'lunch'},
    {'name': 'Sandwich (turkey)', 'calories': 350, 'protein': 24.0, 'carbs': 35.0, 'fat': 12.0, 'meal': 'lunch'},
    {'name': 'Soup (vegetable)', 'calories': 120, 'protein': 4.0, 'carbs': 18.0, 'fat': 3.0, 'meal': 'lunch'},
    
    // Dinner
    {'name': 'Salmon (6 oz)', 'calories': 350, 'protein': 38.0, 'carbs': 0.0, 'fat': 20.0, 'meal': 'dinner'},
    {'name': 'Steak (6 oz)', 'calories': 420, 'protein': 42.0, 'carbs': 0.0, 'fat': 26.0, 'meal': 'dinner'},
    {'name': 'Pasta (2 cups)', 'calories': 440, 'protein': 16.0, 'carbs': 86.0, 'fat': 2.6, 'meal': 'dinner'},
    {'name': 'Pizza (2 slices)', 'calories': 500, 'protein': 20.0, 'carbs': 60.0, 'fat': 20.0, 'meal': 'dinner'},
    {'name': 'Broccoli (1 cup)', 'calories': 55, 'protein': 3.7, 'carbs': 11.0, 'fat': 0.6, 'meal': 'dinner'},
    
    // Snacks
    {'name': 'Apple', 'calories': 95, 'protein': 0.5, 'carbs': 25.0, 'fat': 0.3, 'meal': 'snack'},
    {'name': 'Almonds (1 oz)', 'calories': 164, 'protein': 6.0, 'carbs': 6.0, 'fat': 14.0, 'meal': 'snack'},
    {'name': 'Protein Bar', 'calories': 200, 'protein': 20.0, 'carbs': 22.0, 'fat': 7.0, 'meal': 'snack'},
    {'name': 'Orange', 'calories': 62, 'protein': 1.2, 'carbs': 15.0, 'fat': 0.2, 'meal': 'snack'},
    {'name': 'Dark Chocolate (1 oz)', 'calories': 155, 'protein': 1.4, 'carbs': 17.0, 'fat': 9.0, 'meal': 'snack'},
  ];

  static List<Map<String, dynamic>> getByMeal(MealType mealType) {
    return items.where((item) => item['meal'] == mealType.name).toList();
  }
}
