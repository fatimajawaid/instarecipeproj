import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/recipe_data_service.dart';
import '../models/recipe_model.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeDataService _dataService = RecipeDataService();
  
  bool isGridView = true;
  List<Recipe> _allRecipes = [];
  List<Recipe> _filteredRecipes = [];
  
  // Filter states
  List<String> selectedDietFilters = [];
  String selectedSortFilter = 'Relevance';
  String selectedCuisine = 'All';
  String selectedDifficulty = 'All';
  
  // Filter options
  final List<String> dietFilters = ['Vegetarian', 'Vegan', 'Gluten-Free'];
  final List<String> sortFilters = ['Relevance', 'Cooking Time', 'Difficulty Level', 'Rating', 'Popularity', 'Newest'];
  final List<String> cuisineFilters = ['All', 'Italian', 'Asian', 'Indian', 'Mediterranean', 'American', 'International'];
  final List<String> difficultyFilters = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() {
    setState(() {
      _allRecipes = _dataService.getAllRecipes();
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRecipes = _dataService.getRecipesWithMatching(
        selectedIngredients: [], // Empty list since we're not doing ingredient matching in all recipes
        dietaryFilters: selectedDietFilters.isNotEmpty ? selectedDietFilters : null,
        sortBy: selectedSortFilter,
        cuisine: selectedCuisine,
        difficulty: selectedDifficulty,
      );
    });
  }

  void _toggleDietFilter(String filter) {
    setState(() {
      if (selectedDietFilters.contains(filter)) {
        selectedDietFilters.remove(filter);
      } else {
        selectedDietFilters.add(filter);
      }
      _applyFilters();
    });
  }

  void _clearAllFilters() {
    setState(() {
      selectedDietFilters.clear();
      selectedSortFilter = 'Relevance';
      selectedCuisine = 'All';
      selectedDifficulty = 'All';
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFfcf9f8),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1b110d)),
                  ),
                  Expanded(
                    child: Text(
                      'All Recipes (${_filteredRecipes.length})',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1b110d),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => isGridView = !isGridView),
                    icon: Icon(
                      isGridView ? Icons.view_list : Icons.grid_view,
                      color: const Color(0xFF1b110d),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Sort filter
                      _buildFilterChip(
                        'Sort: $selectedSortFilter',
                        true,
                        onTap: () => _showSortDialog(),
                      ),
                      const SizedBox(width: 8),
                      
                      // Cuisine filter
                      _buildFilterChip(
                        'Cuisine: $selectedCuisine',
                        selectedCuisine != 'All',
                        onTap: () => _showCuisineDialog(),
                      ),
                      const SizedBox(width: 8),
                      
                      // Difficulty filter
                      _buildFilterChip(
                        'Difficulty: $selectedDifficulty',
                        selectedDifficulty != 'All',
                        onTap: () => _showDifficultyDialog(),
                      ),
                      const SizedBox(width: 8),
                      
                      // Diet filters
                      ...selectedDietFilters.map((filter) => 
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            filter,
                            true,
                            onTap: () => _toggleDietFilter(filter),
                            showClose: true,
                          ),
                        ),
                      ),
                      
                      // Add diet filter button
                      _buildFilterChip(
                        '+ Diet',
                        false,
                        onTap: () => _showDietDialog(),
                      ),
                    ],
                  ),
                ),
                
                // Clear filters button
                if (selectedDietFilters.isNotEmpty || 
                    selectedCuisine != 'All' || 
                    selectedDifficulty != 'All' ||
                    selectedSortFilter != 'Relevance')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: GestureDetector(
                      onTap: _clearAllFilters,
                      child: Text(
                        'Clear all filters',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFef6a42),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Recipes List/Grid
          Expanded(
            child: _filteredRecipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Color(0xFF8d6658),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No recipes found',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1b110d),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: const Color(0xFF8d6658),
                          ),
                        ),
                      ],
                    ),
                  )
                : isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredRecipes.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeGridCard(_filteredRecipes[index]);
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRecipes.length,
                        itemBuilder: (context, index) {
                          return _buildRecipeListCard(_filteredRecipes[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isActive, {VoidCallback? onTap, bool showClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFef6a42) : const Color(0xFFf3eae7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFFef6a42) : const Color(0xFFe4d7d3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF8d6658),
              ),
            ),
            if (showClose) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 14,
                color: isActive ? Colors.white : const Color(0xFF8d6658),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGridCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => context.go('/recipe-detail?from=recipes', extra: {'recipe': recipe}),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  image: DecorationImage(
                    image: NetworkImage(recipe.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Rating badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              recipe.rating.toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Recipe Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1b110d),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Add description
                    Expanded(
                      child: Text(
                        recipe.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF8d6658),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: const Color(0xFF8d6658)),
                        const SizedBox(width: 2),
                        Text(
                          recipe.formattedCookingTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFF8d6658),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: recipe.difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            recipe.difficulty,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: recipe.difficultyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeListCard(Recipe recipe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
                    child: InkWell(
                onTap: () => context.go('/recipe-detail?from=recipes', extra: {'recipe': recipe}),
                borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Recipe Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(recipe.imageUrl),
                    fit: BoxFit.cover,
                  ),
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
                        fontSize: 12,
                        color: const Color(0xFF8d6658),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: const Color(0xFF8d6658)),
                        const SizedBox(width: 4),
                        Text(
                          recipe.formattedCookingTime,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF8d6658),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          recipe.rating.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFF8d6658),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: recipe.difficultyColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            recipe.difficulty,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: recipe.difficultyColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Sort by',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sortFilters.map((filter) => 
            RadioListTile<String>(
              title: Text(filter, style: GoogleFonts.plusJakartaSans()),
              value: filter,
              groupValue: selectedSortFilter,
              onChanged: (value) {
                setState(() {
                  selectedSortFilter = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  void _showCuisineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Cuisine',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cuisineFilters.map((cuisine) => 
            RadioListTile<String>(
              title: Text(cuisine, style: GoogleFonts.plusJakartaSans()),
              value: cuisine,
              groupValue: selectedCuisine,
              onChanged: (value) {
                setState(() {
                  selectedCuisine = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Difficulty',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: difficultyFilters.map((difficulty) => 
            RadioListTile<String>(
              title: Text(difficulty, style: GoogleFonts.plusJakartaSans()),
              value: difficulty,
              groupValue: selectedDifficulty,
              onChanged: (value) {
                setState(() {
                  selectedDifficulty = value!;
                  _applyFilters();
                });
                Navigator.pop(context);
              },
            ),
          ).toList(),
        ),
      ),
    );
  }

  void _showDietDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Dietary Preferences',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: dietFilters.map((filter) => 
            CheckboxListTile(
              title: Text(filter, style: GoogleFonts.plusJakartaSans()),
              value: selectedDietFilters.contains(filter),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedDietFilters.add(filter);
                  } else {
                    selectedDietFilters.remove(filter);
                  }
                });
              },
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _applyFilters();
              Navigator.pop(context);
            },
            child: Text(
              'Apply',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFef6a42),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 