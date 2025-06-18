import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/recipe_model.dart';
import 'auth_service.dart';

class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  final Connectivity _connectivity = Connectivity();
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Cache keys
  static const String _savedRecipesKey = 'cached_saved_recipes';
  static const String _favoriteRecipesKey = 'cached_favorite_recipes';
  static const String _userRecipesKey = 'cached_user_recipes';
  static const String _allRecipesKey = 'cached_all_recipes';
  static const String _mealPlansKey = 'cached_meal_plans';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _pendingActionsKey = 'pending_actions';
  static const String _connectivityStatusKey = 'last_connectivity_status';

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _onConnectivityChanged(results.first);
      }
    });
  }

  // Check if device is online
  Future<bool> isOnline() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) async {
    bool wasOffline = await _getConnectivityStatus() == false;
    bool isNowOnline = result != ConnectivityResult.none;
    
    await _setConnectivityStatus(isNowOnline);
    
    // If coming back online, sync pending actions
    if (wasOffline && isNowOnline) {
      await _syncPendingActions();
    }
  }

  // Save/Get connectivity status
  Future<void> _setConnectivityStatus(bool isOnline) async {
    await _prefs.setBool(_connectivityStatusKey, isOnline);
  }

  Future<bool> _getConnectivityStatus() async {
    return _prefs.getBool(_connectivityStatusKey) ?? true;
  }

  // SAVED RECIPES CACHE
  Future<void> cacheSavedRecipes(List<Recipe> recipes) async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_savedRecipesKey}_$userId';
    
    final List<Map<String, dynamic>> recipeMaps = recipes.map((recipe) => recipe.toMap()).toList();
    await _prefs.setString(key, jsonEncode(recipeMaps));
    await _updateLastSync();
  }

  Future<List<Recipe>> getCachedSavedRecipes() async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_savedRecipesKey}_$userId';
    
    final String? recipesJson = _prefs.getString(key);
    if (recipesJson == null) return [];
    
    final List<dynamic> recipeMaps = jsonDecode(recipesJson);
    return recipeMaps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<void> addToSavedRecipesCache(Recipe recipe) async {
    final List<Recipe> savedRecipes = await getCachedSavedRecipes();
    if (!savedRecipes.any((r) => r.id == recipe.id)) {
      savedRecipes.add(recipe);
      await cacheSavedRecipes(savedRecipes);
    }
  }

  Future<void> removeFromSavedRecipesCache(String recipeId) async {
    final List<Recipe> savedRecipes = await getCachedSavedRecipes();
    savedRecipes.removeWhere((recipe) => recipe.id == recipeId);
    await cacheSavedRecipes(savedRecipes);
  }

  // FAVORITE RECIPES CACHE
  Future<void> cacheFavoriteRecipes(List<Recipe> recipes) async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_favoriteRecipesKey}_$userId';
    
    final List<Map<String, dynamic>> recipeMaps = recipes.map((recipe) => recipe.toMap()).toList();
    await _prefs.setString(key, jsonEncode(recipeMaps));
    await _updateLastSync();
  }

  Future<List<Recipe>> getCachedFavoriteRecipes() async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_favoriteRecipesKey}_$userId';
    
    final String? recipesJson = _prefs.getString(key);
    if (recipesJson == null) return [];
    
    final List<dynamic> recipeMaps = jsonDecode(recipesJson);
    return recipeMaps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<void> addToFavoriteRecipesCache(Recipe recipe) async {
    final List<Recipe> favoriteRecipes = await getCachedFavoriteRecipes();
    if (!favoriteRecipes.any((r) => r.id == recipe.id)) {
      favoriteRecipes.add(recipe);
      await cacheFavoriteRecipes(favoriteRecipes);
    }
  }

  Future<void> removeFromFavoriteRecipesCache(String recipeId) async {
    final List<Recipe> favoriteRecipes = await getCachedFavoriteRecipes();
    favoriteRecipes.removeWhere((recipe) => recipe.id == recipeId);
    await cacheFavoriteRecipes(favoriteRecipes);
  }

  // USER CREATED RECIPES CACHE
  Future<void> cacheUserRecipes(List<Recipe> recipes) async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_userRecipesKey}_$userId';
    
    final List<Map<String, dynamic>> recipeMaps = recipes.map((recipe) => recipe.toMap()).toList();
    await _prefs.setString(key, jsonEncode(recipeMaps));
    await _updateLastSync();
  }

  Future<List<Recipe>> getCachedUserRecipes() async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_userRecipesKey}_$userId';
    
    final String? recipesJson = _prefs.getString(key);
    if (recipesJson == null) return [];
    
    final List<dynamic> recipeMaps = jsonDecode(recipesJson);
    return recipeMaps.map((map) => Recipe.fromMap(map)).toList();
  }

  Future<void> addToUserRecipesCache(Recipe recipe) async {
    final List<Recipe> userRecipes = await getCachedUserRecipes();
    userRecipes.removeWhere((r) => r.id == recipe.id); // Remove if exists
    userRecipes.add(recipe); // Add updated version
    await cacheUserRecipes(userRecipes);
  }

  // ALL RECIPES CACHE (for search functionality)
  Future<void> cacheAllRecipes(List<Recipe> recipes) async {
    await _ensureInitialized();
    final List<Map<String, dynamic>> recipeMaps = recipes.map((recipe) => recipe.toMap()).toList();
    await _prefs.setString(_allRecipesKey, jsonEncode(recipeMaps));
    await _updateLastSync();
  }

  Future<List<Recipe>> getCachedAllRecipes() async {
    await _ensureInitialized();
    final String? recipesJson = _prefs.getString(_allRecipesKey);
    if (recipesJson == null) return [];
    
    final List<dynamic> recipeMaps = jsonDecode(recipesJson);
    return recipeMaps.map((map) => Recipe.fromMap(map)).toList();
  }

  // MEAL PLANS CACHE
  Future<void> cacheMealPlans(Map<String, dynamic> mealPlansData) async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_mealPlansKey}_$userId';
    
    await _prefs.setString(key, jsonEncode(mealPlansData));
    await _updateLastSync();
  }

  Future<Map<String, dynamic>> getCachedMealPlans() async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    final String key = '${_mealPlansKey}_$userId';
    
    final String? mealPlansJson = _prefs.getString(key);
    if (mealPlansJson == null) return {};
    
    return Map<String, dynamic>.from(jsonDecode(mealPlansJson));
  }

  // PENDING ACTIONS (for when offline)
  Future<void> addPendingAction(Map<String, dynamic> action) async {
    await _ensureInitialized();
    final List<Map<String, dynamic>> pendingActions = await _getPendingActions();
    
    action['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    action['userId'] = AuthService().userId;
    
    pendingActions.add(action);
    await _prefs.setString(_pendingActionsKey, jsonEncode(pendingActions));
  }

  Future<List<Map<String, dynamic>>> _getPendingActions() async {
    await _ensureInitialized();
    final String? actionsJson = _prefs.getString(_pendingActionsKey);
    if (actionsJson == null) return [];
    
    final List<dynamic> actions = jsonDecode(actionsJson);
    return actions.cast<Map<String, dynamic>>();
  }

  Future<void> _clearPendingActions() async {
    await _prefs.remove(_pendingActionsKey);
  }

  // Sync pending actions when back online
  Future<void> _syncPendingActions() async {
    // This would sync with Firebase when online
    // For now, we'll just clear them as we're primarily focusing on offline access
    await _clearPendingActions();
  }

  // UTILITY METHODS
  Future<void> _updateLastSync() async {
    await _prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastSyncTime() async {
    await _ensureInitialized();
    final int? timestamp = _prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Get cache status info
  Future<Map<String, dynamic>> getCacheStatus() async {
    await _ensureInitialized();
    final bool isOnlineNow = await isOnline();
    final DateTime? lastSync = await getLastSyncTime();
    final List<Recipe> savedRecipes = await getCachedSavedRecipes();
    final List<Recipe> favoriteRecipes = await getCachedFavoriteRecipes();
    final List<Recipe> userRecipes = await getCachedUserRecipes();
    final List<Map<String, dynamic>> pendingActions = await _getPendingActions();

    return {
      'isOnline': isOnlineNow,
      'lastSync': lastSync,
      'savedRecipesCount': savedRecipes.length,
      'favoriteRecipesCount': favoriteRecipes.length,
      'userRecipesCount': userRecipes.length,
      'pendingActionsCount': pendingActions.length,
      'hasCachedData': savedRecipes.isNotEmpty || favoriteRecipes.isNotEmpty || userRecipes.isNotEmpty,
    };
  }

  // Clear all cache for user
  Future<void> clearUserCache() async {
    await _ensureInitialized();
    final String userId = AuthService().userId ?? 'anonymous';
    
    await _prefs.remove('${_savedRecipesKey}_$userId');
    await _prefs.remove('${_favoriteRecipesKey}_$userId');
    await _prefs.remove('${_userRecipesKey}_$userId');
    await _prefs.remove('${_mealPlansKey}_$userId');
    await _prefs.remove(_pendingActionsKey);
    await _prefs.remove(_lastSyncKey);
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await _ensureInitialized();
    await _prefs.clear();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Search in cached recipes
  Future<List<Recipe>> searchCachedRecipes(String query) async {
    final List<Recipe> allCachedRecipes = [
      ...await getCachedSavedRecipes(),
      ...await getCachedFavoriteRecipes(),
      ...await getCachedUserRecipes(),
      ...await getCachedAllRecipes(),
    ];

    // Remove duplicates
    final Map<String, Recipe> uniqueRecipes = {};
    for (final recipe in allCachedRecipes) {
      uniqueRecipes[recipe.id] = recipe;
    }

    final List<Recipe> searchResults = uniqueRecipes.values.where((recipe) {
      final String queryLower = query.toLowerCase();
      return recipe.name.toLowerCase().contains(queryLower) ||
             recipe.description.toLowerCase().contains(queryLower) ||
             recipe.ingredients.any((ingredient) => ingredient.toLowerCase().contains(queryLower)) ||
             recipe.cuisine.toLowerCase().contains(queryLower) ||
             recipe.category.toLowerCase().contains(queryLower);
    }).toList();

    return searchResults;
  }
} 