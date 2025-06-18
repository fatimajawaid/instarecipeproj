import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/recipe_model.dart';
import '../services/recipe_data_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String from;
  final Recipe? recipe;

  const RecipeDetailScreen({
    super.key,
    required this.from,
    this.recipe,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late RecipeDataService _dataService;
  Recipe? _recipe;
  bool _isFavorited = false;
  bool _isSaved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dataService = RecipeDataService();
    _initializeRecipe();
  }

  void _initializeRecipe() {
    setState(() {
      _recipe = widget.recipe;
      if (_recipe != null) {
        _isFavorited = _dataService.isFavorited(_recipe!.id);
        _isSaved = _dataService.isSaved(_recipe!.id);
      }
      _isLoading = false;
    });
  }

  void _toggleFavorite() {
    if (_recipe == null) return;
    
    setState(() {
      _isFavorited = !_isFavorited;
      if (_isFavorited) {
        _dataService.addToFavorites(_recipe!);
      } else {
        _dataService.removeFromFavorites(_recipe!.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: ValueKey('favorite_snack_${_recipe!.id}_${DateTime.now().millisecondsSinceEpoch}'),
        content: Text(_isFavorited ? 'Added to favorites' : 'Removed from favorites'),
        backgroundColor: const Color(0xFFef6a42),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleSaved() {
    if (_recipe == null) return;
    
    setState(() {
      _isSaved = !_isSaved;
      if (_isSaved) {
        _dataService.addToSaved(_recipe!);
      } else {
        _dataService.removeFromSaved(_recipe!.id);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: ValueKey('saved_snack_${_recipe!.id}_${DateTime.now().millisecondsSinceEpoch}'),
        content: Text(_isSaved ? 'Recipe saved' : 'Recipe unsaved'),
        backgroundColor: const Color(0xFFef6a42),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Not Found'),
        ),
        body: const Center(
          child: Text('Recipe not found'),
        ),
      );
    }

    return Scaffold(
      key: ValueKey('recipe_detail_${_recipe!.id}'),
      body: CustomScrollView(
        slivers: [
          // App bar with recipe image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: IconButton(
              onPressed: () {
                // Use GoRouter for consistent navigation
                switch (widget.from) {
                  case 'my-recipes':
                    context.go('/my-recipes');
                    break;
                  case 'recipes':
                    context.go('/recipes');
                    break;
                  case 'saved':
                    context.go('/saved');
                    break;
                  case 'search':
                    context.go('/search');
                    break;
                  default:
                    context.go('/home');
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _recipe!.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.restaurant,
                          size: 80,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorited ? Colors.red : Colors.white,
                ),
              ),
              IconButton(
                onPressed: _toggleSaved,
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? const Color(0xFFef6a42) : Colors.white,
                ),
              ),
            ],
          ),
          
          // Recipe content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recipe title and basic info
                  Text(
                    _recipe!.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    _recipe!.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recipe metadata
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.access_time,
                        _recipe!.formattedCookingTime,
                        Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.people,
                        '${_recipe!.servings} servings',
                        Colors.green,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoChip(
                        Icons.local_fire_department,
                        '${_recipe!.calories} cal',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating and difficulty
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _recipe!.rating.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _recipe!.difficultyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _recipe!.difficultyColor),
                        ),
                        child: Text(
                          _recipe!.difficulty,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _recipe!.difficultyColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFef6a42).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFef6a42)),
                        ),
                        child: Text(
                          _recipe!.cuisine,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFef6a42),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Dietary tags
                  if (_recipe!.dietaryTags.isNotEmpty) ...[
                    const Text(
                      'Dietary Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recipe!.dietaryTags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.green.withOpacity(0.1),
                        side: const BorderSide(color: Colors.green),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Ingredients section
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_recipe!.ingredients.map((ingredient) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFef6a42),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ingredient,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ))),
                  const SizedBox(height: 24),
                  
                  // Instructions section
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...(_recipe!.instructions.asMap().entries.map((entry) {
                    int index = entry.key;
                    String instruction = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFef6a42),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              instruction,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    );
                  })),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
} 