import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../services/firebase_service.dart';
import '../../../services/step_counter_error_handler.dart';
import '../../../services/global_step_counter_provider.dart';
import '../../../models/activity_model.dart';
import '../../../models/hydration_model.dart';
import '../../../models/user_model.dart';
import '../models/activity_state_model.dart';

/// Activity Provider class that manages the activity screen state
/// Uses ChangeNotifier for reactive UI updates
class ActivityProvider with ChangeNotifier {
  // Private state
  ActivityStateModel _activityState = const ActivityStateModel();
  
  // Stream subscriptions for real-time data
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  
  // Timer for periodic refresh
  Timer? _refreshTimer;
  
  // User and connectivity
  User? _currentUser;
  bool _hasInternetConnection = true;

  // Legacy services kept for backward compatibility
  final StepCounterErrorHandler _errorHandler = StepCounterErrorHandler();
  
  // Global step counter reference
  GlobalStepCounterProvider? _globalStepCounter;

  // Public getters
  ActivityStateModel get activityState => _activityState;
  UserModel? get userProfile => _activityState.userProfile;
  ActivityModel? get activityData => _activityState.activityData;
  HydrationModel? get hydrationData => _activityState.hydrationData;
  
  bool get isLoading => _activityState.isLoading;
  bool get hasError => _activityState.hasError;
  bool get isRefreshing => _activityState.isRefreshing;
  String? get errorMessage => _activityState.errorMessage;

  // Section-specific getters
  bool isSectionLoading(ActivitySection section) =>
      _activityState.isSectionLoading(section);
  bool hasSectionError(ActivitySection section) =>
      _activityState.hasSectionError(section);

  // Data getters - prioritize global step counter when available
  int get currentSteps {
    if (_globalStepCounter != null && _globalStepCounter!.isInitialized) {
      return _globalStepCounter!.primarySteps;
    }
    return _activityState.currentSteps;
  }
  
  double get stepsProgress => (currentSteps / stepGoal).clamp(0.0, 1.0);
  double get currentDistance => _activityState.currentDistance;
  double get currentCalories => _activityState.currentCalories;
  double get currentWaterIntake => _activityState.currentWaterIntake;
  double get waterProgress => _activityState.waterProgress;
  int get stepGoal => _activityState.stepGoal;
  double get waterGoal => _activityState.waterGoal;

  // Achievements
  bool get hasAchievedStepGoal => _activityState.hasAchievedStepGoal;
  bool get hasAchievedWaterGoal => _activityState.hasAchievedWaterGoal;

  // Step counter getters - now using global step counter
  bool get isPedometerAvailable => _globalStepCounter?.isPedometerAvailable ?? false;
  bool get isStepCounterListening => _globalStepCounter?.isStepCounterListening ?? false;
  int get deviceSteps => _globalStepCounter?.deviceSteps ?? 0;
  int get pedometerDailySteps => _globalStepCounter?.pedometerDailySteps ?? 0;
  String get stepCounterStatus => _globalStepCounter?.stepCounterStatus ?? 'Not available';
  bool get hasStepCounterError => _globalStepCounter?.hasStepCounterError ?? false;
  String? get stepCounterError => _globalStepCounter?.stepCounterError;

  /// Initializes the provider and loads initial data
  Future<void> initialize() async {
    developer.log('ActivityProvider: Initializing...', name: 'ActivityProvider');
    
    try {
      // Get current user
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser == null) {
        developer.log('ActivityProvider: No authenticated user found', name: 'ActivityProvider');
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
      
      developer.log('ActivityProvider: Initialization complete', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Initialization failed: $e', name: 'ActivityProvider');
      _setActivityState(_activityState.copyWith(
        status: ActivityDataStatus.error,
        errorMessage: 'Failed to initialize: ${e.toString()}',
      ));
    }
  }

  /// Updates the activity state and notifies listeners
  void _setActivityState(ActivityStateModel newState) {
    _activityState = newState;
    notifyListeners();
  }

  /// Checks internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      _hasInternetConnection = connectivityResult != ConnectivityResult.none;
      developer.log('ActivityProvider: Connectivity status: $_hasInternetConnection', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Connectivity check failed: $e', name: 'ActivityProvider');
      _hasInternetConnection = false;
    }
  }

  /// Sets up connectivity listener
  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasConnected = _hasInternetConnection;
      _hasInternetConnection = result != ConnectivityResult.none;
      
