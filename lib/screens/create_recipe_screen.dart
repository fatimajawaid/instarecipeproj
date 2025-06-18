import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe_model.dart';
import '../services/recipe_data_service.dart';
import '../services/image_upload_service.dart';

class CreateRecipeScreen extends StatefulWidget {
  final Recipe? recipe; // Add recipe parameter for editing
  
  const CreateRecipeScreen({
    super.key,
    this.recipe,
  });

  @override
  State<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends State<CreateRecipeScreen> {
  late RecipeDataService _dataService;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _cookingTimeController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  
  String _selectedDifficulty = 'Difficulty Level';
  String _selectedCuisine = 'Cuisine Type';
  String _selectedCategory = 'Category';
  List<String> _selectedDietaryTags = [];
  
  // Image upload variables
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _imageUrl;
  bool _isUploadingImage = false;
  
  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    _dataService = RecipeDataService();
    if (_isEditing) {
      _prefillFields();
    }
  }

  void _prefillFields() {
    final recipe = widget.recipe!;
    _titleController.text = recipe.name;
    _descriptionController.text = recipe.description;
    _ingredientsController.text = recipe.ingredients.join('\n');
    _instructionsController.text = recipe.instructions.join('\n');
    _cookingTimeController.text = recipe.cookingTimeMinutes.toString();
    _servingsController.text = recipe.servings.toString();
    _caloriesController.text = recipe.calories.toString();
    _selectedDifficulty = recipe.difficulty;
    _selectedCuisine = recipe.cuisine;
    _selectedCategory = recipe.category;
    _selectedDietaryTags = List.from(recipe.dietaryTags);
    _imageUrl = recipe.imageUrl; // Set existing image URL
  }

