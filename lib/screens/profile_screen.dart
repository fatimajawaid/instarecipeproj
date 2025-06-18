import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/bottom_navigation.dart';
import '../services/recipe_data_service.dart';
import '../services/auth_service.dart';
import '../models/recipe_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late RecipeDataService _dataService;
  List<Recipe> _myRecipes = [];

  @override
  void initState() {
    super.initState();
    _dataService = RecipeDataService();
    _loadMyRecipes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh recipes when screen gains focus
    _loadMyRecipes();
  }

  void _loadMyRecipes() {
    final allRecipes = _dataService.getAllRecipes();
    setState(() {
      // Get the same recipes as shown in My Recipes screen, but get fresh data
      _myRecipes = allRecipes.where((recipe) => 
        ['11', '15', '3', '8'].contains(recipe.id) || 
        int.tryParse(recipe.id) != null && int.parse(recipe.id) > 15 // Include newly created recipes
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfbf9f9),
      body: Column(
        children: [
          // Header
          Container(
            color: const Color(0xFFfbf9f9),
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const SizedBox(width: 48), // Space for centering
                  Expanded(
                    child: Text(
                      'Profile',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF191210),
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
                    child: PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.settings,
                        color: Color(0xFF191210),
                        size: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: const Color(0xFFfcf9f8),
                      onSelected: (String value) async {
                        if (value == 'logout') {
                          // Show confirmation dialog
                          bool? shouldLogout = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFfcf9f8),
                              title: Text(
                                'Logout',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1b110d),
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to logout?',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1b110d),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8d6658),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Logout',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFef6a42),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldLogout == true) {
                            try {
                              await AuthService().signOut();
                              if (mounted) {
                                context.go('/');
                              }
                            } catch (e) {
                              if (mounted) {
                                AuthService.showErrorDialog(context, e.toString());
                              }
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.logout,
                                color: Color(0xFFef6a42),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Logout',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1b110d),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Picture
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuB6kSWZeCATDr6sfjBivDd4UeXeTJVsqrcu5Jtq8oFb0G4jnheq2EhRF_9I-po3fKrIe47G3tuHCUQCk33oVAeaA_IeIEUwCEFwEyU09vW_EtmDG-4HOplApuBmL24ruGM7e0gctVv2aiO28uftm7KDPd0RNeAAucO_auiGb8--LDsKelj4ZB-nvzoM3thuzxYwL2CUHef0BQnrto2xU-UR8TlQOwevyZeZtkjPbIOpGgcI0SAOOYeyN03Hh-pFM3NCMvIldDAvD8c',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // User Info
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              AuthService().userName ?? 'Recipe Lover',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF191210),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.015,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AuthService().userEmail ?? 'user@example.com',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF8d6658),
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Foodie & Recipe Enthusiast',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF8d6658),
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Meal Plans Section (moved to first)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
                    child: GestureDetector(
                      onTap: () => context.go('/meal-plan'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Meal Plans',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF191210),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.015,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF8d6658),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Meal Plan Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () => context.go('/meal-plan'),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFfbf9f9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFe4d7d3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upcoming',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8d6658),
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Week of July 15th',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF191210),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '5 recipes · 3 days',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8d6658),
                                      fontSize: 14,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDirkL51okkLe5C0IuI_hc0p4LR82IQ_Prsm_6iL6OIQqxTA-gES8vT78v9vXwcV-wwid3eXxRFB3uOWWMfvA7c2u73vV937LsOgwgMKZWKrTtFFEbX2V6-9jI-1vKboZOhF14_7JmzQBPwSisjqazrdd-vom92MrfmA3GIuVYAQqgq1eNajjOeDTbHb2cMshQJhTqHlruP8vO0UWM-18fAn6jBhMm5-Sqn2vqwT3decpYi4GB40a3eyxxXI7CLrg7aj3o-eRiMvZg',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // My Recipes Section (moved to second, renamed from Saved Recipes)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 16),
                    child: GestureDetector(
                      onTap: () => context.go('/my-recipes'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Recipes',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF191210),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.015,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFF8d6658),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // My Recipes Grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: _myRecipes.map((recipe) => _buildMyRecipeCard(context, recipe)).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigation(currentRoute: '/profile'),
    );
  }

  Widget _buildMyRecipeCard(BuildContext context, Recipe recipe) {
    return GestureDetector(
      onTap: () => context.go('/recipe-detail?from=profile', extra: {'recipe': recipe}),
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
} 