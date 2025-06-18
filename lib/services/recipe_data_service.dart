import '../models/recipe_model.dart';
import '../models/ingredient_model.dart';
import 'firebase_service.dart';
import 'offline_cache_service.dart';

class RecipeDataService {
  static final RecipeDataService _instance = RecipeDataService._internal();
  factory RecipeDataService() => _instance;
  RecipeDataService._internal();

  final FirebaseService _firebaseService = FirebaseService();
  final OfflineCacheService _cacheService = OfflineCacheService();
  
  List<Recipe> _allRecipes = [];
  List<Ingredient> _allIngredients = [];
  List<String> _userSelectedIngredients = [];

  // Lists to store favorites and saved recipes
  List<Recipe> _favoriteRecipes = [];
  List<Recipe> _savedRecipes = [];

  // Initialize with sample data and cache
  Future<void> initializeData() async {
    // Initialize offline cache service
    await _cacheService.initialize();
    
    _allRecipes = _getSampleRecipes();
    _allIngredients = _getSampleIngredients();
    
    // Cache the sample recipes for offline access
    await _cacheService.cacheAllRecipes(_allRecipes);
    
    // Load cached user data
    await _loadCachedUserData();
  }

  // Load cached user data
  Future<void> _loadCachedUserData() async {
    try {
      _savedRecipes = await _cacheService.getCachedSavedRecipes();
      _favoriteRecipes = await _cacheService.getCachedFavoriteRecipes();
      
      // Load and merge user created recipes
      final List<Recipe> userRecipes = await _cacheService.getCachedUserRecipes();
      for (final Recipe userRecipe in userRecipes) {
        final int existingIndex = _allRecipes.indexWhere((r) => r.id == userRecipe.id);
        if (existingIndex != -1) {
          _allRecipes[existingIndex] = userRecipe;
        } else {
          _allRecipes.add(userRecipe);
        }
      }
    } catch (e) {
      print('Error loading cached user data: $e');
    }
  }

  // Get all recipes
  List<Recipe> getAllRecipes() => _allRecipes;

