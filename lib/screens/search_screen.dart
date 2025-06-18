import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_navigation.dart';
import '../services/recipe_data_service.dart';
import '../models/ingredient_model.dart';
import '../models/recipe_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final RecipeDataService _dataService = RecipeDataService();
  
  late TabController _tabController;
  bool _isOnline = true;
  List<IngredientCategory> _ingredientCategories = [];
  List<String> _selectedIngredients = [];
  List<Recipe> _matchedRecipes = [];
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showRecipes = false;

  // Filter states for generated recipes
  List<String> _selectedDietFilters = [];
  String _selectedSortFilter = 'Relevance';
  String _selectedCuisine = 'All';
  String _selectedDifficulty = 'All';

  // Filter options
  final List<String> _dietFilters = ['Vegetarian', 'Vegan', 'Gluten-Free'];
  final List<String> _sortFilters = ['Relevance', 'Cooking Time', 'Difficulty Level', 'Rating', 'Popularity', 'Newest'];
  final List<String> _cuisineFilters = ['All', 'Italian', 'Asian', 'Indian', 'Mediterranean', 'American', 'International', 'Thai', 'Mexican'];
  final List<String> _difficultyFilters = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _dataService.initializeData();
    
    // Check connectivity
    final bool online = await _dataService.isOnline();
    
    setState(() {
      _isOnline = online;
      _ingredientCategories = _dataService.getIngredientCategories();
      _tabController = TabController(length: _ingredientCategories.length, vsync: this);
      _isLoading = false;
    });
  }

  void _toggleIngredient(String ingredientName) {
    setState(() {
      if (_selectedIngredients.contains(ingredientName)) {
        _selectedIngredients.remove(ingredientName);
      } else {
        _selectedIngredients.add(ingredientName);
      }
      _dataService.updateSelectedIngredients(_selectedIngredients);
    });
  }

  void _generateRecipes() {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one ingredient'),
          backgroundColor: Color(0xFFef6a42),
        ),
      );
      return;
    }

    setState(() {
      _matchedRecipes = _dataService.getRecipesWithMatching(
        selectedIngredients: _selectedIngredients,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        dietaryFilters: _selectedDietFilters.isNotEmpty ? _selectedDietFilters : null,
        sortBy: _selectedSortFilter,
        cuisine: _selectedCuisine,
        difficulty: _selectedDifficulty,
      );
      _showRecipes = true;
    });
  }

  void _applyRecipeFilters() {
    setState(() {
      _matchedRecipes = _dataService.getRecipesWithMatching(
        selectedIngredients: _selectedIngredients,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        dietaryFilters: _selectedDietFilters.isNotEmpty ? _selectedDietFilters : null,
        sortBy: _selectedSortFilter,
        cuisine: _selectedCuisine,
        difficulty: _selectedDifficulty,
      );
    });
  }

  void _clearRecipeFilters() {
    setState(() {
      _selectedDietFilters.clear();
      _selectedSortFilter = 'Relevance';
      _selectedCuisine = 'All';
      _selectedDifficulty = 'All';
      _applyRecipeFilters();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIngredients.clear();
      _showRecipes = false;
      _matchedRecipes.clear();
      _dataService.updateSelectedIngredients(_selectedIngredients);
    });
  }

  List<Ingredient> _getFilteredIngredients(List<Ingredient> ingredients) {
    if (_searchQuery.isEmpty) return ingredients;
    return ingredients.where((ingredient) => 
        ingredient.matchesSearch(_searchQuery)).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFfcf9f8),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFef6a42)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF1b110d)),
                  ),
                  Expanded(
                    child: Text(
                      _showRecipes ? 'Recipe Suggestions' : 'Select Ingredients',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1b110d),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (_showRecipes)
                    IconButton(
                      onPressed: () => setState(() => _showRecipes = false),
                      icon: const Icon(Icons.edit, color: Color(0xFF1b110d)),
                    )
                  else
                    Row(
                      children: [
                        if (!_isOnline)
                          IconButton(
                            onPressed: () => context.go('/offline-search'),
                            icon: Icon(
                              Icons.cloud_off,
                              color: Colors.orange[700],
                            ),
                            tooltip: 'Search Offline',
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                ],
              ),
            ),

            // Offline indicator
            if (!_isOnline)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'re offline. Tap the cloud icon to search cached recipes.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_showRecipes) ...[
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFf3eae7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Icon(Icons.search, color: Color(0xFF9a5e4c)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => _searchQuery = value),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1b110d),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: "Search ingredients...",
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF9a5e4c),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Selected ingredients
              if (_selectedIngredients.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(
                    minHeight: 50,
                    maxHeight: 120,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Selected (${_selectedIngredients.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1b110d),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedIngredients.map((ingredient) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFef6a42),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      ingredient,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _toggleIngredient(ingredient),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close, 
                                          color: Colors.white, 
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Category tabs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: const Color(0xFFef6a42),
                  unselectedLabelColor: const Color(0xFF8d6658),
                  indicatorColor: const Color(0xFFef6a42),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: _ingredientCategories.map((category) => 
                    Tab(text: '${category.icon} ${category.name}')).toList(),
                ),
              ),

              // Ingredients grid
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _ingredientCategories.map((category) {
                    List<Ingredient> filteredIngredients = _getFilteredIngredients(category.ingredients);
                    
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredIngredients.length,
                      itemBuilder: (context, index) {
                        Ingredient ingredient = filteredIngredients[index];
                        bool isSelected = _selectedIngredients.contains(ingredient.name);
                        
                        return GestureDetector(
                          onTap: () => _toggleIngredient(ingredient.name),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFef6a42) : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(ingredient.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  ingredient.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF1b110d),
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFFef6a42),
                                    size: 16,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),

              // Generate recipes button
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_selectedIngredients.isNotEmpty)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clearSelection,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFef6a42)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Clear All',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFef6a42),
                            ),
                          ),
                        ),
                      ),
                    if (_selectedIngredients.isNotEmpty) const SizedBox(width: 12),
                    Expanded(
                      flex: _selectedIngredients.isNotEmpty ? 2 : 1,
                      child: ElevatedButton(
                        onPressed: _generateRecipes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef6a42),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _selectedIngredients.isEmpty 
                              ? 'Select Ingredients' 
                              : 'Generate Recipes (${_selectedIngredients.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Recipe results
              Expanded(
                child: _matchedRecipes.isEmpty
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
                              'Try selecting different ingredients',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF8d6658),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildRecipeResults(),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigation(currentRoute: '/search'),
    );
  }

  Widget _buildRecipeResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter section
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recipe Results (${_matchedRecipes.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _clearRecipeFilters,
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Sort filter
                    FilterChip(
                      label: Text('Sort: $_selectedSortFilter'),
                      selected: _selectedSortFilter != 'Relevance',
                      onSelected: (_) => _showSortDialog(),
                    ),
                    const SizedBox(width: 8),
                    
                    // Cuisine filter
                    FilterChip(
                      label: Text('Cuisine: $_selectedCuisine'),
                      selected: _selectedCuisine != 'All',
                      onSelected: (_) => _showCuisineDialog(),
                    ),
                    const SizedBox(width: 8),
                    
                    // Difficulty filter
                    FilterChip(
                      label: Text('Difficulty: $_selectedDifficulty'),
                      selected: _selectedDifficulty != 'All',
                      onSelected: (_) => _showDifficultyDialog(),
                    ),
                    const SizedBox(width: 8),
                    
                    // Diet filters
                    ...(_selectedDietFilters.map((diet) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(diet),
                        selected: true,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDietFilters.remove(diet);
                            _applyRecipeFilters();
                          });
                        },
                      ),
                    ))),
                    
                    // Add diet filter button
                    ActionChip(
                      label: const Text('+ Diet'),
                      onPressed: _showDietDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Recipe grid
        Expanded(
          child: _matchedRecipes.isEmpty
              ? const Center(
                  child: Text(
                    'No recipes found with selected ingredients and filters',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _matchedRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _matchedRecipes[index];
                    return _buildRecipeCard(recipe);
                  },
                ),
        ),
      ],
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _sortFilters.map((sort) => RadioListTile<String>(
            title: Text(sort),
            value: sort,
            groupValue: _selectedSortFilter,
            onChanged: (value) {
              setState(() {
                _selectedSortFilter = value!;
                _applyRecipeFilters();
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showCuisineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cuisine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _cuisineFilters.map((cuisine) => RadioListTile<String>(
            title: Text(cuisine),
            value: cuisine,
            groupValue: _selectedCuisine,
            onChanged: (value) {
              setState(() {
                _selectedCuisine = value!;
                _applyRecipeFilters();
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDifficultyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _difficultyFilters.map((difficulty) => RadioListTile<String>(
            title: Text(difficulty),
            value: difficulty,
            groupValue: _selectedDifficulty,
            onChanged: (value) {
              setState(() {
                _selectedDifficulty = value!;
                _applyRecipeFilters();
              });
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showDietDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dietary Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _dietFilters.map((diet) => CheckboxListTile(
            title: Text(diet),
            value: _selectedDietFilters.contains(diet),
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _selectedDietFilters.add(diet);
                } else {
                  _selectedDietFilters.remove(diet);
                }
              });
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyRecipeFilters();
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => context.go('/recipe-detail?from=search', extra: {'recipe': recipe}),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Recipe details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe name
                    Text(
                      recipe.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Match percentage if available
                    if (recipe.ingredientMatchText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          recipe.ingredientMatchText!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Recipe metadata
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              recipe.formattedCookingTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            recipe.rating.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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
} 