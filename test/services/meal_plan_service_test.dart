import 'package:flutter_test/flutter_test.dart';
import 'package:instarecipe/services/meal_plan_service.dart';
import 'package:instarecipe/models/recipe_model.dart';

void main() {
  group('MealPlanService Tests', () {
    late MealPlanService mealPlanService;
    late Recipe testRecipe;

    setUp(() {
      mealPlanService = MealPlanService();
      testRecipe = Recipe(
        id: '1',
        name: 'Test Recipe',
        description: 'A test recipe',
        ingredients: ['1 cup flour', '2 eggs', '1 cup milk'],
        instructions: ['Mix ingredients', 'Bake'],
        cookingTimeMinutes: 30,
        difficulty: 'Easy',
        cuisine: 'International',
        dietaryTags: [],
        category: 'Breakfast',
        rating: 4.5,
        servings: 4,
        calories: 250,
        imageUrl: 'https://example.com/image.jpg',
      );
    });

    test('Initial state is correct', () {
      expect(mealPlanService.selectedDate, isA<DateTime>());
      expect(mealPlanService.currentMonth, isA<DateTime>());
      expect(mealPlanService.mealPlans, isEmpty);
      expect(mealPlanService.currentWeekMeals, isEmpty);
      expect(mealPlanService.groceryItems, isEmpty);
    });

    test('Date selection works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      mealPlanService.selectDate(testDate);
      
      expect(mealPlanService.selectedDate.year, 2024);
      expect(mealPlanService.selectedDate.month, 1);
      expect(mealPlanService.selectedDate.day, 15);
    });

    test('Calendar navigation works correctly', () {
      final initialMonth = DateTime(2024, 1, 1);
      mealPlanService.currentMonth = initialMonth;
      
      // Test next month
      mealPlanService.goToNextMonth();
      expect(mealPlanService.currentMonth.month, 2);
      expect(mealPlanService.currentMonth.year, 2024);
      
      // Test previous month
      mealPlanService.goToPreviousMonth();
      expect(mealPlanService.currentMonth.month, 1);
      expect(mealPlanService.currentMonth.year, 2024);
      
      // Test year boundary (December to January)
      mealPlanService.currentMonth = DateTime(2024, 12, 1);
      mealPlanService.goToNextMonth();
      expect(mealPlanService.currentMonth.month, 1);
      expect(mealPlanService.currentMonth.year, 2025);
    });

    test('Go to today works correctly', () {
      final today = DateTime.now();
      mealPlanService.goToToday();
      
      expect(mealPlanService.selectedDate.year, today.year);
      expect(mealPlanService.selectedDate.month, today.month);
      expect(mealPlanService.selectedDate.day, today.day);
      expect(mealPlanService.currentMonth.year, today.year);
      expect(mealPlanService.currentMonth.month, today.month);
    });

    test('Adding meals works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Add breakfast
      mealPlanService.addMeal(testDate, 'breakfast', testRecipe);
      
      final mealPlan = mealPlanService.getMealPlan(testDate);
      expect(mealPlan, isNotNull);
      expect(mealPlan!.breakfast.length, 1);
      expect(mealPlan.breakfast.first.id, testRecipe.id);
      expect(mealPlan.lunch.isEmpty, true);
      expect(mealPlan.dinner.isEmpty, true);
      expect(mealPlan.snacks.isEmpty, true);
    });

    test('Adding multiple meals to same day works', () {
      final testDate = DateTime(2024, 1, 15);
      final lunchRecipe = testRecipe.copyWith(id: '2', name: 'Lunch Recipe');
      
      mealPlanService.addMeal(testDate, 'breakfast', testRecipe);
      mealPlanService.addMeal(testDate, 'lunch', lunchRecipe);
      
      final mealPlan = mealPlanService.getMealPlan(testDate);
      expect(mealPlan!.breakfast.length, 1);
      expect(mealPlan.lunch.length, 1);
      expect(mealPlan.breakfast.first.id, testRecipe.id);
      expect(mealPlan.lunch.first.id, lunchRecipe.id);
    });

    test('Removing meals works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Add and then remove meal
      mealPlanService.addMeal(testDate, 'breakfast', testRecipe);
      expect(mealPlanService.getMealPlan(testDate)!.breakfast.length, 1);
      
      mealPlanService.removeMeal(testDate, 'breakfast', testRecipe.id);
      expect(mealPlanService.getMealPlan(testDate)!.breakfast.length, 0);
    });

    test('Has meals on date check works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      final emptyDate = DateTime(2024, 1, 16);
      
      expect(mealPlanService.hasMealsOnDate(testDate), false);
      expect(mealPlanService.hasMealsOnDate(emptyDate), false);
      
      mealPlanService.addMeal(testDate, 'breakfast', testRecipe);
      expect(mealPlanService.hasMealsOnDate(testDate), true);
      expect(mealPlanService.hasMealsOnDate(emptyDate), false);
    });

    test('Current week meals calculation works correctly', () {
      final monday = DateTime(2024, 1, 15); // Assuming Monday
      final tuesday = monday.add(const Duration(days: 1));
      
      mealPlanService.addMeal(monday, 'breakfast', testRecipe);
      mealPlanService.addMeal(tuesday, 'lunch', testRecipe);
      
      mealPlanService.updateCurrentWeekMeals();
      
      expect(mealPlanService.currentWeekMeals.length, 2);
      expect(mealPlanService.currentWeekMeals.any((meal) => 
        meal.date.day == monday.day && meal.mealType == 'breakfast'), true);
      expect(mealPlanService.currentWeekMeals.any((meal) => 
        meal.date.day == tuesday.day && meal.mealType == 'lunch'), true);
    });

    test('Grocery list generation works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Add meals with different ingredients
      final recipe1 = testRecipe;
      final recipe2 = testRecipe.copyWith(
        id: '2',
        name: 'Recipe 2',
        ingredients: ['2 cups rice', '1 cup milk', '3 tomatoes'],
      );
      
      mealPlanService.addMeal(testDate, 'breakfast', recipe1);
      mealPlanService.addMeal(testDate, 'lunch', recipe2);
      
      mealPlanService.generateGroceryList();
      
      expect(mealPlanService.groceryItems.isNotEmpty, true);
      
      // Check that ingredients were categorized
      final milkItems = mealPlanService.groceryItems.where((item) => 
        item.name.toLowerCase().contains('milk')).toList();
      expect(milkItems.isNotEmpty, true);
      
      // Check that duplicate ingredients were combined
      expect(milkItems.length, 1);
      expect(milkItems.first.quantity, '2 cup'); // 1 + 1 = 2 cups
    });

    test('Grocery item ingredient parsing works correctly', () {
      final service = MealPlanService();
      
      // Test various ingredient formats
      expect(service.parseIngredientQuantity('2 cups flour'), equals(('flour', '2 cups')));
      expect(service.parseIngredientQuantity('1 large onion'), equals(('onion', '1 large')));
      expect(service.parseIngredientQuantity('Salt to taste'), equals(('salt', 'to taste')));
      expect(service.parseIngredientQuantity('3 eggs'), equals(('eggs', '3')));
      expect(service.parseIngredientQuantity('olive oil'), equals(('olive oil', '1')));
    });

    test('Grocery item categorization works correctly', () {
      final service = MealPlanService();
      
      expect(service.categorizeIngredient('tomatoes'), 'Vegetables');
      expect(service.categorizeIngredient('apples'), 'Fruits');
      expect(service.categorizeIngredient('chicken breast'), 'Meat & Seafood');
      expect(service.categorizeIngredient('milk'), 'Dairy');
      expect(service.categorizeIngredient('bread'), 'Bakery');
      expect(service.categorizeIngredient('flour'), 'Pantry');
      expect(service.categorizeIngredient('salt'), 'Spices & Seasonings');
      expect(service.categorizeIngredient('unknown ingredient'), 'Other');
    });

    test('Adding custom grocery items works correctly', () {
      mealPlanService.addCustomGroceryItem('Custom Item', 'Custom Category');
      
      expect(mealPlanService.groceryItems.length, 1);
      expect(mealPlanService.groceryItems.first.name, 'Custom Item');
      expect(mealPlanService.groceryItems.first.category, 'Custom Category');
      expect(mealPlanService.groceryItems.first.quantity, '1');
      expect(mealPlanService.groceryItems.first.isChecked, false);
    });

    test('Toggling grocery item check status works correctly', () {
      mealPlanService.addCustomGroceryItem('Test Item', 'Test Category');
      final itemId = mealPlanService.groceryItems.first.id;
      
      expect(mealPlanService.groceryItems.first.isChecked, false);
      
      mealPlanService.toggleGroceryItem(itemId);
      expect(mealPlanService.groceryItems.first.isChecked, true);
      
      mealPlanService.toggleGroceryItem(itemId);
      expect(mealPlanService.groceryItems.first.isChecked, false);
    });

    test('Clearing grocery list works correctly', () {
      mealPlanService.addCustomGroceryItem('Item 1', 'Category 1');
      mealPlanService.addCustomGroceryItem('Item 2', 'Category 2');
      
      expect(mealPlanService.groceryItems.length, 2);
      
      mealPlanService.clearGroceryList();
      expect(mealPlanService.groceryItems.isEmpty, true);
    });

    test('Date key generation works correctly', () {
      final date1 = DateTime(2024, 1, 15, 10, 30); // With time
      final date2 = DateTime(2024, 1, 15, 0, 0); // Without time
      final date3 = DateTime(2024, 2, 15, 0, 0); // Different month
      
      final key1 = mealPlanService.getDateKey(date1);
      final key2 = mealPlanService.getDateKey(date2);
      final key3 = mealPlanService.getDateKey(date3);
      
      expect(key1, key2); // Same date should generate same key
      expect(key1, isNot(key3)); // Different dates should generate different keys
      expect(key1, '2024-01-15');
      expect(key3, '2024-02-15');
    });

    test('Invalid meal type handling', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Should not throw error, but also should not add meal
      mealPlanService.addMeal(testDate, 'invalid_meal_type', testRecipe);
      
      final mealPlan = mealPlanService.getMealPlan(testDate);
      expect(mealPlan, isNull);
    });
  });

  group('MealPlan Model Tests', () {
    test('MealPlan creation with empty lists', () {
      final mealPlan = MealPlan();
      
      expect(mealPlan.breakfast.isEmpty, true);
      expect(mealPlan.lunch.isEmpty, true);
      expect(mealPlan.dinner.isEmpty, true);
      expect(mealPlan.snacks.isEmpty, true);
    });

    test('MealPlan total recipes count', () {
      final recipe1 = Recipe(
        id: '1', name: 'Recipe 1', description: '', ingredients: [], 
        instructions: [], cookingTimeMinutes: 30, difficulty: 'Easy',
        cuisine: 'International', dietaryTags: [], category: 'Breakfast',
        rating: 4.0, servings: 1, calories: 200, imageUrl: '',
      );
      final recipe2 = recipe1.copyWith(id: '2', name: 'Recipe 2');
      
      final mealPlan = MealPlan();
      mealPlan.breakfast.add(recipe1);
      mealPlan.lunch.add(recipe2);
      
      final totalRecipes = mealPlan.breakfast.length + 
                          mealPlan.lunch.length + 
                          mealPlan.dinner.length + 
                          mealPlan.snacks.length;
      
      expect(totalRecipes, 2);
    });
  });

  group('GroceryItem Model Tests', () {
    test('GroceryItem creation with all properties', () {
      final groceryItem = GroceryItem(
        id: '1',
        name: 'Milk',
        category: 'Dairy',
        quantity: '2 cups',
        isChecked: false,
      );
      
      expect(groceryItem.id, '1');
      expect(groceryItem.name, 'Milk');
      expect(groceryItem.category, 'Dairy');
      expect(groceryItem.quantity, '2 cups');
      expect(groceryItem.isChecked, false);
    });

    test('GroceryItem default values', () {
      final groceryItem = GroceryItem(
        id: '1',
        name: 'Item',
        category: 'Category',
      );
      
      expect(groceryItem.quantity, '1');
      expect(groceryItem.isChecked, false);
    });
  });

  group('WeeklyMeal Model Tests', () {
    test('WeeklyMeal creation', () {
      final date = DateTime(2024, 1, 15);
      final recipe = Recipe(
        id: '1', name: 'Recipe', description: '', ingredients: [], 
        instructions: [], cookingTimeMinutes: 30, difficulty: 'Easy',
        cuisine: 'International', dietaryTags: [], category: 'Breakfast',
        rating: 4.0, servings: 1, calories: 200, imageUrl: '',
      );
      
      final weeklyMeal = WeeklyMeal(
        date: date,
        mealType: 'breakfast',
        recipe: recipe,
      );
      
      expect(weeklyMeal.date, date);
      expect(weeklyMeal.mealType, 'breakfast');
      expect(weeklyMeal.recipe.id, recipe.id);
    });
  });
} 