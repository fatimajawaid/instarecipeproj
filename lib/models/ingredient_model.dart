class Ingredient {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> alternativeNames;
  final bool isSelected; // For user's kitchen selection
  final String unit; // cup, tbsp, piece, etc.

  Ingredient({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.alternativeNames = const [],
    this.isSelected = false,
    this.unit = 'piece',
  });

  // Convert to/from Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'alternativeNames': alternativeNames,
      'unit': unit,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      alternativeNames: List<String>.from(map['alternativeNames'] ?? []),
      unit: map['unit'] ?? 'piece',
    );
  }

  // Create a copy with updated selection status
  Ingredient copyWith({
    String? id,
    String? name,
    String? category,
    String? imageUrl,
    List<String>? alternativeNames,
    bool? isSelected,
    String? unit,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      alternativeNames: alternativeNames ?? this.alternativeNames,
      isSelected: isSelected ?? this.isSelected,
      unit: unit ?? this.unit,
    );
  }

  // Check if ingredient matches search query
  bool matchesSearch(String query) {
    String lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           alternativeNames.any((alt) => alt.toLowerCase().contains(lowerQuery));
  }
}

class IngredientCategory {
  final String id;
  final String name;
  final String icon;
  final List<Ingredient> ingredients;

  IngredientCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.ingredients,
  });

  // Get selected ingredients count
  int get selectedCount => ingredients.where((ing) => ing.isSelected).length;

  // Get total ingredients count
  int get totalCount => ingredients.length;
} 