  // Get recipes with ingredient matching
  List<Recipe> getRecipesWithMatching({
    required List<String> selectedIngredients,
    String? searchQuery,
    List<String>? dietaryFilters,
    String? sortBy,
    String? cuisine,
    String? difficulty,
  }) {
    List<Recipe> filteredRecipes = List<Recipe>.from(_allRecipes);

    // Apply search query filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredRecipes = filteredRecipes.where((recipe) =>
          recipe.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          recipe.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          recipe.ingredients.any((ingredient) => 
              ingredient.toLowerCase().contains(searchQuery.toLowerCase()))).toList();
    }

    // Apply dietary filters
    if (dietaryFilters != null && dietaryFilters.isNotEmpty) {
      filteredRecipes = filteredRecipes.where((recipe) {
        return dietaryFilters.every((filter) => recipe.dietaryTags.contains(filter));
      }).toList();
    }

    // Apply cuisine filter
    if (cuisine != null && cuisine != 'All') {
      filteredRecipes = filteredRecipes.where((recipe) => recipe.cuisine == cuisine).toList();
    }

    // Apply difficulty filter
    if (difficulty != null && difficulty != 'All') {
      filteredRecipes = filteredRecipes.where((recipe) => recipe.difficulty == difficulty).toList();
    }

    // Calculate ingredient matching for each recipe
    for (Recipe recipe in filteredRecipes) {
      List<String> matchingIngredients = [];
      List<String> missingIngredients = [];

      for (String recipeIngredient in recipe.ingredients) {
        bool found = false;
        for (String selectedIngredient in selectedIngredients) {
          if (recipeIngredient.toLowerCase().contains(selectedIngredient.toLowerCase()) ||
              selectedIngredient.toLowerCase().contains(recipeIngredient.toLowerCase())) {
            matchingIngredients.add(recipeIngredient);
            found = true;
            break;
          }
        }
        if (!found) {
          missingIngredients.add(recipeIngredient);
        }
      }

      // Set ingredient counts and format
      recipe.matchingIngredientsCount = matchingIngredients.length;
      recipe.totalIngredientsCount = recipe.ingredients.length;
      recipe.missingIngredients = missingIngredients;
      
      // Calculate percentage for sorting purposes but don't use for display
      recipe.matchPercentage = recipe.ingredients.isEmpty 
          ? 0 
          : (matchingIngredients.length / recipe.ingredients.length * 100).round();
    }

    // Sort recipes
    if (sortBy != null) {
      switch (sortBy) {
        case 'Relevance':
          filteredRecipes.sort((a, b) => (b.matchingIngredientsCount ?? 0).compareTo(a.matchingIngredientsCount ?? 0));
          break;
        case 'Cooking Time':
          filteredRecipes.sort((a, b) => a.cookingTimeMinutes.compareTo(b.cookingTimeMinutes));
          break;
        case 'Difficulty Level':
          filteredRecipes.sort((a, b) {
            final difficultyOrder = {'Easy': 1, 'Medium': 2, 'Hard': 3};
            return (difficultyOrder[a.difficulty] ?? 2).compareTo(difficultyOrder[b.difficulty] ?? 2);
          });
          break;
        case 'Rating':
          filteredRecipes.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Popularity':
          filteredRecipes.sort((a, b) => b.rating.compareTo(a.rating)); // Using rating as proxy for popularity
          break;
        case 'Newest':
          // For now, keep original order as "newest"
          break;
      }
    }

    return filteredRecipes;
  }

  // Get categorized ingredients
  List<IngredientCategory> getIngredientCategories() {
    Map<String, List<Ingredient>> categorizedIngredients = {};
    
    for (Ingredient ingredient in _allIngredients) {
      if (!categorizedIngredients.containsKey(ingredient.category)) {
        categorizedIngredients[ingredient.category] = [];
      }
      categorizedIngredients[ingredient.category]!.add(ingredient);
    }

    return categorizedIngredients.entries.map((entry) {
      return IngredientCategory(
        id: entry.key.toLowerCase().replaceAll(' ', '_'),
        name: entry.key,
        icon: _getCategoryIcon(entry.key),
        ingredients: entry.value,
      );
    }).toList();
  }

  // Update user selected ingredients
  void updateSelectedIngredients(List<String> selectedIngredients) {
    _userSelectedIngredients = selectedIngredients;
  }

  // Get user selected ingredients
  List<String> getUserSelectedIngredients() => _userSelectedIngredients;

  // Helper methods
  bool _ingredientMatches(String recipeIngredient, String selectedIngredient) {
    String recipe = recipeIngredient.toLowerCase();
    String selected = selectedIngredient.toLowerCase();
    
    return recipe.contains(selected) || selected.contains(recipe);
  }

  int _getDifficultyOrder(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': return 1;
      case 'medium': return 2;
      case 'hard': return 3;
      default: return 0;
    }
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'vegetables': return '🥕';
      case 'fruits': return '🍎';
      case 'proteins': return '🥩';
      case 'dairy': return '🥛';
      case 'grains': return '🌾';
      case 'spices': return '🌶️';
      case 'herbs': return '🌿';
      case 'oils': return '🫒';
      case 'condiments': return '🍯';
      case 'seafood': return '🐟';
      default: return '🥄';
    }
  }

  // Sample recipes data
  List<Recipe> _getSampleRecipes() {
    return [
      Recipe(
        id: '1',
        name: 'Classic Spaghetti Carbonara',
        description: 'Creamy Italian pasta dish with eggs, cheese, and pancetta',
        imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=500&h=400&fit=crop',
        ingredients: ['spaghetti', 'pancetta', 'eggs', 'parmesan cheese', 'black pepper', 'salt', 'garlic'],
        instructions: [
          'Cook spaghetti according to package directions',
          'Cook pancetta until crispy',
          'Whisk eggs with cheese and pepper',
          'Combine hot pasta with pancetta and egg mixture',
          'Serve immediately'
        ],
        cookingTimeMinutes: 25,
        difficulty: 'Medium',
        cuisine: 'Italian',
        dietaryTags: [],
        rating: 4.8,
        servings: 4,
        calories: 520,
        category: 'Main Course',
      ),
      Recipe(
        id: '2',
        name: 'Chicken Tikka Masala',
        description: 'Tender chicken in a rich, creamy tomato-based curry sauce',
        imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500&h=400&fit=crop',
        ingredients: ['chicken breast', 'yogurt', 'tomatoes', 'onions', 'garlic', 'ginger', 'cream', 'spices'],
        instructions: [
          'Marinate chicken in yogurt and spices',
          'Cook chicken until browned',
          'Make curry sauce with tomatoes and spices',
          'Combine chicken with sauce',
          'Serve with rice'
        ],
        cookingTimeMinutes: 45,
        difficulty: 'Medium',
        cuisine: 'Indian',
        dietaryTags: ['Gluten-Free'],
        rating: 4.7,
        servings: 6,
        calories: 380,
        category: 'Main Course',
      ),
      Recipe(
        id: '3',
        name: 'Avocado Toast',
        description: 'Healthy breakfast with creamy avocado and poached egg',
        imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c44d?w=500&h=400&fit=crop',
        ingredients: ['bread', 'avocado', 'eggs', 'lemon', 'salt', 'pepper', 'olive oil'],
        instructions: [
          'Toast bread slices',
          'Poach eggs in simmering water',
          'Mash avocado with lemon and seasoning',
          'Spread avocado on toast',
          'Top with poached egg'
        ],
        cookingTimeMinutes: 15,
        difficulty: 'Easy',
        cuisine: 'International',
        dietaryTags: ['Vegetarian'],
        rating: 4.5,
        servings: 2,
        calories: 280,
        category: 'Breakfast',
      ),
      Recipe(
        id: '4',
        name: 'Beef Stir-Fry',
        description: 'Quick stir-fry with tender beef and crisp vegetables',
        imageUrl: 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=500&h=400&fit=crop',
        ingredients: ['beef', 'bell peppers', 'broccoli', 'carrots', 'garlic', 'soy sauce', 'oil'],
        instructions: [
          'Slice beef thinly',
          'Heat oil in wok',
          'Stir-fry beef until browned',
          'Add vegetables and stir-fry',
          'Season with soy sauce'
        ],
        cookingTimeMinutes: 20,
        difficulty: 'Easy',
        cuisine: 'Asian',
        dietaryTags: [],
        rating: 4.6,
        servings: 4,
        calories: 320,
        category: 'Main Course',
      ),
      Recipe(
        id: '5',
        name: 'Mediterranean Quinoa Salad',
        description: 'Fresh salad with quinoa, vegetables, and feta cheese',
        imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&h=400&fit=crop',
        ingredients: ['quinoa', 'cucumber', 'tomatoes', 'onions', 'feta cheese', 'olive oil', 'lemon'],
        instructions: [
          'Cook quinoa until tender',
          'Dice vegetables',
          'Make lemon vinaigrette',
          'Combine all ingredients',
          'Chill before serving'
        ],
        cookingTimeMinutes: 30,
        difficulty: 'Easy',
        cuisine: 'Mediterranean',
        dietaryTags: ['Vegetarian', 'Gluten-Free'],
        rating: 4.4,
        servings: 6,
        calories: 240,
        category: 'Salad',
      ),
      Recipe(
        id: '6',
        name: 'Chocolate Chip Cookies',
        description: 'Classic homemade cookies with gooey chocolate chips',
        imageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=500&h=400&fit=crop',
        ingredients: ['flour', 'butter', 'sugar', 'eggs', 'vanilla', 'chocolate chips', 'baking soda'],
        instructions: [
          'Cream butter and sugars',
          'Add eggs and vanilla',
          'Mix in dry ingredients',
          'Fold in chocolate chips',
          'Bake until golden'
        ],
        cookingTimeMinutes: 25,
        difficulty: 'Easy',
        cuisine: 'American',
        dietaryTags: ['Vegetarian'],
        rating: 4.9,
        servings: 24,
        calories: 180,
        category: 'Dessert',
      ),
      Recipe(
        id: '7',
        name: 'Thai Green Curry',
        description: 'Aromatic and spicy Thai curry with coconut milk',
        imageUrl: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=500&h=400&fit=crop',
        ingredients: ['chicken breast', 'coconut milk', 'green curry paste', 'bell peppers', 'thai basil', 'fish sauce'],
        instructions: [
          'Heat coconut milk in pan',
          'Add curry paste and fry until fragrant',
          'Add chicken and cook through',
          'Add vegetables and simmer',
          'Garnish with basil'
        ],
        cookingTimeMinutes: 35,
        difficulty: 'Medium',
        cuisine: 'Thai',
        dietaryTags: ['Gluten-Free'],
        rating: 4.7,
        servings: 4,
        calories: 420,
        category: 'Main Course',
      ),
      Recipe(
        id: '8',
        name: 'Caesar Salad',
        description: 'Classic Caesar salad with homemade dressing and croutons',
        imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=500&h=400&fit=crop',
        ingredients: ['lettuce', 'parmesan cheese', 'bread', 'garlic', 'anchovies', 'lemon', 'olive oil'],
        instructions: [
          'Make croutons from bread',
          'Prepare Caesar dressing',
          'Wash and chop lettuce',
          'Toss with dressing',
          'Top with parmesan and croutons'
        ],
        cookingTimeMinutes: 20,
        difficulty: 'Easy',
        cuisine: 'Italian',
        dietaryTags: [],
        rating: 4.3,
        servings: 4,
        calories: 220,
        category: 'Salad',
      ),
      Recipe(
        id: '9',
        name: 'Mushroom Risotto',
        description: 'Creamy Italian rice dish with wild mushrooms',
        imageUrl: 'https://images.unsplash.com/photo-1476124369491-e7addf5db371?w=500&h=400&fit=crop',
        ingredients: ['rice', 'mushrooms', 'onions', 'garlic', 'white wine', 'parmesan cheese', 'butter'],
        instructions: [
          'Sauté mushrooms until golden',
          'Cook onions and garlic',
          'Add rice and toast lightly',
          'Add wine and stock gradually',
          'Finish with cheese and butter'
        ],
        cookingTimeMinutes: 40,
        difficulty: 'Medium',
        cuisine: 'Italian',
        dietaryTags: ['Vegetarian'],
        rating: 4.6,
        servings: 4,
        calories: 350,
        category: 'Main Course',
      ),
      Recipe(
        id: '10',
        name: 'Fish Tacos',
        description: 'Fresh fish tacos with cabbage slaw and lime',
        imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=500&h=400&fit=crop',
        ingredients: ['fish', 'tortillas', 'cabbage', 'lime', 'cilantro', 'avocado', 'sour cream'],
        instructions: [
          'Season and cook fish',
          'Make cabbage slaw',
          'Warm tortillas',
          'Assemble tacos with fish and slaw',
          'Serve with lime wedges'
        ],
        cookingTimeMinutes: 25,
        difficulty: 'Easy',
        cuisine: 'Mexican',
        dietaryTags: ['Gluten-Free'],
        rating: 4.5,
        servings: 4,
        calories: 290,
        category: 'Main Course',
      ),
      Recipe(
        id: '11',
        name: 'Pancakes',
        description: 'Fluffy breakfast pancakes with maple syrup',
        imageUrl: 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=500&h=400&fit=crop',
        ingredients: ['flour', 'milk', 'eggs', 'sugar', 'baking powder', 'butter', 'vanilla'],
        instructions: [
          'Mix dry ingredients',
          'Combine wet ingredients',
          'Fold wet into dry ingredients',
          'Cook on griddle until bubbles form',
          'Flip and cook until golden'
        ],
        cookingTimeMinutes: 20,
        difficulty: 'Easy',
        cuisine: 'American',
        dietaryTags: ['Vegetarian'],
        rating: 4.8,
        servings: 4,
        calories: 250,
        category: 'Breakfast',
      ),
      Recipe(
        id: '12',
        name: 'Beef Burger',
        description: 'Juicy beef burger with fresh toppings',
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&h=400&fit=crop',
        ingredients: ['ground beef', 'burger buns', 'lettuce', 'tomatoes', 'onions', 'cheese', 'pickles'],
        instructions: [
          'Form beef into patties',
          'Season with salt and pepper',
          'Grill patties to desired doneness',
          'Toast buns lightly',
          'Assemble burger with toppings'
        ],
        cookingTimeMinutes: 15,
        difficulty: 'Easy',
        cuisine: 'American',
        dietaryTags: [],
        rating: 4.7,
        servings: 4,
        calories: 450,
        category: 'Main Course',
      ),
      Recipe(
        id: '13',
        name: 'Vegetable Soup',
        description: 'Hearty vegetable soup with seasonal vegetables',
        imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=500&h=400&fit=crop',
        ingredients: ['carrots', 'celery', 'onions', 'tomatoes', 'potatoes', 'vegetable broth', 'herbs'],
        instructions: [
          'Chop all vegetables',
          'Sauté onions, carrots, and celery',
          'Add remaining vegetables and broth',
          'Simmer until vegetables are tender',
          'Season with herbs and spices'
        ],
        cookingTimeMinutes: 45,
        difficulty: 'Easy',
        cuisine: 'International',
        dietaryTags: ['Vegetarian', 'Vegan', 'Gluten-Free'],
        rating: 4.2,
        servings: 6,
        calories: 120,
        category: 'Soup',
      ),
      Recipe(
        id: '14',
        name: 'Chicken Caesar Wrap',
        description: 'Grilled chicken Caesar salad in a tortilla wrap',
        imageUrl: 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=500&h=400&fit=crop',
        ingredients: ['chicken breast', 'tortillas', 'lettuce', 'parmesan cheese', 'caesar dressing', 'croutons'],
        instructions: [
          'Grill chicken and slice',
          'Toss lettuce with Caesar dressing',
          'Warm tortillas',
          'Fill with chicken and salad',
          'Roll tightly and slice'
        ],
        cookingTimeMinutes: 20,
        difficulty: 'Easy',
        cuisine: 'American',
        dietaryTags: [],
        rating: 4.4,
        servings: 4,
        calories: 320,
        category: 'Lunch',
      ),
      Recipe(
        id: '15',
        name: 'Chocolate Brownies',
        description: 'Rich and fudgy chocolate brownies',
        imageUrl: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=500&h=400&fit=crop',
        ingredients: ['chocolate', 'butter', 'sugar', 'eggs', 'flour', 'cocoa powder', 'vanilla'],
        instructions: [
          'Melt chocolate and butter',
          'Beat in sugar and eggs',
          'Fold in flour and cocoa',
          'Pour into baking pan',
          'Bake until set but still fudgy'
        ],
        cookingTimeMinutes: 35,
        difficulty: 'Easy',
        cuisine: 'American',
        dietaryTags: ['Vegetarian'],
        rating: 4.9,
        servings: 12,
        calories: 280,
        category: 'Dessert',
      ),
    ];
  }

  // Sample ingredients data
  List<Ingredient> _getSampleIngredients() {
    return [
      // Vegetables
      Ingredient(id: '1', name: 'Tomatoes', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1546470427-e26264be0b0d?w=100&h=100&fit=crop'),
      Ingredient(id: '2', name: 'Onions', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=100&h=100&fit=crop'),
      Ingredient(id: '3', name: 'Garlic', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=100&h=100&fit=crop'),
      Ingredient(id: '4', name: 'Bell Peppers', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=100&h=100&fit=crop'),
      Ingredient(id: '5', name: 'Broccoli', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=100&h=100&fit=crop'),
      Ingredient(id: '6', name: 'Carrots', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1445282768818-728615cc910a?w=100&h=100&fit=crop'),
      Ingredient(id: '7', name: 'Cucumber', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=100&h=100&fit=crop'),
      Ingredient(id: '8', name: 'Lettuce', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=100&h=100&fit=crop'),
      Ingredient(id: '9', name: 'Mushrooms', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1518020382113-a7e8fc38eac9?w=100&h=100&fit=crop'),
      Ingredient(id: '10', name: 'Potatoes', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=100&h=100&fit=crop'),
      Ingredient(id: '11', name: 'Celery', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=100&h=100&fit=crop'),
      Ingredient(id: '12', name: 'Cabbage', category: 'Vegetables', imageUrl: 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=100&h=100&fit=crop'),
      
      // Proteins
      Ingredient(id: '13', name: 'Chicken Breast', category: 'Proteins', imageUrl: 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=100&h=100&fit=crop'),
      Ingredient(id: '14', name: 'Beef', category: 'Proteins', imageUrl: 'https://images.unsplash.com/photo-1588347818133-6b2e6d8b1c0e?w=100&h=100&fit=crop'),
      Ingredient(id: '15', name: 'Ground Beef', category: 'Proteins', imageUrl: 'https://images.unsplash.com/photo-1603048297172-c92544798d5a?w=100&h=100&fit=crop'),
      Ingredient(id: '16', name: 'Fish', category: 'Seafood', imageUrl: 'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=100&h=100&fit=crop'),
      Ingredient(id: '17', name: 'Eggs', category: 'Proteins', imageUrl: 'https://images.unsplash.com/photo-1518569656558-1f25e69d93d7?w=100&h=100&fit=crop'),
      Ingredient(id: '18', name: 'Pancetta', category: 'Proteins', imageUrl: 'https://images.unsplash.com/photo-1528207776546-365bb710ee93?w=100&h=100&fit=crop'),
      Ingredient(id: '19', name: 'Anchovies', category: 'Seafood', imageUrl: 'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=100&h=100&fit=crop'),
      
      // Dairy
      Ingredient(id: '20', name: 'Milk', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=100&h=100&fit=crop'),
      Ingredient(id: '21', name: 'Cheese', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=100&h=100&fit=crop'),
      Ingredient(id: '22', name: 'Parmesan Cheese', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1452195100486-9cc805987862?w=100&h=100&fit=crop'),
      Ingredient(id: '23', name: 'Feta Cheese', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=100&h=100&fit=crop'),
      Ingredient(id: '24', name: 'Butter', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=100&h=100&fit=crop'),
      Ingredient(id: '25', name: 'Yogurt', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1571212515416-fca0b8ba8c8b?w=100&h=100&fit=crop'),
      Ingredient(id: '26', name: 'Cream', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=100&h=100&fit=crop'),
      Ingredient(id: '27', name: 'Sour Cream', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1571212515416-fca0b8ba8c8b?w=100&h=100&fit=crop'),
      Ingredient(id: '28', name: 'Coconut Milk', category: 'Dairy', imageUrl: 'https://images.unsplash.com/photo-1520950237264-6b52ef1a8b3c?w=100&h=100&fit=crop'),
      
      // Grains
      Ingredient(id: '29', name: 'Rice', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=100&h=100&fit=crop'),
      Ingredient(id: '30', name: 'Pasta', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1551892374-ecf8754cf8b0?w=100&h=100&fit=crop'),
      Ingredient(id: '31', name: 'Spaghetti', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?w=100&h=100&fit=crop'),
      Ingredient(id: '32', name: 'Bread', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=100&h=100&fit=crop'),
      Ingredient(id: '33', name: 'Burger Buns', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=100&h=100&fit=crop'),
      Ingredient(id: '34', name: 'Tortillas', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=100&h=100&fit=crop'),
      Ingredient(id: '35', name: 'Quinoa', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=100&h=100&fit=crop'),
      Ingredient(id: '36', name: 'Flour', category: 'Grains', imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=100&h=100&fit=crop'),
      
      // Fruits
      Ingredient(id: '37', name: 'Avocado', category: 'Fruits', imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=100&h=100&fit=crop'),
      Ingredient(id: '38', name: 'Lemon', category: 'Fruits', imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=100&h=100&fit=crop'),
      Ingredient(id: '39', name: 'Lime', category: 'Fruits', imageUrl: 'https://images.unsplash.com/photo-1541544181051-e46607e4ac21?w=100&h=100&fit=crop'),
      
      // Spices & Herbs
      Ingredient(id: '40', name: 'Salt', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1472162314594-a27637f1bf5f?w=100&h=100&fit=crop'),
      Ingredient(id: '41', name: 'Black Pepper', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100&h=100&fit=crop'),
      Ingredient(id: '42', name: 'Spices', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=100&h=100&fit=crop'),
      Ingredient(id: '43', name: 'Thai Basil', category: 'Herbs', imageUrl: 'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?w=100&h=100&fit=crop'),
      Ingredient(id: '44', name: 'Cilantro', category: 'Herbs', imageUrl: 'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?w=100&h=100&fit=crop'),
      Ingredient(id: '45', name: 'Herbs', category: 'Herbs', imageUrl: 'https://images.unsplash.com/photo-1618375569909-3c8616cf7733?w=100&h=100&fit=crop'),
      Ingredient(id: '46', name: 'Vanilla', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=100&h=100&fit=crop'),
      Ingredient(id: '47', name: 'Baking Powder', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1472162314594-a27637f1bf5f?w=100&h=100&fit=crop'),
      Ingredient(id: '48', name: 'Baking Soda', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1472162314594-a27637f1bf5f?w=100&h=100&fit=crop'),
      
      // Oils & Condiments
      Ingredient(id: '49', name: 'Olive Oil', category: 'Oils', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=100&h=100&fit=crop'),
      Ingredient(id: '50', name: 'Oil', category: 'Oils', imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=100&h=100&fit=crop'),
      Ingredient(id: '51', name: 'Soy Sauce', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=100&h=100&fit=crop'),
      Ingredient(id: '52', name: 'Fish Sauce', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1563636619-e9143da7973b?w=100&h=100&fit=crop'),
      Ingredient(id: '53', name: 'Caesar Dressing', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1472162314594-a27637f1bf5f?w=100&h=100&fit=crop'),
      Ingredient(id: '54', name: 'Sugar', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=100&h=100&fit=crop'),
      Ingredient(id: '55', name: 'White Wine', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1510812431401-41d2bd2722f3?w=100&h=100&fit=crop'),
      Ingredient(id: '56', name: 'Vegetable Broth', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=100&h=100&fit=crop'),
      Ingredient(id: '57', name: 'Green Curry Paste', category: 'Condiments', imageUrl: 'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=100&h=100&fit=crop'),
      
      // Extras
      Ingredient(id: '58', name: 'Chocolate', category: 'Extras', imageUrl: 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=100&h=100&fit=crop'),
      Ingredient(id: '59', name: 'Chocolate Chips', category: 'Extras', imageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=100&h=100&fit=crop'),
      Ingredient(id: '60', name: 'Cocoa Powder', category: 'Extras', imageUrl: 'https://images.unsplash.com/photo-1606312619070-d48b4c652a52?w=100&h=100&fit=crop'),
      Ingredient(id: '61', name: 'Croutons', category: 'Extras', imageUrl: 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=100&h=100&fit=crop'),
      Ingredient(id: '62', name: 'Pickles', category: 'Extras', imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=100&h=100&fit=crop'),
      Ingredient(id: '63', name: 'Ginger', category: 'Spices', imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=100&h=100&fit=crop'),
    ];
  }

  // Get featured recipes (top-rated recipes)
  List<Recipe> getFeaturedRecipes({int limit = 6}) {
    final sortedRecipes = List<Recipe>.from(_allRecipes);
    sortedRecipes.sort((a, b) => b.rating.compareTo(a.rating));
    return sortedRecipes.take(limit).toList();
  }

  // Favorite recipes management
  bool isFavorited(String recipeId) {
    return _favoriteRecipes.any((recipe) => recipe.id == recipeId);
  }

  void addToFavorites(Recipe recipe) {
    if (!isFavorited(recipe.id)) {
      _favoriteRecipes.add(recipe);
      // Cache offline
      _cacheService.addToFavoriteRecipesCache(recipe);
    }
  }

  void removeFromFavorites(String recipeId) {
    _favoriteRecipes.removeWhere((recipe) => recipe.id == recipeId);
    // Update cache
    _cacheService.removeFromFavoriteRecipesCache(recipeId);
  }

  List<Recipe> getFavoriteRecipes() {
    return List<Recipe>.from(_favoriteRecipes);
  }

  // Saved recipes management
  bool isSaved(String recipeId) {
    return _savedRecipes.any((recipe) => recipe.id == recipeId);
  }

  void addToSaved(Recipe recipe) {
    if (!isSaved(recipe.id)) {
      _savedRecipes.add(recipe);
      // Cache offline
      _cacheService.addToSavedRecipesCache(recipe);
    }
  }

  void removeFromSaved(String recipeId) {
    _savedRecipes.removeWhere((recipe) => recipe.id == recipeId);
    // Update cache
    _cacheService.removeFromSavedRecipesCache(recipeId);
  }

  List<Recipe> getSavedRecipes() {
    return List<Recipe>.from(_savedRecipes);
  }

  // Update an existing recipe
  void updateRecipe(Recipe updatedRecipe) {
    final index = _allRecipes.indexWhere((recipe) => recipe.id == updatedRecipe.id);
    if (index != -1) {
      _allRecipes[index] = updatedRecipe;
      // Cache offline
      _cacheService.addToUserRecipesCache(updatedRecipe);
    }
  }

  // Add a new recipe
  void addRecipe(Recipe newRecipe) {
    _allRecipes.add(newRecipe);
    // Cache offline
    _cacheService.addToUserRecipesCache(newRecipe);
  }

  // Get next available ID for new recipes
  String getNextRecipeId() {
    if (_allRecipes.isEmpty) return '1';
    final maxId = _allRecipes.map((r) => int.tryParse(r.id) ?? 0).reduce((a, b) => a > b ? a : b);
    return (maxId + 1).toString();
  }

  // Offline-specific methods
  Future<bool> isOnline() async {
    return await _cacheService.isOnline();
  }

  Future<Map<String, dynamic>> getCacheStatus() async {
    return await _cacheService.getCacheStatus();
  }

  Future<List<Recipe>> searchOfflineRecipes(String query) async {
    return await _cacheService.searchCachedRecipes(query);
  }

  Future<void> syncUserDataWhenOnline() async {
    if (await isOnline()) {
      // Cache current data when online
      await _cacheService.cacheSavedRecipes(_savedRecipes);
      await _cacheService.cacheFavoriteRecipes(_favoriteRecipes);
      
      // Cache user created recipes
      final List<Recipe> userRecipes = _allRecipes.where((recipe) => 
        int.tryParse(recipe.id) != null && int.parse(recipe.id) > 15
      ).toList();
      await _cacheService.cacheUserRecipes(userRecipes);
    }
  }

  Future<void> clearUserCache() async {
    await _cacheService.clearUserCache();
    // Reload data
    _savedRecipes.clear();
    _favoriteRecipes.clear();
    await _loadCachedUserData();
  }
} 