      if (!wasConnected && _hasInternetConnection) {
        developer.log('ActivityProvider: Connection restored, refreshing data', name: 'ActivityProvider');
        refreshData();
      }
    });
  }

  /// Loads all initial data
  Future<void> _loadInitialData() async {
    if (_currentUser == null) return;

    developer.log('ActivityProvider: Loading initial data...', name: 'ActivityProvider');
    
    _setActivityState(_activityState.copyWith(
      status: ActivityDataStatus.loading,
      errorMessage: null,
    ));

    try {
      // Load data in parallel for better performance
      final futures = [
        _loadUserProfile(),
        _loadTodaysActivityData(),
        _loadTodaysHydrationData(),
      ];

      await Future.wait(futures);

      _setActivityState(_activityState.copyWith(
        status: ActivityDataStatus.loaded,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      ));

      developer.log('ActivityProvider: Initial data loaded successfully', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Failed to load initial data: $e', name: 'ActivityProvider');
      _setActivityState(_activityState.copyWith(
        status: ActivityDataStatus.error,
        errorMessage: 'Failed to load activity data: ${e.toString()}',
      ));
    }
  }

  /// Loads user profile data
  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;

    try {
      developer.log('ActivityProvider: Loading user profile...', name: 'ActivityProvider');
      
      _setSectionStatus(ActivitySection.userProfile, ActivityDataStatus.loading);
      
      final userProfile = await FirebaseService.getUserProfile(_currentUser!.uid);
      
      _setActivityState(_activityState.copyWith(
        userProfile: userProfile,
        sectionStatus: {
          ..._activityState.sectionStatus,
          ActivitySection.userProfile: ActivityDataStatus.loaded,
        },
      ));
      
      developer.log('ActivityProvider: User profile loaded: ${userProfile?.displayName}', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Failed to load user profile: $e', name: 'ActivityProvider');
      _setSectionStatus(ActivitySection.userProfile, ActivityDataStatus.error);
    }
  }

  /// Loads today's activity data
  Future<void> _loadTodaysActivityData() async {
    if (_currentUser == null) return;

    try {
      developer.log('ActivityProvider: Loading activity data...', name: 'ActivityProvider');
      
      _setSectionStatus(ActivitySection.activityData, ActivityDataStatus.loading);
      
      final today = DateTime.now();
      final activityData = await FirebaseService.getActivityData(_currentUser!.uid, today);
      
      _setActivityState(_activityState.copyWith(
        activityData: activityData,
        sectionStatus: {
          ..._activityState.sectionStatus,
          ActivitySection.activityData: ActivityDataStatus.loaded,
        },
      ));
      
      developer.log('ActivityProvider: Activity data loaded: ${activityData?.steps} steps', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Failed to load activity data: $e', name: 'ActivityProvider');
      _setSectionStatus(ActivitySection.activityData, ActivityDataStatus.error);
    }
  }

  /// Loads today's hydration data
  Future<void> _loadTodaysHydrationData() async {
    if (_currentUser == null) return;

    try {
      developer.log('ActivityProvider: Loading hydration data...', name: 'ActivityProvider');
      
      _setSectionStatus(ActivitySection.hydrationData, ActivityDataStatus.loading);
      
      final today = DateTime.now();
      final hydrationData = await FirebaseService.getHydrationData(_currentUser!.uid, today);
      
      _setActivityState(_activityState.copyWith(
        hydrationData: hydrationData,
        sectionStatus: {
          ..._activityState.sectionStatus,
          ActivitySection.hydrationData: ActivityDataStatus.loaded,
        },
      ));
      
      developer.log('ActivityProvider: Hydration data loaded: ${hydrationData?.waterIntake}L', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Failed to load hydration data: $e', name: 'ActivityProvider');
      _setSectionStatus(ActivitySection.hydrationData, ActivityDataStatus.error);
    }
  }

  /// Sets the status of a specific section
  void _setSectionStatus(ActivitySection section, ActivityDataStatus status) {
    final updatedSectionStatus = Map<ActivitySection, ActivityDataStatus>.from(_activityState.sectionStatus);
    updatedSectionStatus[section] = status;
    
    _setActivityState(_activityState.copyWith(
      sectionStatus: updatedSectionStatus,
    ));
  }

  /// Sets up real-time stream listeners
  void _setupStreamListeners() {
    if (_currentUser == null) return;

    developer.log('ActivityProvider: Setting up stream listeners...', name: 'ActivityProvider');
    
    final today = DateTime.now();
    final userId = _currentUser!.uid;

    // Activity data stream
    _streamSubscriptions['activity'] = FirebaseService
        .streamActivityData(userId, today)
        .listen(
      (ActivityModel? activity) {
        developer.log('ActivityProvider: Activity stream update: ${activity?.steps} steps', name: 'ActivityProvider');
        _setActivityState(_activityState.copyWith(
          activityData: activity,
          lastUpdated: DateTime.now(),
        ));
      },
      onError: (error) {
        developer.log('ActivityProvider: Activity stream error: $error', name: 'ActivityProvider');
      },
    );

    // Hydration data stream
    _streamSubscriptions['hydration'] = FirebaseService
        .streamHydrationData(userId, today)
        .listen(
      (HydrationModel? hydration) {
        developer.log('ActivityProvider: Hydration stream update: ${hydration?.waterIntake}L', name: 'ActivityProvider');
        _setActivityState(_activityState.copyWith(
          hydrationData: hydration,
          lastUpdated: DateTime.now(),
        ));
      },
      onError: (error) {
        developer.log('ActivityProvider: Hydration stream error: $error', name: 'ActivityProvider');
      },
    );

    developer.log('ActivityProvider: Stream listeners setup complete', name: 'ActivityProvider');
  }

  /// Starts periodic refresh timer
  void _startPeriodicRefresh() {
    // Refresh data every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_activityState.needsRefresh) {
        developer.log('ActivityProvider: Performing periodic refresh', name: 'ActivityProvider');
        refreshData();
      }
    });
  }

  /// Refreshes all data or specific sections
  Future<void> refreshData({Set<ActivitySection>? sectionsToRefresh}) async {
    if (_currentUser == null) return;
    if (!_hasInternetConnection) {
      developer.log('ActivityProvider: Skipping refresh - no internet connection', name: 'ActivityProvider');
      return;
    }

    developer.log('ActivityProvider: Refreshing data...', name: 'ActivityProvider');
    
    _setActivityState(_activityState.copyWith(
      isRefreshing: true,
      errorMessage: null,
    ));

    try {
      final sectionsToLoad = sectionsToRefresh ?? {
        ActivitySection.userProfile,
        ActivitySection.activityData,
        ActivitySection.hydrationData,
      };

      final futures = <Future<void>>[];
      
      if (sectionsToLoad.contains(ActivitySection.userProfile)) {
        futures.add(_loadUserProfile());
      }
      
      if (sectionsToLoad.contains(ActivitySection.activityData)) {
        futures.add(_loadTodaysActivityData());
      }
      
      if (sectionsToLoad.contains(ActivitySection.hydrationData)) {
        futures.add(_loadTodaysHydrationData());
      }

      await Future.wait(futures);

      _setActivityState(_activityState.copyWith(
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        status: ActivityDataStatus.loaded,
      ));

      developer.log('ActivityProvider: Data refresh completed', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Data refresh failed: $e', name: 'ActivityProvider');
      _setActivityState(_activityState.copyWith(
        isRefreshing: false,
        errorMessage: 'Failed to refresh data: ${e.toString()}',
      ));
    }
  }

  /// Increments steps by the given amount
  Future<void> incrementSteps(int additionalSteps) async {
    if (_currentUser == null) return;

    try {
      developer.log('ActivityProvider: Adding $additionalSteps steps...', name: 'ActivityProvider');
      
      final today = DateTime.now();
      final currentActivity = _activityState.activityData ?? 
          await FirebaseService.getActivityData(_currentUser!.uid, today);
      
      final userWeight = _activityState.userWeight;
      final newSteps = (currentActivity?.steps ?? 0) + additionalSteps;
      final distance = ActivityModel.estimateDistance(newSteps);
      final calories = ActivityModel.estimateCalories(newSteps, userWeight);

      final updatedActivity = ActivityModel(
        id: currentActivity?.id ?? '',
        userId: _currentUser!.uid,
        date: today,
        steps: newSteps,
        distance: distance,
        calories: calories,
        activeMinutes: currentActivity?.activeMinutes ?? 0,
        createdAt: currentActivity?.createdAt ?? today,
        updatedAt: today,
      );

      await FirebaseService.saveActivityData(updatedActivity);

      // Update local state immediately for better UX
      _setActivityState(_activityState.copyWith(
        activityData: updatedActivity,
        lastUpdated: DateTime.now(),
      ));

      // Add success message
      _addMessage('Added $additionalSteps steps successfully!');
      
      developer.log('ActivityProvider: Steps updated to ${updatedActivity.steps}', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Failed to add steps: $e', name: 'ActivityProvider');
      _addMessage('Failed to add steps: ${e.toString()}');
    }
  }

  /// Adds water intake by the given amount (in liters)
  Future<void> addWaterIntake(double amount) async {
    if (_currentUser == null) return;

    try {
      developer.log('ActivityProvider: Adding ${amount}L of water...', name: 'ActivityProvider');
      
      final today = DateTime.now();
      final entry = WaterEntry(
        amount: amount,
        timestamp: today,
      );

      await FirebaseService.addWaterEntry(_currentUser!.uid, today, entry);

      // Add success message
      final milliliters = (amount * 1000).toInt();
      _addMessage('Added ${milliliters}ml of water successfully!');
      
      developer.log('ActivityProvider: Water entry added: ${amount}L', name: 'ActivityProvider');
    } catch (e) {
      developer.log('ActivityProvider: Failed to add water: $e', name: 'ActivityProvider');
      _addMessage('Failed to add water: ${e.toString()}');
    }
  }

  /// Updates step goal
  Future<void> updateStepGoal(int newGoal) async {
    if (newGoal <= 0) return;

    _setActivityState(_activityState.copyWith(stepGoal: newGoal));
    developer.log('ActivityProvider: Step goal updated to $newGoal', name: 'ActivityProvider');
    
    // Here you could also save the goal to Firebase if needed
    _addMessage('Step goal updated to $newGoal steps!');
  }

  /// Updates water goal
  Future<void> updateWaterGoal(double newGoal) async {
    if (newGoal <= 0) return;

    _setActivityState(_activityState.copyWith(waterGoal: newGoal));
    developer.log('ActivityProvider: Water goal updated to ${newGoal}L', name: 'ActivityProvider');
    
    // Here you could also save the goal to Firebase if needed
    _addMessage('Water goal updated to ${newGoal}L!');
  }

  /// Adds a message to the message queue
  void _addMessage(String message) {
    final updatedMessages = List<String>.from(_activityState.messages)..add(message);
    _setActivityState(_activityState.copyWith(messages: updatedMessages));
    
    // Auto-clear message after 3 seconds
    Timer(const Duration(seconds: 3), () {
      clearMessage(message);
    });
  }

  /// Clears a specific message
  void clearMessage(String message) {
    final updatedMessages = List<String>.from(_activityState.messages)..remove(message);
    _setActivityState(_activityState.copyWith(messages: updatedMessages));
  }

  /// Clears all messages
  void clearAllMessages() {
    _setActivityState(_activityState.copyWith(messages: []));
  }

  /// Toggles notifications
  void toggleNotifications() {
    final newValue = !_activityState.notificationsEnabled;
    _setActivityState(_activityState.copyWith(notificationsEnabled: newValue));
    developer.log('ActivityProvider: Notifications ${newValue ? 'enabled' : 'disabled'}', name: 'ActivityProvider');
  }

  /// Clears any error state
  void clearError() {
    _setActivityState(_activityState.copyWith(
      status: ActivityDataStatus.loaded,
      errorMessage: null,
    ));
  }

  // ======================== STEP COUNTER METHODS ========================
  
  /// Sets the global step counter reference (called from UI)
  void setGlobalStepCounter(GlobalStepCounterProvider globalStepCounter) {
    _globalStepCounter = globalStepCounter;
    
    // Listen to step counter changes
    _globalStepCounter!.addListener(_onGlobalStepCounterChanged);
    
    developer.log('ActivityProvider: Connected to GlobalStepCounterProvider', name: 'ActivityProvider');
    notifyListeners(); // Trigger UI update with new step data
  }
  
  /// Called when global step counter changes
  void _onGlobalStepCounterChanged() {
    // Trigger UI update when step count changes
    notifyListeners();
  }

  // NOTE: All step counter methods removed - ActivityProvider now uses GlobalStepCounterProvider
  // Step counting functionality is handled by the global step counter

  /// Disposes of resources
  @override
  void dispose() {
    developer.log('ActivityProvider: Disposing...', name: 'ActivityProvider');
    
    // Remove listener from global step counter
    if (_globalStepCounter != null) {
      _globalStepCounter!.removeListener(_onGlobalStepCounterChanged);
    }
    
    // Cancel all stream subscriptions
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    
    // Dispose error handler
    _errorHandler.dispose();
    
    // Cancel refresh timer
    _refreshTimer?.cancel();
    
    super.dispose();
    
    developer.log('ActivityProvider: Disposed successfully', name: 'ActivityProvider');
  }

  /// Debug method to get current state info
  Map<String, dynamic> getDebugInfo() {
    return {
      'hasUser': _currentUser != null,
      'userId': _currentUser?.uid,
      'isConnected': _hasInternetConnection,
      'state': _activityState.toString(),
      'streamCount': _streamSubscriptions.length,
      'hasRefreshTimer': _refreshTimer?.isActive ?? false,
    };
  }
}