  // Handle image selection
  void _handleImageSelection(XFile? image) async {
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _cookingTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfbf9f9),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () {
                        context.go('/my-recipes');
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF191210),
                        size: 24,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Text(
                        _isEditing ? 'Edit Recipe' : 'Create Recipe',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191210),
                          letterSpacing: -0.015,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Title
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: TextField(
                        controller: _titleController,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF191210),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Recipe Title',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8d6658),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFf1ebe9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                    
                    // Recipe Image Upload Section
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recipe Image',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF191210),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              ImageUploadService.showImageSourceDialog(
                                context: context,
                                onImageSelected: _handleImageSelection,
                              );
                            },
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFf1ebe9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF8d6658).withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: _selectedImageBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        _selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : _imageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            _imageUrl!,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const Center(child: CircularProgressIndicator());
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    size: 48,
                                                    color: Color(0xFF8d6658),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Tap to add recipe image',
                                                    style: TextStyle(
                                                      color: Color(0xFF8d6658),
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        )
                                      : const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.camera_alt,
                                              size: 48,
                                              color: Color(0xFF8d6658),
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Tap to add recipe image',
                                              style: TextStyle(
                                                color: Color(0xFF8d6658),
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Description
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF191210),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Description',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8d6658),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFf1ebe9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    // Recipe Details Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Cooking Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cooking Time (min)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF191210),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _cookingTimeController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF191210),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '30',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8d6658),
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFf1ebe9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Servings
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Servings',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF191210),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _servingsController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF191210),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '4',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8d6658),
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFf1ebe9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dropdowns Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Difficulty Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Difficulty',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF191210),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedDifficulty,
                                  items: ['Easy', 'Medium', 'Hard'],
                                  onChanged: (value) => setState(() => _selectedDifficulty = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Cuisine Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cuisine',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF191210),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedCuisine,
                                  items: ['Italian', 'Asian', 'Mexican', 'American', 'Mediterranean', 'Indian', 'French'],
                                  onChanged: (value) => setState(() => _selectedCuisine = value),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Category and Calories Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          // Category Dropdown
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF191210),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdown(
                                  value: _selectedCategory,
                                  items: ['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'],
                                  onChanged: (value) => setState(() => _selectedCategory = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Calories
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Calories',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF191210),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _caloriesController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF191210),
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '250',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF8d6658),
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFf1ebe9),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dietary Tags Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Dietary Tags',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191210),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Vegetarian', 'Vegan', 'Gluten-Free', 'Dairy-Free', 'Low-Carb', 'Keto', 'Paleo']
                            .map((tag) => FilterChip(
                                  label: Text(tag),
                                  selected: _selectedDietaryTags.contains(tag),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedDietaryTags.add(tag);
                                      } else {
                                        _selectedDietaryTags.remove(tag);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(0xFFef6a42).withOpacity(0.2),
                                  checkmarkColor: const Color(0xFFef6a42),
                                ))
                            .toList(),
                      ),
                    ),
                    
                    // Ingredients Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Ingredients',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191210),
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: TextField(
                        controller: _ingredientsController,
                        maxLines: 5,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF191210),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'List ingredients (one per line)\ne.g., 2 cups flour\n1 tsp salt',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8d6658),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFf1ebe9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    // Instructions Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Instructions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF191210),
                        ),
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: TextField(
                        controller: _instructionsController,
                        maxLines: 6,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF191210),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Step-by-step instructions (one per line)\ne.g., 1. Preheat oven to 350°F\n2. Mix dry ingredients...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF8d6658),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFf1ebe9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    // Save Button
                    Container(
                      padding: const EdgeInsets.all(16),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploadingImage ? null : _saveRecipe,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFef6a42),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isUploadingImage
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Saving...',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                _isEditing ? 'Update Recipe' : 'Save Recipe',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFf1ebe9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: items.contains(value) ? value : null,
        isExpanded: true,
        underline: const SizedBox(),
        hint: Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF8d6658),
            fontSize: 16,
          ),
        ),
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF191210),
          fontSize: 16,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  void _saveRecipe() async {
    // Prevent multiple saves
    if (_isUploadingImage) return;
    
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a recipe title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ingredientsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter ingredients'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_instructionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter instructions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate dropdowns
    if (_selectedDifficulty == 'Difficulty Level' || !['Easy', 'Medium', 'Hard'].contains(_selectedDifficulty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a difficulty level'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCuisine == 'Cuisine Type' || !['Italian', 'Asian', 'Mexican', 'American', 'Mediterranean', 'Indian', 'French'].contains(_selectedCuisine)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cuisine type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategory == 'Category' || !['Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert'].contains(_selectedCategory)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator immediately
      setState(() {
        _isUploadingImage = true;
      });

      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text(_selectedImage != null ? 'Uploading image...' : 'Saving recipe...'),
            ],
          ),
          backgroundColor: const Color(0xFFef6a42),
          duration: Duration(seconds: _selectedImage != null ? 10 : 3),
        ),
      );

      // Parse data first (quick operations)
      int cookingTimeMinutes = int.tryParse(_cookingTimeController.text.trim()) ?? 30;
      int servings = int.tryParse(_servingsController.text.trim()) ?? 4;
      int calories = int.tryParse(_caloriesController.text.trim()) ?? 250;

      List<String> ingredients = _ingredientsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String> instructions = _instructionsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Upload image if selected (potentially slow operation)
      String? finalImageUrl = _imageUrl; // Keep existing image URL if editing
      if (_selectedImage != null) {
        debugPrint('Starting image upload...');
        finalImageUrl = await ImageUploadService.uploadImage(
          imageFile: _selectedImage!,
          recipeName: _titleController.text.trim(),
        );
        debugPrint('Image upload completed: $finalImageUrl');
        
        if (finalImageUrl == null) {
          setState(() {
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Create/update recipe (quick operation)
      debugPrint('Creating/updating recipe...');
      if (_isEditing) {
        final updatedRecipe = widget.recipe!.copyWith(
          name: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: finalImageUrl ?? widget.recipe!.imageUrl,
          ingredients: ingredients,
          instructions: instructions,
          cookingTimeMinutes: cookingTimeMinutes,
          servings: servings,
          calories: calories,
          difficulty: _selectedDifficulty,
          cuisine: _selectedCuisine,
          category: _selectedCategory,
          dietaryTags: _selectedDietaryTags,
        );

        _dataService.updateRecipe(updatedRecipe);
      } else {
        final newRecipe = Recipe(
          id: _dataService.getNextRecipeId(),
          name: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrl: finalImageUrl ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400&h=400&fit=crop',
          ingredients: ingredients,
          instructions: instructions,
          cookingTimeMinutes: cookingTimeMinutes,
          difficulty: _selectedDifficulty,
          cuisine: _selectedCuisine,
          dietaryTags: _selectedDietaryTags,
          rating: 4.5,
          servings: servings,
          calories: calories,
          category: _selectedCategory,
        );

        _dataService.addRecipe(newRecipe);
      }

      // Hide loading indicator
      setState(() {
        _isUploadingImage = false;
      });

      // Hide the progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Recipe updated successfully!' : 'Recipe saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      debugPrint('Recipe saved successfully, navigating back...');

      // Navigate back to my recipes
      context.go('/my-recipes');
    } catch (e) {
      // Hide loading indicator
      setState(() {
        _isUploadingImage = false;
      });
      
      // Hide the progress snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      debugPrint('Error saving recipe: $e');
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving recipe: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }
} 