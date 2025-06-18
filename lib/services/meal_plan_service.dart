import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';

class MealPlan {
  final DateTime date;
  final List<Recipe> breakfast;
  final List<Recipe> lunch;
  final List<Recipe> dinner;
  final List<Recipe> snacks;

  MealPlan({
    required this.date,
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
    this.snacks = const [],
  });

  MealPlan copyWith({
    DateTime? date,
    List<Recipe>? breakfast,
    List<Recipe>? lunch,
    List<Recipe>? dinner,
    List<Recipe>? snacks,
  }) {
    return MealPlan(
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snacks: snacks ?? this.snacks,
    );
  }

  List<Recipe> get allMeals => [...breakfast, ...lunch, ...dinner, ...snacks];

  bool get hasMeals => allMeals.isNotEmpty;

  String get mealSummary {
    List<String> mealTypes = [];
    if (breakfast.isNotEmpty) mealTypes.add('${breakfast.length} breakfast');
    if (lunch.isNotEmpty) mealTypes.add('${lunch.length} lunch');
    if (dinner.isNotEmpty) mealTypes.add('${dinner.length} dinner');
    if (snacks.isNotEmpty) mealTypes.add('${snacks.length} snacks');
    
    if (mealTypes.isEmpty) return 'No meals planned';
    return mealTypes.join(', ');
  }
}

class GroceryItem {
  final String name;
  final String category;
  int quantity;
  bool isChecked;

  GroceryItem({
    required this.name,
    required this.category,
    this.quantity = 1,
    this.isChecked = false,
  });

  GroceryItem copyWith({
    String? name,
    String? category,
    int? quantity,
    bool? isChecked,
  }) {
    return GroceryItem(
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }
}

class MealPlanService extends ChangeNotifier {
  static final MealPlanService _instance = MealPlanService._internal();
  factory MealPlanService() => _instance;
  MealPlanService._internal();

  // Current state
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDate;
  Map<String, MealPlan> _mealPlans = {};
  List<GroceryItem> _groceryList = [];

  // Getters
  DateTime get currentMonth => _currentMonth;
  DateTime? get selectedDate => _selectedDate;
  Map<String, MealPlan> get mealPlans => _mealPlans;
  List<GroceryItem> get groceryList => _groceryList;

  // Date utilities
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseKey(String key) {
    List<String> parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // Calendar navigation
  void goToPreviousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    notifyListeners();
  }

  void goToNextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    notifyListeners();
  }

  void goToToday() {
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  // Date selection
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  // Meal plan management
  MealPlan? getMealPlan(DateTime date) {
    return _mealPlans[_dateKey(date)];
  }

  void addMealToDate({
    required DateTime date,
    required Recipe recipe,
    required String mealType, // 'breakfast', 'lunch', 'dinner', 'snacks'
  }) {
    String key = _dateKey(date);
    MealPlan existingPlan = _mealPlans[key] ?? MealPlan(date: date);

    List<Recipe> updatedMeals;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        updatedMeals = [...existingPlan.breakfast, recipe];
        _mealPlans[key] = existingPlan.copyWith(breakfast: updatedMeals);
        break;
      case 'lunch':
        updatedMeals = [...existingPlan.lunch, recipe];
        _mealPlans[key] = existingPlan.copyWith(lunch: updatedMeals);
        break;
      case 'dinner':
        updatedMeals = [...existingPlan.dinner, recipe];
        _mealPlans[key] = existingPlan.copyWith(dinner: updatedMeals);
        break;
      case 'snacks':
        updatedMeals = [...existingPlan.snacks, recipe];
        _mealPlans[key] = existingPlan.copyWith(snacks: updatedMeals);
        break;
    }

    _generateGroceryList();
    notifyListeners();
  }

  void removeMealFromDate({
    required DateTime date,
    required Recipe recipe,
    required String mealType,
  }) {
    String key = _dateKey(date);
    MealPlan? existingPlan = _mealPlans[key];
    if (existingPlan == null) return;

    List<Recipe> updatedMeals;
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        updatedMeals = existingPlan.breakfast.where((r) => r.id != recipe.id).toList();
        _mealPlans[key] = existingPlan.copyWith(breakfast: updatedMeals);
        break;
      case 'lunch':
        updatedMeals = existingPlan.lunch.where((r) => r.id != recipe.id).toList();
        _mealPlans[key] = existingPlan.copyWith(lunch: updatedMeals);
        break;
      case 'dinner':
        updatedMeals = existingPlan.dinner.where((r) => r.id != recipe.id).toList();
        _mealPlans[key] = existingPlan.copyWith(dinner: updatedMeals);
        break;
      case 'snacks':
        updatedMeals = existingPlan.snacks.where((r) => r.id != recipe.id).toList();
        _mealPlans[key] = existingPlan.copyWith(snacks: updatedMeals);
        break;
    }

    // Remove meal plan if no meals left
    if (!_mealPlans[key]!.hasMeals) {
      _mealPlans.remove(key);
    }

