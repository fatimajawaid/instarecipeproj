import 'package:flutter_test/flutter_test.dart';
import 'package:instarecipe/models/recipe_model.dart';

void main() {
  group('Recipe Model Tests', () {
    late Recipe testRecipe;

    setUp(() {
      testRecipe = Recipe(
        id: '1',
        name: 'Test Recipe',
        description: 'A delicious test recipe',
        ingredients: ['1 cup flour', '2 eggs', '1 cup milk'],
        instructions: ['Mix ingredients', 'Bake for 30 minutes'],
        cookingTimeMinutes: 30,
        difficulty: 'Easy',
        cuisine: 'International',
        dietaryTags: ['Vegetarian'],
        category: 'Breakfast',
        rating: 4.5,
        servings: 4,
        calories: 250,
        imageUrl: 'https://example.com/image.jpg',
      );
    });

    test('Recipe creation with valid data', () {
      expect(testRecipe.id, '1');
      expect(testRecipe.name, 'Test Recipe');
      expect(testRecipe.ingredients.length, 3);
      expect(testRecipe.instructions.length, 2);
      expect(testRecipe.cookingTimeMinutes, 30);
      expect(testRecipe.rating, 4.5);
      expect(testRecipe.servings, 4);
      expect(testRecipe.calories, 250);
    });

    test('Formatted cooking time returns correct format', () {
      // Test minutes only
      expect(testRecipe.formattedCookingTime, '30min');

      // Test hours and minutes
      final longRecipe = Recipe(
        id: '2',
        name: 'Long Recipe',
        description: 'Takes a while',
        ingredients: ['ingredient'],
        instructions: ['instruction'],
        cookingTimeMinutes: 90, // 1 hour 30 minutes
        difficulty: 'Hard',
        cuisine: 'Italian',
        dietaryTags: [],
        category: 'Dinner',
        rating: 4.0,
        servings: 2,
        calories: 500,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(longRecipe.formattedCookingTime, '1h 30min');

      // Test exact hours
      final hourRecipe = Recipe(
        id: '3',
        name: 'Hour Recipe',
        description: 'Exactly one hour',
        ingredients: ['ingredient'],
        instructions: ['instruction'],
        cookingTimeMinutes: 60,
        difficulty: 'Medium',
        cuisine: 'Asian',
        dietaryTags: ['Vegan'],
        category: 'Lunch',
        rating: 3.5,
        servings: 3,
        calories: 300,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(hourRecipe.formattedCookingTime, '1h');
    });

    test('Difficulty color returns correct color', () {
      // Test Easy difficulty
      expect(testRecipe.difficultyColor.value, 0xFF4CAF50); // Green

      // Test Medium difficulty
      final mediumRecipe = Recipe(
        id: '2',
        name: 'Medium Recipe',
        description: 'Medium difficulty',
        ingredients: ['ingredient'],
        instructions: ['instruction'],
        cookingTimeMinutes: 45,
        difficulty: 'Medium',
        cuisine: 'Mexican',
        dietaryTags: [],
        category: 'Lunch',
        rating: 4.0,
        servings: 2,
        calories: 400,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(mediumRecipe.difficultyColor.value, 0xFFFF9800); // Orange

      // Test Hard difficulty
      final hardRecipe = Recipe(
        id: '3',
        name: 'Hard Recipe',
        description: 'Very difficult',
        ingredients: ['ingredient'],
        instructions: ['instruction'],
        cookingTimeMinutes: 120,
        difficulty: 'Hard',
        cuisine: 'French',
        dietaryTags: [],
        category: 'Dinner',
        rating: 5.0,
        servings: 6,
        calories: 800,
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(hardRecipe.difficultyColor.value, 0xFFF44336); // Red
    });

    test('toMap creates correct map', () {
      final map = testRecipe.toMap();
      
      expect(map['id'], '1');
      expect(map['name'], 'Test Recipe');
      expect(map['ingredients'], ['1 cup flour', '2 eggs', '1 cup milk']);
      expect(map['cookingTimeMinutes'], 30);
      expect(map['rating'], 4.5);
      expect(map['calories'], 250);
      expect(map['servings'], 4);
    });

    test('fromMap creates Recipe from map', () {
      final map = {
        'id': '2',
        'name': 'Map Recipe',
        'description': 'Created from map',
        'ingredients': ['ingredient1', 'ingredient2'],
        'instructions': ['step1', 'step2'],
        'cookingTimeMinutes': 45,
        'difficulty': 'Medium',
        'cuisine': 'Thai',
        'dietaryTags': ['Spicy'],
        'category': 'Lunch',
        'rating': 4.2,
        'servings': 3,
        'calories': 350,
        'imageUrl': 'https://example.com/map.jpg',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      final recipe = Recipe.fromMap(map);
      
      expect(recipe.id, '2');
      expect(recipe.name, 'Map Recipe');
      expect(recipe.ingredients.length, 2);
      expect(recipe.cookingTimeMinutes, 45);
      expect(recipe.rating, 4.2);
      expect(recipe.servings, 3);
      expect(recipe.calories, 350);
    });

    test('copyWith creates modified copy', () {
      final copiedRecipe = testRecipe.copyWith(
        name: 'Modified Recipe',
        rating: 5.0,
        servings: 6,
      );

      expect(copiedRecipe.id, testRecipe.id); // Unchanged
      expect(copiedRecipe.name, 'Modified Recipe'); // Changed
      expect(copiedRecipe.rating, 5.0); // Changed
      expect(copiedRecipe.servings, 6); // Changed
      expect(copiedRecipe.difficulty, testRecipe.difficulty); // Unchanged
    });

    test('Dietary preference matching', () {
      final vegetarianRecipe = Recipe(
        id: '1',
        name: 'Veggie Recipe',
        description: 'Vegetarian dish',
        ingredients: ['vegetables'],
        instructions: ['cook vegetables'],
        cookingTimeMinutes: 20,
        difficulty: 'Easy',
        cuisine: 'International',
        dietaryTags: ['Vegetarian', 'Gluten-Free'],
        category: 'Lunch',
        rating: 4.0,
        servings: 2,
        calories: 200,
        imageUrl: 'https://example.com/veggie.jpg',
      );

      expect(vegetarianRecipe.matchesDietaryPreference('Vegetarian'), true);
      expect(vegetarianRecipe.matchesDietaryPreference('Gluten-Free'), true);
      expect(vegetarianRecipe.matchesDietaryPreference('Vegan'), false);
    });

    test('Ingredient match text calculation', () {
      final recipeWithMatch = testRecipe.copyWith(
        matchingIngredientsCount: 3,
        totalIngredientsCount: 5,
      );

      expect(recipeWithMatch.ingredientMatchText, '3/5 ingredients');

      // Test null values
      expect(testRecipe.ingredientMatchText, null);
    });

    test('Recipe with empty/default values handles gracefully', () {
      final emptyRecipe = Recipe(
        id: '',
        name: '',
        description: '',
        ingredients: [],
        instructions: [],
        cookingTimeMinutes: 0,
        difficulty: '',
        cuisine: '',
        dietaryTags: [],
        category: '',
        rating: 0.0,
        servings: 0,
        calories: 0,
        imageUrl: '',
      );

      expect(emptyRecipe.formattedCookingTime, '0min');
      expect(emptyRecipe.ingredients.isEmpty, true);
      expect(emptyRecipe.instructions.isEmpty, true);
      expect(emptyRecipe.dietaryTags.isEmpty, true);
    });
  });
} 