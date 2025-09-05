import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../services/firebase_service.dart';
import '../../../models/food_model.dart';
import '../../../models/user_model.dart';
import '../models/food_logging_state_model.dart';

/// Food Logging Provider class that manages the food logging screen state
/// Uses ChangeNotifier for reactive UI updates
class FoodLoggingProvider with ChangeNotifier {
  // Private state
  FoodLoggingStateModel _state = FoodLoggingStateModel.createDefault();
  
  // Stream subscriptions for real-time data
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  
  // Timer for periodic refresh
  Timer? _refreshTimer;
  
  // User and connectivity
  User? _currentUser;
  bool _hasInternetConnection = true;

  // Public getters
  FoodLoggingStateModel get state => _state;
  UserModel? get userProfile => _state.userProfile;
  FoodLogModel? get dailyFoodLog => _state.dailyFoodLog;
  List<Map<String, dynamic>> get scanHistory => _state.scanHistory;
  DateTime get selectedDate => _state.selectedDate;
  
  bool get isLoading => _state.isLoading;
  bool get hasError => _state.hasError;
  bool get isRefreshing => _state.isRefreshing;
  String? get errorMessage => _state.errorMessage;

  // Section-specific getters
  bool isSectionLoading(FoodLoggingSection section) =>
      _state.isSectionLoading(section);
  bool hasSectionError(FoodLoggingSection section) =>
      _state.hasSectionError(section);

  // Nutrition data getters
  double get totalCalories => _state.totalCalories;
  double get totalProtein => _state.totalProtein;
  double get totalCarbs => _state.totalCarbs;
  double get totalFat => _state.totalFat;
  List<FoodEntry> get todaysMeals => _state.todaysMeals;
  bool get hasMeals => _state.hasMeals;
  
  // User profile data getters
  String get displayName => _state.displayName;
  double get userWeight => _state.userWeight;

  /// Initializes the provider and loads initial data
  Future<void> initialize() async {
    developer.log('FoodLoggingProvider: Initializing...', name: 'FoodLoggingProvider');
    
    try {
      // Get current user
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser == null) {
        developer.log('FoodLoggingProvider: No authenticated user found', name: 'FoodLoggingProvider');
        return;
      }

      // Check connectivity
      await _checkConnectivity();
      
      // Set up connectivity listener
      _setupConnectivityListener();
      
      // Load initial data
      await _loadInitialData();
      
      // Set up stream listeners for real-time updates
      _setupStreamListeners();
      
      // Start periodic refresh timer
      _startPeriodicRefresh();
      
      developer.log('FoodLoggingProvider: Initialization complete', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Initialization failed: $e', name: 'FoodLoggingProvider');
      _setState(_state.copyWith(
        status: FoodLoggingDataStatus.error,
        errorMessage: 'Failed to initialize: ${e.toString()}',
      ));
    }
  }

  /// Updates the state and notifies listeners
  void _setState(FoodLoggingStateModel newState) {
    _state = newState;
    notifyListeners();
  }