    _generateGroceryList();
    notifyListeners();
  }

  void clearMealPlan(DateTime date) {
    _mealPlans.remove(_dateKey(date));
    _generateGroceryList();
    notifyListeners();
  }

  // Week management
  List<DateTime> getCurrentWeekDates() {
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  List<MealPlan> getCurrentWeekMealPlans() {
    List<DateTime> weekDates = getCurrentWeekDates();
    return weekDates.map((date) => getMealPlan(date) ?? MealPlan(date: date)).toList();
  }

  // Grocery list management
  void _generateGroceryList() {
    Map<String, GroceryItem> ingredientMap = {};

    // Get all recipes from current week
    List<DateTime> weekDates = getCurrentWeekDates();
    
    for (DateTime date in weekDates) {
      MealPlan? mealPlan = getMealPlan(date);
      if (mealPlan != null) {
        for (Recipe recipe in mealPlan.allMeals) {
          for (String ingredient in recipe.ingredients) {
            String cleanIngredient = ingredient.toLowerCase().trim();
            String category = _categorizeIngredient(cleanIngredient);
            
            if (ingredientMap.containsKey(cleanIngredient)) {
              ingredientMap[cleanIngredient]!.quantity++;
            } else {
              ingredientMap[cleanIngredient] = GroceryItem(
                name: ingredient,
                category: category,
                quantity: 1,
              );
            }
          }
        }
      }
    }

    _groceryList = ingredientMap.values.toList()
      ..sort((a, b) {
        int categoryCompare = a.category.compareTo(b.category);
        if (categoryCompare != 0) return categoryCompare;
        return a.name.compareTo(b.name);
      });
  }

  String _categorizeIngredient(String ingredient) {
    // Simple categorization - you can make this more sophisticated
    if (ingredient.contains('chicken') || ingredient.contains('beef') || 
        ingredient.contains('pork') || ingredient.contains('fish') ||
        ingredient.contains('meat') || ingredient.contains('salmon')) {
      return 'Meat & Seafood';
    } else if (ingredient.contains('milk') || ingredient.contains('cheese') ||
               ingredient.contains('yogurt') || ingredient.contains('butter') ||
               ingredient.contains('cream')) {
      return 'Dairy';
    } else if (ingredient.contains('tomato') || ingredient.contains('onion') ||
               ingredient.contains('carrot') || ingredient.contains('pepper') ||
               ingredient.contains('lettuce') || ingredient.contains('broccoli') ||
               ingredient.contains('cucumber') || ingredient.contains('garlic')) {
      return 'Vegetables';
    } else if (ingredient.contains('apple') || ingredient.contains('banana') ||
               ingredient.contains('orange') || ingredient.contains('berry') ||
               ingredient.contains('lemon') || ingredient.contains('lime')) {
      return 'Fruits';
    } else if (ingredient.contains('rice') || ingredient.contains('pasta') ||
               ingredient.contains('bread') || ingredient.contains('flour') ||
               ingredient.contains('quinoa') || ingredient.contains('oats')) {
      return 'Grains & Cereals';
    } else if (ingredient.contains('oil') || ingredient.contains('vinegar') ||
               ingredient.contains('sauce') || ingredient.contains('dressing')) {
      return 'Condiments & Oils';
    } else if (ingredient.contains('salt') || ingredient.contains('pepper') ||
               ingredient.contains('spice') || ingredient.contains('herb')) {
      return 'Spices & Herbs';
    } else {
      return 'Other';
    }
  }

  void toggleGroceryItem(int index) {
    if (index >= 0 && index < _groceryList.length) {
      _groceryList[index] = _groceryList[index].copyWith(
        isChecked: !_groceryList[index].isChecked,
      );
      notifyListeners();
    }
  }

  void addCustomGroceryItem(String name, String category) {
    _groceryList.add(GroceryItem(name: name, category: category));
    _groceryList.sort((a, b) {
      int categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.name.compareTo(b.name);
    });
    notifyListeners();
  }

  void removeGroceryItem(int index) {
    if (index >= 0 && index < _groceryList.length) {
      _groceryList.removeAt(index);
      notifyListeners();
    }
  }

  void clearGroceryList() {
    _groceryList.clear();
    notifyListeners();
  }

  void regenerateGroceryList() {
    _generateGroceryList();
    notifyListeners();
  }

  // Calendar utilities
  List<List<DateTime?>> getCalendarWeeks(DateTime month) {
    DateTime firstDay = DateTime(month.year, month.month, 1);
    DateTime lastDay = DateTime(month.year, month.month + 1, 0);
    
    int startWeekday = firstDay.weekday % 7; // Convert to 0-6 (Sunday = 0)
    int daysInMonth = lastDay.day;
    
    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);
    
    // Fill in the days
    for (int day = 1; day <= daysInMonth; day++) {
      DateTime date = DateTime(month.year, month.month, day);
      int weekdayIndex = (startWeekday + day - 1) % 7;
      
      currentWeek[weekdayIndex] = date;
      
      // If we've filled a week or it's the last day, add to weeks
      if (weekdayIndex == 6 || day == daysInMonth) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
      }
    }
    
    return weeks;
  }

  bool hasPlannedMeals(DateTime date) {
    MealPlan? plan = getMealPlan(date);
    return plan?.hasMeals ?? false;
  }

  // Initialize with sample data
  void initializeWithSampleData() {
    DateTime now = DateTime.now();
    List<DateTime> weekDates = getCurrentWeekDates();
    
    // You can add sample meal plans here if needed
    // For now, we'll start with an empty meal plan
    
    _generateGroceryList();
    notifyListeners();
  }
} 