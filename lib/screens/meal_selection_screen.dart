import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe_model.dart';
import '../services/recipe_data_service.dart';
import '../services/meal_plan_service.dart';
import 'package:intl/intl.dart';

class MealSelectionScreen extends StatefulWidget {
  final DateTime date;
  final String mealType;

  const MealSelectionScreen({
    super.key,
    required this.date,
    required this.mealType,
  });

  @override
  State<MealSelectionScreen> createState() => _MealSelectionScreenState();
}

class _MealSelectionScreenState extends State<MealSelectionScreen> {
  final RecipeDataService _recipeService = RecipeDataService();
  final MealPlanService _mealPlanService = MealPlanService();
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<String> get _categories {
    List<String> baseCategories = ['All'];
    
    // Add relevant categories based on meal type
    switch (widget.mealType.toLowerCase()) {
      case 'breakfast':
        baseCategories.addAll(['Breakfast', 'Light']);
        break;
      case 'lunch':
        baseCategories.addAll(['Lunch', 'Salad', 'Soup', 'Light']);
        break;
      case 'dinner':
        baseCategories.addAll(['Dinner', 'Main Course', 'Heavy']);
        break;
      case 'snacks':
        baseCategories.addAll(['Snack', 'Dessert', 'Light']);
        break;
      default:
        baseCategories.addAll(['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert']);
    }
    
    return baseCategories;
  }

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    _allRecipes = _recipeService.getAllRecipes();
    _filterRecipes();
  }

  void _filterRecipes() {
    setState(() {
      _filteredRecipes = _allRecipes.where((recipe) {
        bool matchesSearch = _searchQuery.isEmpty ||
            recipe.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            recipe.description.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesCategory = _selectedCategory == 'All' ||
            _isCategoryMatch(recipe.category, _selectedCategory);

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  bool _isCategoryMatch(String recipeCategory, String filterCategory) {
    String recipeCat = recipeCategory.toLowerCase();
    String filterCat = filterCategory.toLowerCase();
    
    // Direct match
    if (recipeCat == filterCat) return true;
    
    // Map recipe categories to meal types and filter categories
    switch (filterCat) {
      case 'breakfast':
        return recipeCat == 'breakfast';
      case 'lunch':
        return recipeCat == 'lunch' || recipeCat == 'salad' || recipeCat == 'soup';
      case 'dinner':
        return recipeCat == 'main course' || recipeCat == 'dinner';
      case 'main course':
        return recipeCat == 'main course' || recipeCat == 'dinner';
      case 'snack':
        return recipeCat == 'snack' || recipeCat == 'dessert';
      case 'dessert':
        return recipeCat == 'dessert';
      case 'salad':
        return recipeCat == 'salad';
      case 'soup':
        return recipeCat == 'soup';
      case 'light':
        return recipeCat == 'breakfast' || recipeCat == 'salad' || 
               recipeCat == 'soup' || recipeCat == 'snack';
      case 'heavy':
        return recipeCat == 'main course' || recipeCat == 'dinner';
      default:
        return false;
    }
  }

  void _addRecipeToMealPlan(Recipe recipe) {
    _mealPlanService.addMealToDate(
      date: widget.date,
      recipe: recipe,
      mealType: widget.mealType,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${recipe.name} added to ${widget.mealType}'),
        backgroundColor: const Color(0xFFef6a42),
        duration: const Duration(seconds: 2),
      ),
    );

    // Go back to meal plan screen
    context.go('/meal-plan');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/meal-plan'),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1b110d),
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Add ${widget.mealType.toUpperCase()}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1b110d),
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMM d').format(widget.date),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF9a5e4c),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFf3eae7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: (value) {
                  _searchQuery = value;
                  _filterRecipes();
                },
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF1b110d),
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF9a5e4c),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  icon: const Icon(
                    Icons.search,
                    color: Color(0xFF9a5e4c),
                    size: 20,
                  ),
                ),
              ),
            ),

            // Category Filter
            Container(
              height: 50,
              margin: const EdgeInsets.only(top: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  String category = _categories[index];
                  bool isSelected = category == _selectedCategory;
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text(category),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : const Color(0xFF1b110d),
                        fontWeight: FontWeight.w500,
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFFef6a42),
                      backgroundColor: const Color(0xFFf3eae7),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        _filterRecipes();
                      },
                    ),
                  );
                },
              ),
            ),

            // Recipe List
            Expanded(
              child: _filteredRecipes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: const Color(0xFF9a5e4c).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No recipes found',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9a5e4c),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or category filter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: const Color(0xFF9a5e4c),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredRecipes.length,
                      itemBuilder: (context, index) {
                        Recipe recipe = _filteredRecipes[index];
                        return _buildRecipeCard(recipe);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _addRecipeToMealPlan(recipe),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Recipe Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  recipe.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFf3eae7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Color(0xFF9a5e4c),
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // Recipe Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1b110d),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: const Color(0xFF9a5e4c),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: const Color(0xFF9a5e4c),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.cookingTimeMinutes} min',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF9a5e4c),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: const Color(0xFF9a5e4c),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.calories} cal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF9a5e4c),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Add Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFef6a42),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 