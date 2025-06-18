import 'package:flutter/material.dart';

class Recipe {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions;
  final int cookingTimeMinutes;
  final String difficulty; // Easy, Medium, Hard
  final String cuisine; // Italian, Asian, Mexican, etc.
  final List<String> dietaryTags; // Vegetarian, Vegan, Gluten-Free, etc.
  final double rating;
  final int servings;
  final int calories;
  final String category; // Breakfast, Lunch, Dinner, Snack, Dessert
  List<String> missingIngredients; // Made mutable
  int? matchPercentage; // Made mutable and nullable
  int? matchingIngredientsCount; // New field
  int? totalIngredientsCount; // New field
  final DateTime createdAt;
  final String? userId; // For user-created recipes

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.cookingTimeMinutes,
    required this.difficulty,
    required this.cuisine,
    required this.dietaryTags,
    required this.rating,
    required this.servings,
    required this.calories,
    required this.category,
    this.missingIngredients = const [],
    this.matchPercentage,
    this.matchingIngredientsCount,
    this.totalIngredientsCount,
    DateTime? createdAt,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now();

  // Get ingredient match display text (e.g., "4/8 ingredients")
  String? get ingredientMatchText {
    if (matchingIngredientsCount != null && totalIngredientsCount != null) {
      return '$matchingIngredientsCount/$totalIngredientsCount ingredients';
    }
    return null;
  }

  // Convert to/from Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'ingredients': ingredients,
      'instructions': instructions,
      'cookingTimeMinutes': cookingTimeMinutes,
      'difficulty': difficulty,
      'cuisine': cuisine,
      'dietaryTags': dietaryTags,
      'rating': rating,
      'servings': servings,
      'calories': calories,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'userId': userId,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      instructions: List<String>.from(map['instructions'] ?? []),
      cookingTimeMinutes: map['cookingTimeMinutes']?.toInt() ?? 0,
      difficulty: map['difficulty'] ?? 'Easy',
      cuisine: map['cuisine'] ?? 'International',
      dietaryTags: List<String>.from(map['dietaryTags'] ?? []),
      rating: map['rating']?.toDouble() ?? 0.0,
      servings: map['servings']?.toInt() ?? 1,
      calories: map['calories']?.toInt() ?? 0,
      category: map['category'] ?? 'Main Course',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      userId: map['userId'],
    );
  }

  // Create a copy with updated missing ingredients and match percentage
  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? ingredients,
    List<String>? instructions,
    int? cookingTimeMinutes,
    String? difficulty,
    String? cuisine,
    List<String>? dietaryTags,
    double? rating,
    int? servings,
    int? calories,
    String? category,
    List<String>? missingIngredients,
    int? matchPercentage,
    int? matchingIngredientsCount,
    int? totalIngredientsCount,
    DateTime? createdAt,
    String? userId,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      cookingTimeMinutes: cookingTimeMinutes ?? this.cookingTimeMinutes,
      difficulty: difficulty ?? this.difficulty,
      cuisine: cuisine ?? this.cuisine,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      rating: rating ?? this.rating,
      servings: servings ?? this.servings,
      calories: calories ?? this.calories,
      category: category ?? this.category,
      missingIngredients: missingIngredients ?? this.missingIngredients,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      matchingIngredientsCount: matchingIngredientsCount ?? this.matchingIngredientsCount,
      totalIngredientsCount: totalIngredientsCount ?? this.totalIngredientsCount,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  // Get cooking time as formatted string
  String get formattedCookingTime {
    if (cookingTimeMinutes < 60) {
      return '${cookingTimeMinutes}min';
    } else {
      int hours = cookingTimeMinutes ~/ 60;
      int minutes = cookingTimeMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  // Get difficulty color
  Color get difficultyColor {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50); // Green
      case 'medium':
        return const Color(0xFFFF9800); // Orange
      case 'hard':
        return const Color(0xFFF44336); // Red
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // Check if recipe matches dietary preferences
  bool matchesDietaryPreference(String preference) {
    return dietaryTags.any((tag) => 
        tag.toLowerCase().contains(preference.toLowerCase()));
  }
} 