  /// Checks internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _hasInternetConnection = connectivityResult != ConnectivityResult.none;
      developer.log('FoodLoggingProvider: Connectivity status: $_hasInternetConnection', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Connectivity check failed: $e', name: 'FoodLoggingProvider');
      _hasInternetConnection = false;
    }
  }

  /// Sets up connectivity listener
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasConnected = _hasInternetConnection;
      _hasInternetConnection = result != ConnectivityResult.none;
      
      if (!wasConnected && _hasInternetConnection) {
        developer.log('FoodLoggingProvider: Connection restored, refreshing data', name: 'FoodLoggingProvider');
        refreshData();
      }
    });
  }

  /// Loads all initial data
  Future<void> _loadInitialData() async {
    if (_currentUser == null) return;

    developer.log('FoodLoggingProvider: Loading initial data...', name: 'FoodLoggingProvider');
    
    _setState(_state.copyWith(
      status: FoodLoggingDataStatus.loading,
      errorMessage: null,
    ));

    try {
      // Load data in parallel for better performance
      final futures = [
        _loadUserProfile(),
        _loadDailyFoodLog(),
        _loadScanHistory(),
      ];

      await Future.wait(futures);

      _setState(_state.copyWith(
        status: FoodLoggingDataStatus.loaded,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      ));

      developer.log('FoodLoggingProvider: Initial data loaded successfully', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Failed to load initial data: $e', name: 'FoodLoggingProvider');
      _setState(_state.copyWith(
        status: FoodLoggingDataStatus.error,
        errorMessage: 'Failed to load food logging data: ${e.toString()}',
      ));
    }
  }

  /// Loads user profile data
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      developer.log('FoodLoggingProvider: Loading user profile...', name: 'FoodLoggingProvider');
      
      _setSectionStatus(FoodLoggingSection.userProfile, FoodLoggingDataStatus.loading);
      
      final userProfile = await FirebaseService.getUserProfile(_currentUser!.uid);
      
      _setState(_state.copyWith(
        userProfile: userProfile,
        sectionStatus: {
          ..._state.sectionStatus,
          FoodLoggingSection.userProfile: FoodLoggingDataStatus.loaded,
        },
      ));
      
      developer.log('FoodLoggingProvider: User profile loaded: ${userProfile?.displayName}', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Failed to load user profile: $e', name: 'FoodLoggingProvider');
      _setSectionStatus(FoodLoggingSection.userProfile, FoodLoggingDataStatus.error);
    }
  }

  /// Loads daily food log data
  Future<void> _loadDailyFoodLog() async {
    if (_currentUser == null) return;

    try {
      developer.log('FoodLoggingProvider: Loading daily food log...', name: 'FoodLoggingProvider');
      
      _setSectionStatus(FoodLoggingSection.dailySummary, FoodLoggingDataStatus.loading);
      _setSectionStatus(FoodLoggingSection.todaysMeals, FoodLoggingDataStatus.loading);
      
      final foodLog = await FirebaseService.getFoodLogData(_currentUser!.uid, _state.selectedDate);
      
      _setState(_state.copyWith(
        dailyFoodLog: foodLog,
        sectionStatus: {
          ..._state.sectionStatus,
          FoodLoggingSection.dailySummary: FoodLoggingDataStatus.loaded,
          FoodLoggingSection.todaysMeals: FoodLoggingDataStatus.loaded,
        },
      ));
      
      developer.log('FoodLoggingProvider: Daily food log loaded: ${foodLog?.meals.length ?? 0} meals', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Failed to load daily food log: $e', name: 'FoodLoggingProvider');
      _setSectionStatus(FoodLoggingSection.dailySummary, FoodLoggingDataStatus.error);
      _setSectionStatus(FoodLoggingSection.todaysMeals, FoodLoggingDataStatus.error);
    }
  }

  /// Loads scan history data
  Future<void> _loadScanHistory() async {
    if (_currentUser == null) return;

    try {
      developer.log('FoodLoggingProvider: Loading scan history...', name: 'FoodLoggingProvider');
      
      _setSectionStatus(FoodLoggingSection.scanHistory, FoodLoggingDataStatus.loading);
      
      // Get scan history stream data once for initial load
      final scanHistoryStream = FirebaseService.streamScanHistory(_currentUser!.uid, limit: 10);
      final scanHistory = await scanHistoryStream.first;
      
      _setState(_state.copyWith(
        scanHistory: scanHistory,
        sectionStatus: {
          ..._state.sectionStatus,
          FoodLoggingSection.scanHistory: FoodLoggingDataStatus.loaded,
        },
      ));
      
      developer.log('FoodLoggingProvider: Scan history loaded: ${scanHistory.length} items', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Failed to load scan history: $e', name: 'FoodLoggingProvider');
      _setSectionStatus(FoodLoggingSection.scanHistory, FoodLoggingDataStatus.error);
    }
  }

  /// Sets the status of a specific section
  void _setSectionStatus(FoodLoggingSection section, FoodLoggingDataStatus status) {
    final updatedSectionStatus = Map<FoodLoggingSection, FoodLoggingDataStatus>.from(_state.sectionStatus);
    updatedSectionStatus[section] = status;
    
    _setState(_state.copyWith(
      sectionStatus: updatedSectionStatus,
    ));
  }

  /// Sets up real-time stream listeners
  void _setupStreamListeners() {
    if (_currentUser == null) return;

    developer.log('FoodLoggingProvider: Setting up stream listeners...', name: 'FoodLoggingProvider');
    
    final userId = _currentUser!.uid;

    // Food log data stream
    _streamSubscriptions['foodLog'] = FirebaseService
        .streamFoodLogData(userId, _state.selectedDate)
        .listen(
      (FoodLogModel? foodLog) {
        developer.log('FoodLoggingProvider: Food log stream update: ${foodLog?.meals.length ?? 0} meals', name: 'FoodLoggingProvider');
        _setState(_state.copyWith(
          dailyFoodLog: foodLog,
          lastUpdated: DateTime.now(),
        ));
      },
      onError: (error) {
        developer.log('FoodLoggingProvider: Food log stream error: $error', name: 'FoodLoggingProvider');
      },
    );

    // Scan history stream
    _streamSubscriptions['scanHistory'] = FirebaseService
        .streamScanHistory(userId, limit: 10)
        .listen(
      (List<Map<String, dynamic>> scanHistory) {
        developer.log('FoodLoggingProvider: Scan history stream update: ${scanHistory.length} items', name: 'FoodLoggingProvider');
        _setState(_state.copyWith(
          scanHistory: scanHistory,
          lastUpdated: DateTime.now(),
        ));
      },
      onError: (error) {
        developer.log('FoodLoggingProvider: Scan history stream error: $error', name: 'FoodLoggingProvider');
      },
    );

    developer.log('FoodLoggingProvider: Stream listeners setup complete', name: 'FoodLoggingProvider');
  }

  /// Starts periodic refresh timer
  void _startPeriodicRefresh() {
    // Refresh data every 10 minutes for food logging
    _refreshTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (_state.needsRefresh) {
        developer.log('FoodLoggingProvider: Performing periodic refresh', name: 'FoodLoggingProvider');
        refreshData();
      }
    });
  }

  /// Refreshes all data or specific sections
  Future<void> refreshData({Set<FoodLoggingSection>? sectionsToRefresh}) async {
    if (_currentUser == null) return;
    if (!_hasInternetConnection) {
      developer.log('FoodLoggingProvider: Skipping refresh - no internet connection', name: 'FoodLoggingProvider');
      return;
    }

    developer.log('FoodLoggingProvider: Refreshing data...', name: 'FoodLoggingProvider');
    
    _setState(_state.copyWith(
      isRefreshing: true,
      errorMessage: null,
    ));

    try {
      final sectionsToLoad = sectionsToRefresh ?? {
        FoodLoggingSection.userProfile,
        FoodLoggingSection.dailySummary,
        FoodLoggingSection.todaysMeals,
        FoodLoggingSection.scanHistory,
      };

      final futures = <Future<void>>[];
      
      if (sectionsToLoad.contains(FoodLoggingSection.userProfile)) {
        futures.add(_loadUserProfile());
      }
      
      if (sectionsToLoad.contains(FoodLoggingSection.dailySummary) ||
          sectionsToLoad.contains(FoodLoggingSection.todaysMeals)) {
        futures.add(_loadDailyFoodLog());
      }
      
      if (sectionsToLoad.contains(FoodLoggingSection.scanHistory)) {
        futures.add(_loadScanHistory());
      }

      await Future.wait(futures);

      _setState(_state.copyWith(
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        status: FoodLoggingDataStatus.loaded,
      ));

      developer.log('FoodLoggingProvider: Data refresh completed', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Data refresh failed: $e', name: 'FoodLoggingProvider');
      _setState(_state.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh data: ${e.toString()}',
      ));
    }
  }

  /// Changes the selected date and reloads data
  Future<void> changeSelectedDate(DateTime date) async {
    developer.log('FoodLoggingProvider: Changing selected date to $date', name: 'FoodLoggingProvider');
    
    _setState(_state.copyWith(
      selectedDate: date,
    ));

    // Cancel existing food log stream and setup new one
    _streamSubscriptions['foodLog']?.cancel();
    
    // Reload data for new date
    await _loadDailyFoodLog();
    
    // Setup new stream for the selected date
    if (_currentUser != null) {
      _streamSubscriptions['foodLog'] = FirebaseService
          .streamFoodLogData(_currentUser!.uid, date)
          .listen(
        (FoodLogModel? foodLog) {
          _setState(_state.copyWith(
            dailyFoodLog: foodLog,
            lastUpdated: DateTime.now(),
          ));
        },
        onError: (error) {
          developer.log('FoodLoggingProvider: Food log stream error: $error', name: 'FoodLoggingProvider');
        },
      );
    }
  }

  /// Adds a scanned food item
  Future<void> addScannedFood(String barcode, Map<String, dynamic> foodData, String mealType) async {
    if (_currentUser == null) return;

    try {
      developer.log('FoodLoggingProvider: Adding scanned food: ${foodData['name']}', name: 'FoodLoggingProvider');

      final foodItem = FoodItem(
        name: foodData['name'] ?? 'Scanned Food',
        barcode: barcode,
        caloriesPerUnit: foodData['calories']?.toDouble() ?? 100.0,
        proteinPerUnit: foodData['protein']?.toDouble() ?? 0.0,
        carbsPerUnit: foodData['carbs']?.toDouble() ?? 0.0,
        fatPerUnit: foodData['fat']?.toDouble() ?? 0.0,
        brand: foodData['brand'],
        imageUrl: foodData['imageUrl'],
      );

      final foodEntry = FoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mealType: mealType,
        items: [foodItem],
        timestamp: DateTime.now(),
      );

      await FirebaseService.addFoodEntry(_currentUser!.uid, _state.selectedDate, foodEntry);
      
      // Add success message
      _addMessage('Added ${foodItem.name} to $mealType');
      
      developer.log('FoodLoggingProvider: Scanned food added successfully', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Failed to add scanned food: $e', name: 'FoodLoggingProvider');
      _addMessage('Failed to add food: ${e.toString()}');
    }
  }

  /// Adds a manually entered food item
  Future<void> addManualFood(Map<String, dynamic> foodData) async {
    if (_currentUser == null) return;

    try {
      developer.log('FoodLoggingProvider: Adding manual food: ${foodData['name']}', name: 'FoodLoggingProvider');
      
      final mealType = foodData['mealType'] as String;
      
      final foodItem = FoodItem(
        name: foodData['name'],
        quantity: foodData['quantity']?.toDouble() ?? 1.0,
        unit: foodData['unit'] ?? 'serving',
        caloriesPerUnit: foodData['calories']?.toDouble() ?? 0.0,
        proteinPerUnit: foodData['protein']?.toDouble() ?? 0.0,
        carbsPerUnit: foodData['carbs']?.toDouble() ?? 0.0,
        fatPerUnit: foodData['fat']?.toDouble() ?? 0.0,
      );

      final foodEntry = FoodEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mealType: mealType,
        items: [foodItem],
        timestamp: DateTime.now(),
      );

      await FirebaseService.addFoodEntry(_currentUser!.uid, _state.selectedDate, foodEntry);
      
      // Add success message
      _addMessage('Added ${foodItem.name} to $mealType');
      
      developer.log('FoodLoggingProvider: Manual food added successfully', name: 'FoodLoggingProvider');
    } catch (e) {
      developer.log('FoodLoggingProvider: Failed to add manual food: $e', name: 'FoodLoggingProvider');
      _addMessage('Failed to add food: ${e.toString()}');
    }
  }

  /// Adds a message to the message queue
  void _addMessage(String message) {
    final updatedMessages = List<String>.from(_state.messages)..add(message);
    _setState(_state.copyWith(messages: updatedMessages));
    
    // Auto-clear message after 3 seconds
    Timer(const Duration(seconds: 3), () {
      clearMessage(message);
    });
  }

  /// Clears a specific message
  void clearMessage(String message) {
    final updatedMessages = List<String>.from(_state.messages)..remove(message);
    _setState(_state.copyWith(messages: updatedMessages));
  }

  /// Clears all messages
  void clearAllMessages() {
    _setState(_state.copyWith(messages: []));
  }

  /// Toggles notifications
  void toggleNotifications() {
    final newValue = !_state.notificationsEnabled;
    _setState(_state.copyWith(notificationsEnabled: newValue));
    developer.log('FoodLoggingProvider: Notifications ${newValue ? 'enabled' : 'disabled'}', name: 'FoodLoggingProvider');
  }

  /// Clears any error state
  void clearError() {
    _setState(_state.copyWith(
      status: FoodLoggingDataStatus.loaded,
      errorMessage: null,
    ));
  }

  /// Disposes of resources
  @override
  void dispose() {
    developer.log('FoodLoggingProvider: Disposing...', name: 'FoodLoggingProvider');
    
    // Cancel all stream subscriptions
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    
    // Cancel refresh timer
    _refreshTimer?.cancel();
    
    super.dispose();
    
    developer.log('FoodLoggingProvider: Disposed successfully', name: 'FoodLoggingProvider');
  }

  /// Debug method to get current state info
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasUser': _currentUser != null,
      'userId': _currentUser?.uid,
      'isConnected': _hasInternetConnection,
      'state': _state.toString(),
      'streamCount': _streamSubscriptions.length,
      'hasRefreshTimer': _refreshTimer?.isActive ?? false,
    };
  }
}
