import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/home_state_model.dart';
import '../../../models/user_model.dart';
import '../../../models/activity_model.dart';
import '../../../models/hydration_model.dart';
import '../../../models/food_model.dart';
import '../../../models/recommendation_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/global_step_counter_provider.dart';

class HomeProvider with ChangeNotifier {
  // Private fields
  HomeStateModel _homeState = HomeStateModel.initial();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Map<String, StreamSubscription> _streamSubscriptions = {};
  Timer? _refreshTimer;
  GlobalStepCounterProvider? _globalStepCounter;
  
  // Getters
  HomeStateModel get homeState => _homeState;
  bool get isLoading => _homeState.isLoading;
  bool get isRefreshing => _homeState.isRefreshing;
  bool get isLoadingAnyData => _homeState.isLoadingAnyData;
  bool get hasError => _homeState.hasError;
  bool get isLoaded => _homeState.isLoaded;
  String? get errorMessage => _homeState.errorMessage;
  String? get successMessage => _homeState.successMessage;
  
  // Data getters
  UserModel? get userProfile => _homeState.userProfile;
  ActivityModel? get activityData => _homeState.activityData;
  HydrationModel? get hydrationData => _homeState.hydrationData;
  FoodLogModel? get foodLogData => _homeState.foodLogData;
  List<RecommendationModel> get recommendations => _homeState.recommendations;
  bool get notificationsEnabled => _homeState.notificationsEnabled;
  
  // Progress getters
  double get stepsProgress => (currentSteps / stepsGoal).clamp(0.0, 1.0);
  double get waterProgress => _homeState.waterProgress;
  double get caloriesProgress => _homeState.caloriesProgress;
  
  /// Gets current steps from global step counter if available, otherwise from Firebase
  int get currentSteps {
    if (_globalStepCounter != null && _globalStepCounter!.isInitialized) {
      return _globalStepCounter!.primarySteps;
    }
    return _homeState.currentSteps;
  }
  
  double get currentWaterIntake => _homeState.currentWaterIntake;
  double get currentCalories => _homeState.currentCalories;
  double get calorieGoal => _homeState.calorieGoal;
  double get waterGoal => _homeState.waterGoal;
  int get stepsGoal => _homeState.stepsGoal;

  /// Initialize home provider
  HomeProvider() {
    _initializeHomeData();
  }

  void _initializeHomeData() {
    // Listen to auth state changes
    _firebaseAuth.authStateChanges().listen((User? user) {
      if (user != null) {
        _connectToGlobalStepCounter();
        _loadInitialData();
        _setupStreamListeners();
        _startPeriodicRefresh();
      } else {
        _clearData();
      }
    });
  }

  /// Connects to global step counter provider for real-time step updates
  void _connectToGlobalStepCounter() {
    // Note: We can't use context.read here, so we'll need to get it in a different way
    // This will be set from outside when the provider is initialized
    debugPrint('HomeProvider: Ready to connect to GlobalStepCounterProvider');
  }
  
  /// Sets the global step counter reference (called from UI)
  void setGlobalStepCounter(GlobalStepCounterProvider globalStepCounter) {
    _globalStepCounter = globalStepCounter;
    
    // Listen to step counter changes
    _globalStepCounter!.addListener(_onGlobalStepCounterChanged);
    
    debugPrint('HomeProvider: Connected to GlobalStepCounterProvider');
    notifyListeners(); // Trigger UI update with new step data
  }
  
  /// Called when global step counter changes
  void _onGlobalStepCounterChanged() {
    // Trigger UI update when step count changes
    notifyListeners();
  }

