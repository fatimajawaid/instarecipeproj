import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_navigation.dart';
import '../services/recipe_data_service.dart';
import '../models/recipe_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RecipeDataService _dataService = RecipeDataService();
  final PageController _pageController = PageController();
  List<Recipe> _featuredRecipes = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadFeaturedRecipes();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadFeaturedRecipes() {
    setState(() {
      // Get top-rated recipes for featured section
      _featuredRecipes = _dataService.getAllRecipes()
          .where((recipe) => recipe.rating >= 4.5)
          .take(6)
          .toList();
      _isLoading = false;
    });
    
    // Start auto-scroll timer after recipes are loaded
    if (_featuredRecipes.isNotEmpty) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _featuredRecipes.isNotEmpty) {
        _currentPage = (_currentPage + 1) % _featuredRecipes.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfcf9f8),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    color: const Color(0xFFfcf9f8),
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          const SizedBox(width: 48), // Space for centering
                          Expanded(
                            child: Text(
                              'InstaRecipe',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1b110d),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.015,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: IconButton(
                              onPressed: () => context.go('/profile'),
                              icon: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF1b110d),
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: GestureDetector(
                      onTap: () => context.go('/search'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFf3eae7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 16, right: 8),
                              child: Icon(
                                Icons.search,
                                color: Color(0xFF9a5e4c),
                                size: 24,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                "What's in your kitchen?",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF9a5e4c),
                                  fontSize: 16,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Featured Recipes
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Recipes',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF1b110d),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.015,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/recipes'),
                          child: Text(
                            'See All',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFef6a42),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (_isLoading)
                    const SizedBox(
                      height: 320,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xFFef6a42)),
                      ),
                    )
                  else
                    _buildFeaturedRecipes(),

                  // Quick Access
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 20),
                    child: Text(
                      'Quick Access',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1b110d),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.015,
                      ),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.5,
                      children: [
                        _buildQuickAccessCard(
                          context,
                          Icons.calendar_month,
                          'Meal Planner',
                          onTap: () => context.go('/meal-plan'),
                        ),
                        _buildQuickAccessCard(
                          context,
                          Icons.favorite_border,
                          'Favorites',
                          onTap: () => context.go('/saved'),
                        ),
                        _buildQuickAccessCard(
                          context,
                          Icons.menu_book,
                          'My Recipes',
                          onTap: () => context.go('/my-recipes'),
                        ),
                        _buildQuickAccessCard(
                          context,
                          Icons.add_circle_outline,
                          'Create Recipe',
                          onTap: () => context.go('/create-recipe'),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentRoute: '/home'),
    );
  }

  Widget _buildFeaturedRecipes() {
    return SizedBox(
      height: 280,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemCount: _featuredRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _featuredRecipes[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _navigateToRecipeDetail(recipe),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background image
                      Container(
                        height: double.infinity,
                        width: double.infinity,
                        child: Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.restaurant,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
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
                            stops: const [0.4, 1.0],
                          ),
                        ),
                      ),
                      
                      // Recipe content
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Recipe name
                              Text(
                                recipe.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              
                              // Recipe description
                              Text(
                                recipe.description,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              
                              // Recipe metadata
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          recipe.formattedCookingTime,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          recipe.rating.toString(),
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: recipe.difficultyColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      recipe.difficulty,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
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
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToRecipeDetail(Recipe recipe) {
    context.go('/recipe-detail?from=home', extra: {'recipe': recipe});
  }

  Widget _buildQuickAccessCard(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFf3eae7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFe4d7d3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFFef6a42),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF1b110d),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 