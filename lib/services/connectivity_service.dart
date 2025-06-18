import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'firebase_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final FirebaseService _firebaseService = FirebaseService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _wasOffline = false;

  // Initialize connectivity monitoring
  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );
  }

  // Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    bool isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    
    if (isOnline && _wasOffline) {
      // Just came back online, sync pending uploads
      print('Back online! Syncing pending uploads...');
      try {
        await _firebaseService.syncPendingUploads();
        print('Sync completed successfully');
      } catch (e) {
        print('Sync failed: $e');
      }
    }
    
    _wasOffline = !isOnline;
  }

  // Check current connectivity status
  Future<bool> isConnected() async {
    var connectivityResults = await _connectivity.checkConnectivity();
    return connectivityResults.isNotEmpty && !connectivityResults.contains(ConnectivityResult.none);
  }

  // Get connectivity status stream
  Stream<List<ConnectivityResult>> get connectivityStream => 
      _connectivity.onConnectivityChanged;

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
} 