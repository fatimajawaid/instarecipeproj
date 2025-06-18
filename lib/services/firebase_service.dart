import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:typed_data';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Connectivity _connectivity = Connectivity();

  // Collections
  static const String recipesCollection = 'recipes';
  static const String usersCollection = 'users';
  static const String savedRecipesCollection = 'saved_recipes';
  static const String cookingHistoryCollection = 'cooking_history';

  // Initialize Firebase service with offline support
  Future<void> initialize() async {
    // Enable offline persistence for Firestore
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Authentication methods
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // Network connectivity check
  Future<bool> isConnected() async {
    var connectivityResult = await _connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // Recipe methods with offline support
  Future<List<Map<String, dynamic>>> getRecipes() async {
    try {
      // Try to get from Firestore (works offline with cache)
      QuerySnapshot snapshot = await _firestore
          .collection(recipesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> recipes = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      // Cache the data locally
      await _cacheData('recipes', recipes);
      return recipes;
    } catch (e) {
      // If offline or error, try to get from cache
      return await _getCachedData('recipes') ?? [];
    }
  }

  Future<Map<String, dynamic>?> getRecipe(String recipeId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(recipesCollection)
          .doc(recipeId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      // Try to get from cached recipes
      List<Map<String, dynamic>>? cachedRecipes = await _getCachedData('recipes');
      if (cachedRecipes != null) {
        return cachedRecipes.firstWhere(
          (recipe) => recipe['id'] == recipeId,
          orElse: () => {},
        );
      }
      return null;
    }
  }

  Future<String> addRecipe(Map<String, dynamic> recipeData) async {
    try {
      recipeData['createdAt'] = FieldValue.serverTimestamp();
      recipeData['userId'] = currentUser?.uid;

      DocumentReference docRef = await _firestore
          .collection(recipesCollection)
          .add(recipeData);

      return docRef.id;
    } catch (e) {
      // If offline, store in pending uploads
      await _storePendingUpload('recipe', recipeData);
      throw Exception('Recipe saved locally. Will sync when online.');
    }
  }

  Future<void> updateRecipe(String recipeId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection(recipesCollection)
          .doc(recipeId)
          .update(updates);
    } catch (e) {
      await _storePendingUpload('update_recipe', {
        'id': recipeId,
        'updates': updates,
      });
      throw Exception('Update saved locally. Will sync when online.');
    }
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await _firestore
          .collection(recipesCollection)
          .doc(recipeId)
          .delete();
    } catch (e) {
      await _storePendingUpload('delete_recipe', {'id': recipeId});
      throw Exception('Delete saved locally. Will sync when online.');
    }
  }

  // Saved recipes methods
  Future<void> saveRecipe(String recipeId) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUser!.uid)
          .collection(savedRecipesCollection)
          .doc(recipeId)
          .set({
        'recipeId': recipeId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _storePendingUpload('save_recipe', {'recipeId': recipeId});
    }
  }

  Future<void> unsaveRecipe(String recipeId) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUser!.uid)
          .collection(savedRecipesCollection)
          .doc(recipeId)
          .delete();
    } catch (e) {
      await _storePendingUpload('unsave_recipe', {'recipeId': recipeId});
    }
  }

  Future<List<String>> getSavedRecipeIds() async {
    if (currentUser == null) return [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection(usersCollection)
          .doc(currentUser!.uid)
          .collection(savedRecipesCollection)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return await _getCachedData('saved_recipes') ?? [];
    }
  }

  // Cooking history methods
  Future<void> addToCookingHistory(String recipeId) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection(usersCollection)
          .doc(currentUser!.uid)
          .collection(cookingHistoryCollection)
          .add({
        'recipeId': recipeId,
        'cookedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await _storePendingUpload('cooking_history', {'recipeId': recipeId});
    }
  }

  Future<List<Map<String, dynamic>>> getCookingHistory() async {
    if (currentUser == null) return [];

    try {
      QuerySnapshot snapshot = await _firestore
          .collection(usersCollection)
          .doc(currentUser!.uid)
          .collection(cookingHistoryCollection)
          .orderBy('cookedAt', descending: true)
          .limit(50)
          .get();

      List<Map<String, dynamic>> history = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      await _cacheData('cooking_history', history);
      return history;
    } catch (e) {
      return await _getCachedData('cooking_history') ?? [];
    }
  }

  // Search methods
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // For production, consider using Algolia or Elasticsearch
      QuerySnapshot snapshot = await _firestore
          .collection(recipesCollection)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      // Fallback to local search in cached data
      List<Map<String, dynamic>>? cachedRecipes = await _getCachedData('recipes');
      if (cachedRecipes != null) {
        return cachedRecipes.where((recipe) {
          return recipe['name']?.toLowerCase().contains(query.toLowerCase()) ?? false;
        }).toList();
      }
      return [];
    }
  }

  // File upload methods
  Future<String> uploadImage(String filePath, String fileName) async {
    try {
      Reference ref = _storage.ref().child('images/$fileName');
      UploadTask uploadTask = ref.putData(await _getFileBytes(filePath));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // Sync pending uploads when back online
  Future<void> syncPendingUploads() async {
    if (!await isConnected()) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? pendingUploads = prefs.getStringList('pending_uploads');

    if (pendingUploads != null) {
      for (String uploadJson in pendingUploads) {
        try {
          Map<String, dynamic> upload = json.decode(uploadJson);
          String type = upload['type'];
          Map<String, dynamic> data = upload['data'];

          switch (type) {
            case 'recipe':
              await addRecipe(data);
              break;
            case 'update_recipe':
              await updateRecipe(data['id'], data['updates']);
              break;
            case 'delete_recipe':
              await deleteRecipe(data['id']);
              break;
            case 'save_recipe':
              await saveRecipe(data['recipeId']);
              break;
            case 'unsave_recipe':
              await unsaveRecipe(data['recipeId']);
              break;
            case 'cooking_history':
              await addToCookingHistory(data['recipeId']);
              break;
          }
        } catch (e) {
          print('Failed to sync upload: $e');
        }
      }

      // Clear pending uploads after successful sync
      await prefs.remove('pending_uploads');
    }
  }

  // Private helper methods
  Future<void> _cacheData(String key, dynamic data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$key', json.encode(data));
  }

  Future<T?> _getCachedData<T>(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('cache_$key');
    if (cachedData != null) {
      return json.decode(cachedData) as T;
    }
    return null;
  }

  Future<void> _storePendingUpload(String type, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pendingUploads = prefs.getStringList('pending_uploads') ?? [];
    
    pendingUploads.add(json.encode({
      'type': type,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
    
    await prefs.setStringList('pending_uploads', pendingUploads);
  }

  Future<Uint8List> _getFileBytes(String filePath) async {
    // This would be implemented based on your file handling needs
    // For now, returning empty Uint8List
    return Uint8List(0);
  }
} 