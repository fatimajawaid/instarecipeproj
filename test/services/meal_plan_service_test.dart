import 'package:flutter_test/flutter_test.dart';
import 'package:instarecipe/services/meal_plan_service.dart';
import 'package:instarecipe/models/recipe_model.dart';

void main() {
  group('MealPlanService Tests', () {
    late MealPlanService mealPlanService;
    late Recipe testRecipe;

    setUp(() {
      mealPlanService = MealPlanService();
      // Clear any existing data
      mealPlanService.clearGroceryList();
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
      expect(mealPlanService.selectedDate, isNull);
      expect(mealPlanService.currentMonth, isA<DateTime>());
      expect(mealPlanService.mealPlans, isEmpty);
      expect(mealPlanService.groceryList, isEmpty);
    });

    test('Date selection works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      mealPlanService.selectDate(testDate);
      
      expect(mealPlanService.selectedDate!.year, 2024);
      expect(mealPlanService.selectedDate!.month, 1);
      expect(mealPlanService.selectedDate!.day, 15);
    });

    test('Calendar navigation works correctly', () {
      final initialMonth = DateTime(2024, 1, 1);
      // Set current month by navigating to it
      while (mealPlanService.currentMonth.month != 1 || 
             mealPlanService.currentMonth.year != 2024) {
        if (mealPlanService.currentMonth.year < 2024 ||
            (mealPlanService.currentMonth.year == 2024 && mealPlanService.currentMonth.month < 1)) {
          mealPlanService.goToNextMonth();
        } else {
          mealPlanService.goToPreviousMonth();
        }
      }
      
      // Test next month
      mealPlanService.goToNextMonth();
      expect(mealPlanService.currentMonth.month, 2);
      expect(mealPlanService.currentMonth.year, 2024);
      
      // Test previous month
      mealPlanService.goToPreviousMonth();
      expect(mealPlanService.currentMonth.month, 1);
      expect(mealPlanService.currentMonth.year, 2024);
      
      // Test year boundary (December to January)
      // Navigate to December 2024
      while (mealPlanService.currentMonth.month != 12 || 
             mealPlanService.currentMonth.year != 2024) {
        mealPlanService.goToNextMonth();
      }
      mealPlanService.goToNextMonth();
      expect(mealPlanService.currentMonth.month, 1);
      expect(mealPlanService.currentMonth.year, 2025);
    });

    test('Go to today works correctly', () {
      final today = DateTime.now();
      mealPlanService.goToToday();
      
      expect(mealPlanService.selectedDate!.year, today.year);
      expect(mealPlanService.selectedDate!.month, today.month);
      expect(mealPlanService.selectedDate!.day, today.day);
      expect(mealPlanService.currentMonth.year, today.year);
      expect(mealPlanService.currentMonth.month, today.month);
    });

    test('Adding meals works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Add breakfast
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      
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
      
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: lunchRecipe,
        mealType: 'lunch',
      );
      
      final mealPlan = mealPlanService.getMealPlan(testDate);
      expect(mealPlan!.breakfast.length, 1);
      expect(mealPlan.lunch.length, 1);
      expect(mealPlan.breakfast.first.id, testRecipe.id);
      expect(mealPlan.lunch.first.id, lunchRecipe.id);
    });

    test('Removing meals works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Add and then remove meal
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      expect(mealPlanService.getMealPlan(testDate)!.breakfast.length, 1);
      
      mealPlanService.removeMealFromDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      final mealPlan = mealPlanService.getMealPlan(testDate);
      expect(mealPlan, isNull); // Plan should be removed when no meals left
    });

    test('Has meals on date check works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      final emptyDate = DateTime(2024, 1, 16);
      
      expect(mealPlanService.hasPlannedMeals(testDate), false);
      expect(mealPlanService.hasPlannedMeals(emptyDate), false);
      
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      expect(mealPlanService.hasPlannedMeals(testDate), true);
      expect(mealPlanService.hasPlannedMeals(emptyDate), false);
    });

    test('Current week meal plans calculation works correctly', () {
      final weekDates = mealPlanService.getCurrentWeekDates();
      expect(weekDates.length, 7);
      
      // Add meals to different days
      mealPlanService.addMealToDate(
        date: weekDates[0],
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      mealPlanService.addMealToDate(
        date: weekDates[1],
        recipe: testRecipe,
        mealType: 'lunch',
      );
      
      final weekMealPlans = mealPlanService.getCurrentWeekMealPlans();
      expect(weekMealPlans.length, 7);
      
      // Check that meals were added correctly
      expect(weekMealPlans[0].breakfast.length, 1);
      expect(weekMealPlans[1].lunch.length, 1);
    });

    test('Grocery list generation works correctly', () {
      final testDate = DateTime.now(); // Use current date to be in this week
      
      // Add meals with different ingredients
      final recipe1 = testRecipe;
      final recipe2 = testRecipe.copyWith(
        id: '2',
        name: 'Recipe 2',
        ingredients: ['2 cups rice', '1 cup milk', '3 tomatoes'],
      );
      
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: recipe1,
        mealType: 'breakfast',
      );
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: recipe2,
        mealType: 'lunch',
      );
      
      expect(mealPlanService.groceryList.isNotEmpty, true);
      
      // Check that ingredients were categorized
      final milkItems = mealPlanService.groceryList.where((item) => 
        item.name.toLowerCase().contains('milk')).toList();
      expect(milkItems.isNotEmpty, true);
    });

    test('Adding custom grocery items works correctly', () {
      mealPlanService.addCustomGroceryItem('Custom Item', 'Custom Category');
      
      expect(mealPlanService.groceryList.length, 1);
      expect(mealPlanService.groceryList.first.name, 'Custom Item');
      expect(mealPlanService.groceryList.first.category, 'Custom Category');
      expect(mealPlanService.groceryList.first.quantity, 1);
      expect(mealPlanService.groceryList.first.isChecked, false);
    });

    test('Toggling grocery item check status works correctly', () {
      mealPlanService.addCustomGroceryItem('Test Item', 'Test Category');
      
      expect(mealPlanService.groceryList.first.isChecked, false);
      
      mealPlanService.toggleGroceryItem(0);
      expect(mealPlanService.groceryList.first.isChecked, true);
      
      mealPlanService.toggleGroceryItem(0);
      expect(mealPlanService.groceryList.first.isChecked, false);
    });

    test('Clearing grocery list works correctly', () {
      mealPlanService.addCustomGroceryItem('Item 1', 'Category 1');
      mealPlanService.addCustomGroceryItem('Item 2', 'Category 2');
      
      expect(mealPlanService.groceryList.length, 2);
      
      mealPlanService.clearGroceryList();
      expect(mealPlanService.groceryList.isEmpty, true);
    });

    test('Calendar weeks generation works correctly', () {
      final month = DateTime(2024, 1, 1);
      final weeks = mealPlanService.getCalendarWeeks(month);
      
      expect(weeks.isNotEmpty, true);
      expect(weeks.first.length, 7); // Each week has 7 days
      
      // Check that January 1, 2024 is included
      bool hasJan1 = false;
      for (var week in weeks) {
        for (var day in week) {
          if (day != null && day.day == 1 && day.month == 1) {
            hasJan1 = true;
            break;
          }
        }
      }
      expect(hasJan1, true);
    });

    test('Clear meal plan works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'breakfast',
      );
      expect(mealPlanService.getMealPlan(testDate), isNotNull);
      
      mealPlanService.clearMealPlan(testDate);
      expect(mealPlanService.getMealPlan(testDate), isNull);
    });

    test('Initialize with sample data works', () {
      mealPlanService.initializeWithSampleData();
      // Should not throw any errors
      expect(mealPlanService.groceryList, isNotNull);
    });

    test('Invalid meal type handling', () {
      final testDate = DateTime(2024, 1, 15);
      
      // Should not throw error, but also should not add meal
      mealPlanService.addMealToDate(
        date: testDate,
        recipe: testRecipe,
        mealType: 'invalid_meal_type',
      );
      
      final mealPlan = mealPlanService.getMealPlan(testDate);
      expect(mealPlan, isNull);
    });
  });

  group('MealPlan Model Tests', () {
    test('MealPlan creation with empty lists', () {
      final testDate = DateTime(2024, 1, 15);
      final mealPlan = MealPlan(date: testDate);
      
      expect(mealPlan.breakfast.isEmpty, true);
      expect(mealPlan.lunch.isEmpty, true);
      expect(mealPlan.dinner.isEmpty, true);
      expect(mealPlan.snacks.isEmpty, true);
      expect(mealPlan.date, testDate);
    });

    test('MealPlan total recipes count', () {
      final testDate = DateTime(2024, 1, 15);
      final recipe1 = Recipe(
        id: '1', name: 'Recipe 1', description: '', ingredients: [], 
        instructions: [], cookingTimeMinutes: 30, difficulty: 'Easy',
        cuisine: 'International', dietaryTags: [], category: 'Breakfast',
        rating: 4.0, servings: 1, calories: 200, imageUrl: '',
      );
      final recipe2 = recipe1.copyWith(id: '2', name: 'Recipe 2');
      
      final mealPlan = MealPlan(
        date: testDate,
        breakfast: [recipe1],
        lunch: [recipe2],
      );
      
      expect(mealPlan.allMeals.length, 2);
      expect(mealPlan.hasMeals, true);
    });

    test('MealPlan meal summary works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      final recipe = Recipe(
        id: '1', name: 'Recipe', description: '', ingredients: [], 
        instructions: [], cookingTimeMinutes: 30, difficulty: 'Easy',
        cuisine: 'International', dietaryTags: [], category: 'Breakfast',
        rating: 4.0, servings: 1, calories: 200, imageUrl: '',
      );
      
      final emptyMealPlan = MealPlan(date: testDate);
      expect(emptyMealPlan.mealSummary, 'No meals planned');
      
      final mealPlan = MealPlan(
        date: testDate,
        breakfast: [recipe],
        lunch: [recipe],
      );
      expect(mealPlan.mealSummary, '1 breakfast, 1 lunch');
    });

    test('MealPlan copyWith works correctly', () {
      final testDate = DateTime(2024, 1, 15);
      final recipe = Recipe(
        id: '1', name: 'Recipe', description: '', ingredients: [], 
        instructions: [], cookingTimeMinutes: 30, difficulty: 'Easy',
        cuisine: 'International', dietaryTags: [], category: 'Breakfast',
        rating: 4.0, servings: 1, calories: 200, imageUrl: '',
      );
      
      final originalPlan = MealPlan(date: testDate);
      final updatedPlan = originalPlan.copyWith(breakfast: [recipe]);
      
      expect(originalPlan.breakfast.isEmpty, true);
      expect(updatedPlan.breakfast.length, 1);
      expect(updatedPlan.date, testDate);
    });
  });

  group('GroceryItem Model Tests', () {
    test('GroceryItem creation with all properties', () {
      final groceryItem = GroceryItem(
        name: 'Milk',
        category: 'Dairy',
        quantity: 2,
        isChecked: false,
      );
      
      expect(groceryItem.name, 'Milk');
      expect(groceryItem.category, 'Dairy');
      expect(groceryItem.quantity, 2);
      expect(groceryItem.isChecked, false);
    });

    test('GroceryItem default values', () {
      final groceryItem = GroceryItem(
        name: 'Item',
        category: 'Category',
      );
      
      expect(groceryItem.quantity, 1);
      expect(groceryItem.isChecked, false);
    });

    test('GroceryItem copyWith works correctly', () {
      final original = GroceryItem(
        name: 'Item',
        category: 'Category',
      );
      
      final updated = original.copyWith(
        quantity: 5,
        isChecked: true,
      );
      
      expect(original.quantity, 1);
      expect(original.isChecked, false);
      expect(updated.quantity, 5);
      expect(updated.isChecked, true);
      expect(updated.name, 'Item');
      expect(updated.category, 'Category');
    });
  });
} 