  /// Set home state and notify listeners
  void _setHomeState(HomeStateModel state) {
    _homeState = state;
    notifyListeners();
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Load initial data for home screen
  Future<void> _loadInitialData() async {
    try {
      _setHomeState(HomeStateModel.loading());

      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Load user profile first
      await _loadUserProfile();
      
      // Load other data in parallel
      await Future.wait([
        _loadTodaysActivityData(),
        _loadTodaysHydrationData(),
        _loadTodaysFoodLogData(),
        _loadRecommendations(),
      ]);

      _setHomeState(HomeStateModel.loaded(
        userProfile: _homeState.userProfile,
        activityData: _homeState.activityData,
        hydrationData: _homeState.hydrationData,
        foodLogData: _homeState.foodLogData,
        recommendations: _homeState.recommendations,
        notificationsEnabled: _homeState.notificationsEnabled,
        successMessage: 'Home data loaded successfully',
      ));
    } catch (e) {
      _setHomeState(HomeStateModel.error(e.toString()));
      debugPrint('Error loading initial home data: $e');
    }
  }

  /// Load user profile
  Future<void> _loadUserProfile() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      _setHomeState(_homeState.copyWith(
        loadingSections: {..._homeState.loadingSections, HomeSection.userProfile},
      ));

      final profile = await FirebaseService.getUserProfile(user.uid);
      
      _setHomeState(_homeState.copyWith(
        userProfile: profile,
        loadingSections: _homeState.loadingSections..remove(HomeSection.userProfile),
      ));
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      _setHomeState(_homeState.copyWith(
        loadingSections: _homeState.loadingSections..remove(HomeSection.userProfile),
      ));
    }
  }

  /// Load today's activity data
  Future<void> _loadTodaysActivityData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      _setHomeState(_homeState.copyWith(
        loadingSections: {..._homeState.loadingSections, HomeSection.activityData},
      ));

      final today = DateTime.now();
      final activityStream = FirebaseService.streamActivityData(user.uid, today);
      final activity = await activityStream.first;
      
      _setHomeState(_homeState.copyWith(
        activityData: activity,
        loadingSections: _homeState.loadingSections..remove(HomeSection.activityData),
      ));
    } catch (e) {
      debugPrint('Error loading activity data: $e');
      _setHomeState(_homeState.copyWith(
        loadingSections: _homeState.loadingSections..remove(HomeSection.activityData),
      ));
    }
  }

  /// Load today's hydration data
  Future<void> _loadTodaysHydrationData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      _setHomeState(_homeState.copyWith(
        loadingSections: {..._homeState.loadingSections, HomeSection.hydrationData},
      ));

      final today = DateTime.now();
      final hydrationStream = FirebaseService.streamHydrationData(user.uid, today);
      final hydration = await hydrationStream.first;
      
      _setHomeState(_homeState.copyWith(
        hydrationData: hydration,
        loadingSections: _homeState.loadingSections..remove(HomeSection.hydrationData),
      ));
    } catch (e) {
      debugPrint('Error loading hydration data: $e');
      _setHomeState(_homeState.copyWith(
        loadingSections: _homeState.loadingSections..remove(HomeSection.hydrationData),
      ));
    }
  }

  /// Load today's food log data
  Future<void> _loadTodaysFoodLogData() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      _setHomeState(_homeState.copyWith(
        loadingSections: {..._homeState.loadingSections, HomeSection.foodLogData},
      ));

      final today = DateTime.now();
      final foodLogStream = FirebaseService.streamFoodLogData(user.uid, today);
      final foodLog = await foodLogStream.first;
      
      _setHomeState(_homeState.copyWith(
        foodLogData: foodLog,
        loadingSections: _homeState.loadingSections..remove(HomeSection.foodLogData),
      ));
    } catch (e) {
      debugPrint('Error loading food log data: $e');
      _setHomeState(_homeState.copyWith(
        loadingSections: _homeState.loadingSections..remove(HomeSection.foodLogData),
      ));
    }
  }

  /// Load recommendations
  Future<void> _loadRecommendations() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      _setHomeState(_homeState.copyWith(
        loadingSections: {..._homeState.loadingSections, HomeSection.recommendations},
      ));

      final recommendationsStream = FirebaseService.streamRecommendations(user.uid);
      final recommendations = await recommendationsStream.first;
      
      _setHomeState(_homeState.copyWith(
        recommendations: recommendations,
        loadingSections: _homeState.loadingSections..remove(HomeSection.recommendations),
      ));
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
      _setHomeState(_homeState.copyWith(
        loadingSections: _homeState.loadingSections..remove(HomeSection.recommendations),
      ));
    }
  }

  /// Setup stream listeners for real-time data updates
  void _setupStreamListeners() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    _clearStreamListeners();
    final today = DateTime.now();

    // Activity stream
    _streamSubscriptions['activity'] = FirebaseService
        .streamActivityData(user.uid, today)
        .listen((activity) {
      _setHomeState(_homeState.copyWith(activityData: activity));
    });

    // Hydration stream
    _streamSubscriptions['hydration'] = FirebaseService
        .streamHydrationData(user.uid, today)
        .listen((hydration) {
      _setHomeState(_homeState.copyWith(hydrationData: hydration));
    });

    // Food log stream
    _streamSubscriptions['foodLog'] = FirebaseService
        .streamFoodLogData(user.uid, today)
        .listen((foodLog) {
      _setHomeState(_homeState.copyWith(foodLogData: foodLog));
    });

    // Recommendations stream
    _streamSubscriptions['recommendations'] = FirebaseService
        .streamRecommendations(user.uid)
        .listen((recommendations) {
      _setHomeState(_homeState.copyWith(recommendations: recommendations));
    });
  }

  /// Start periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_homeState.needsRefresh) {
        refreshData();
      }
    });
  }

  /// Refresh all data
  Future<void> refreshData({Set<HomeSection>? sectionsToRefresh}) async {
    try {
      if (_homeState.isLoading) return; // Prevent multiple simultaneous refreshes

      final sectionsToUpdate = sectionsToRefresh ?? {HomeSection.all};
      _setHomeState(HomeStateModel.refreshing(
        currentState: _homeState,
        sectionsToRefresh: sectionsToUpdate,
      ));

      final hasConnection = await _checkConnectivity();
      if (!hasConnection) {
        throw Exception('No internet connection. Please check your network and try again.');
      }

      // Refresh specific sections or all
      final refreshTasks = <Future>[];

      if (sectionsToUpdate.contains(HomeSection.all) || 
          sectionsToUpdate.contains(HomeSection.userProfile)) {
        refreshTasks.add(_loadUserProfile());
      }

      if (sectionsToUpdate.contains(HomeSection.all) || 
          sectionsToUpdate.contains(HomeSection.activityData)) {
        refreshTasks.add(_loadTodaysActivityData());
      }

      if (sectionsToUpdate.contains(HomeSection.all) || 
          sectionsToUpdate.contains(HomeSection.hydrationData)) {
        refreshTasks.add(_loadTodaysHydrationData());
      }

      if (sectionsToUpdate.contains(HomeSection.all) || 
          sectionsToUpdate.contains(HomeSection.foodLogData)) {
        refreshTasks.add(_loadTodaysFoodLogData());
      }

      if (sectionsToUpdate.contains(HomeSection.all) || 
          sectionsToUpdate.contains(HomeSection.recommendations)) {
        refreshTasks.add(_loadRecommendations());
      }

      await Future.wait(refreshTasks);

      _setHomeState(_homeState.copyWith(
        status: HomeDataStatus.loaded,
        loadingSections: <HomeSection>{},
        successMessage: 'Data refreshed successfully',
        lastRefreshTime: DateTime.now(),
      ));
    } catch (e) {
      _setHomeState(_homeState.copyWith(
        status: HomeDataStatus.error,
        errorMessage: e.toString(),
        loadingSections: <HomeSection>{},
      ));
      debugPrint('Error refreshing home data: $e');
    }
  }

  /// Check if specific section is loading
  bool isSectionLoading(HomeSection section) {
    return _homeState.isSectionLoading(section);
  }

  /// Toggle notifications
  void toggleNotifications() {
    final newValue = !_homeState.notificationsEnabled;
    _setHomeState(_homeState.copyWith(notificationsEnabled: newValue));
    
    // You can add logic here to update the setting in Firebase or SharedPreferences
    debugPrint('Notifications ${newValue ? 'enabled' : 'disabled'}');
  }

  /// Update notification settings
  void updateNotificationSettings(bool enabled) {
    _setHomeState(_homeState.copyWith(notificationsEnabled: enabled));
  }

  /// Mark recommendation as read
  Future<void> markRecommendationAsRead(String recommendationId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return;

      await FirebaseService.markRecommendationAsRead(user.uid, recommendationId);
      
      // Remove the recommendation from the current list
      final updatedRecommendations = _homeState.recommendations
          .where((rec) => rec.id != recommendationId)
          .toList();
      
      _setHomeState(_homeState.copyWith(recommendations: updatedRecommendations));
    } catch (e) {
      debugPrint('Error marking recommendation as read: $e');
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    if (_homeState.hasError || _homeState.successMessage != null) {
      _setHomeState(_homeState.copyWith(
        clearError: true,
        clearSuccess: true,
      ));
    }
  }

  /// Clear all data (used when user logs out)
  void _clearData() {
    _clearStreamListeners();
    _refreshTimer?.cancel();
    _setHomeState(HomeStateModel.initial());
  }

  /// Clear stream listeners
  void _clearStreamListeners() {
    for (final subscription in _streamSubscriptions.values) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
  }

  /// Reset to initial state
  void resetHomeData() {
    _clearData();
    _initializeHomeData();
  }

  /// Get formatted greeting message
  String get greetingMessage {
    final hour = DateTime.now().hour;
    final name = _homeState.userProfile?.displayName ?? 'there';
    
    if (hour < 12) {
      return 'Good morning, $name!';
    } else if (hour < 17) {
      return 'Good afternoon, $name!';
    } else {
      return 'Good evening, $name!';
    }
  }

  /// Get progress summary
  Map<String, dynamic> get progressSummary {
    return {
      'steps': {
        'current': currentSteps,
        'goal': stepsGoal,
        'progress': stepsProgress,
        'unit': 'steps',
      },
      'water': {
        'current': currentWaterIntake,
        'goal': waterGoal,
        'progress': waterProgress,
        'unit': 'L',
      },
      'calories': {
        'current': currentCalories,
        'goal': calorieGoal,
        'progress': caloriesProgress,
        'unit': 'kcal',
      },
    };
  }

  /// Get recommendations by type
  List<RecommendationModel> getRecommendationsByType(RecommendationType type) {
    return _homeState.recommendations.where((rec) => rec.type == type).toList();
  }

  /// Get high priority recommendations
  List<RecommendationModel> get highPriorityRecommendations {
    return _homeState.recommendations.where((rec) => rec.priority == 1).toList();
  }

  @override
  void dispose() {
    _clearStreamListeners();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
