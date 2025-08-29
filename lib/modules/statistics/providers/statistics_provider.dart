import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../models/user_model.dart';
import '../../../models/food_model.dart';
import '../models/statistics_state_model.dart';
import '../utils/responsive_layout_utils.dart';

/// Provider for managing statistics screen state with real-time data
class StatisticsProvider extends ChangeNotifier {
  /// Private state
  StatisticsStateModel _state = const StatisticsStateModel();

  /// Stream subscriptions for real-time data
  StreamSubscription<DocumentSnapshot>? _userProfileSubscription;
  StreamSubscription<QuerySnapshot>? _weightHistorySubscription;
  StreamSubscription<QuerySnapshot>? _foodLogsSubscription;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  /// Timer for periodic data refresh
  Timer? _refreshTimer;

  /// Firebase and connectivity instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Connectivity _connectivity = Connectivity();

  /// Public state getter
  StatisticsStateModel get state => _state;

  /// Current user ID
  String? get _userId => _auth.currentUser?.uid;

  /// Constructor
  StatisticsProvider() {
    _initialize();
  }

  /// Initialize provider with connectivity monitoring
  void _initialize() {
    _setupConnectivityListener();
    _setupPeriodicRefresh();
    _loadUserPreferences();
    if (_userId != null) {
      loadStatisticsData();
    }
  }
  
  /// Load user preferences from persistent storage
  void _loadUserPreferences() {
    // In a real app, load from SharedPreferences or similar
    // For now, use default values that adapt to screen size
  }

  /// Setup connectivity listener
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _state.hasError) {
        _addMessage('Connection restored, refreshing data...');
        loadStatisticsData();
      }
    });
  }

  /// Setup periodic refresh timer
  void _setupPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_state.needsRefresh) {
        refreshData(showLoading: false);
      }
    });
  }

  /// Load all statistics data
  Future<void> loadStatisticsData() async {
    if (_userId == null) {
      _updateState(_state.copyWith(
        status: StatisticsDataStatus.error,
        errorMessage: 'User not authenticated',
      ));
      return;
    }

    _updateState(_state.copyWith(
      status: StatisticsDataStatus.loading,
      errorMessage: null,
    ));

    try {
      await Future.wait([
        _loadUserProfile(),
        _loadWeightHistory(),
        _loadFoodLogs(),
      ]);

      _updateState(_state.copyWith(
        status: StatisticsDataStatus.loaded,
        lastUpdated: DateTime.now(),
      ));

      _addMessage('Statistics updated successfully');
    } catch (e) {
      _updateState(_state.copyWith(
        status: StatisticsDataStatus.error,
        errorMessage: 'Failed to load statistics: ${e.toString()}',
      ));
    }
  }

  /// Load user profile with stream
  Future<void> _loadUserProfile() async {
    _updateSectionStatus(StatisticsSection.userProfile, StatisticsDataStatus.loading);
    
    try {
      _userProfileSubscription?.cancel();
      _userProfileSubscription = _firestore
          .collection('users')
          .doc(_userId)
          .snapshots()
          .listen(
            (snapshot) {
              if (snapshot.exists) {
                final userProfile = UserModel.fromSnapshot(snapshot);
                
                _updateState(_state.copyWith(userProfile: userProfile));
                _updateSectionStatus(StatisticsSection.userProfile, StatisticsDataStatus.loaded);
              }
            },
            onError: (error) {
              _updateSectionStatus(StatisticsSection.userProfile, StatisticsDataStatus.error);
              _addMessage('Failed to load user profile: $error');
            },
          );
    } catch (e) {
      _updateSectionStatus(StatisticsSection.userProfile, StatisticsDataStatus.error);
      throw Exception('Error setting up user profile stream: $e');
    }
  }

  /// Load weight history with stream
  Future<void> _loadWeightHistory() async {
    _updateSectionStatus(StatisticsSection.weightProgress, StatisticsDataStatus.loading);
    
    try {
      _weightHistorySubscription?.cancel();
      _weightHistorySubscription = _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_history')
          .orderBy('timestamp', descending: true)
          .limit(30) // Last 30 entries
          .snapshots()
          .listen(
            (snapshot) {
              final weightHistory = snapshot.docs.map((doc) {
                final data = doc.data();
                return WeightHistoryEntry(
                  weight: (data['weight'] as num).toDouble(),
                  timestamp: (data['timestamp'] as Timestamp).toDate(),
                );
              }).toList();

              final latestWeight = weightHistory.isNotEmpty ? weightHistory.first.weight : null;

              _updateState(_state.copyWith(
                weightHistory: weightHistory,
                latestWeight: latestWeight,
              ));
              _updateSectionStatus(StatisticsSection.weightProgress, StatisticsDataStatus.loaded);
            },
            onError: (error) {
              _updateSectionStatus(StatisticsSection.weightProgress, StatisticsDataStatus.error);
              _addMessage('Failed to load weight history: $error');
            },
          );
    } catch (e) {
      _updateSectionStatus(StatisticsSection.weightProgress, StatisticsDataStatus.error);
      throw Exception('Error setting up weight history stream: $e');
    }
  }

  /// Load food logs for weekly activity calculation
  Future<void> _loadFoodLogs() async {
    _updateSectionStatus(StatisticsSection.weeklyActivity, StatisticsDataStatus.loading);
    
    try {
      // Get date range for current week
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      
      _foodLogsSubscription?.cancel();
      _foodLogsSubscription = _firestore
          .collection('users')
          .doc(_userId)
          .collection('food_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .snapshots()
          .listen(
            (snapshot) {
              _processWeeklyActivity(snapshot, startOfWeek);
              _updateSectionStatus(StatisticsSection.weeklyActivity, StatisticsDataStatus.loaded);
            },
            onError: (error) {
              _updateSectionStatus(StatisticsSection.weeklyActivity, StatisticsDataStatus.error);
              _addMessage('Failed to load weekly activity: $error');
            },
          );
    } catch (e) {
      _updateSectionStatus(StatisticsSection.weeklyActivity, StatisticsDataStatus.error);
      throw Exception('Error setting up food logs stream: $e');
    }
  }

  /// Process weekly activity data from food logs
  void _processWeeklyActivity(QuerySnapshot snapshot, DateTime startOfWeek) {
    final weeklyData = <WeeklyActivityData>[];
    final foodLogsByDate = <DateTime, FoodLogModel>{};

    // Parse food logs by date
    for (final doc in snapshot.docs) {
      final foodLog = FoodLogModel.fromSnapshot(doc);
      final data = doc.data() as Map<String, dynamic>;
      final logDate = (data['date'] as Timestamp).toDate();
      final dateOnly = DateTime(logDate.year, logDate.month, logDate.day);
      
      foodLogsByDate[dateOnly] = foodLog;
    }

    // Generate data for each day of the week
    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final foodLog = foodLogsByDate[dateOnly];
      
      weeklyData.add(WeeklyActivityData.fromFoodLog(foodLog, date));
    }

    // Calculate today's calories
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final todayFoodLog = foodLogsByDate[todayOnly];
    final todayCalories = todayFoodLog?.totalCalories ?? 0.0;

    // Calculate nutrition stats
    final nutritionStats = _calculateNutritionStats(foodLogsByDate.values.toList());

    _updateState(_state.copyWith(
      weeklyActivityData: weeklyData,
      todayCalories: todayCalories,
      nutritionStats: nutritionStats,
    ));
  }

  /// Calculate nutrition statistics
  NutritionStats _calculateNutritionStats(List<FoodLogModel> foodLogs) {
    if (foodLogs.isEmpty) {
      return NutritionStats(
        avgCalories: 0.0,
        avgProtein: 0.0,
        avgCarbs: 0.0,
        avgFat: 0.0,
        weeklyCaloriesGoal: _state.weeklyTargetCalories * 7,
        currentProgress: 0.0,
      );
    }

    final totalCalories = foodLogs.fold(0.0, (sum, log) => sum + log.totalCalories);
    final totalProtein = foodLogs.fold(0.0, (sum, log) => sum + log.totalProtein);
    final totalCarbs = foodLogs.fold(0.0, (sum, log) => sum + log.totalCarbs);
    final totalFat = foodLogs.fold(0.0, (sum, log) => sum + log.totalFat);

    final avgCalories = totalCalories / foodLogs.length;
    final avgProtein = totalProtein / foodLogs.length;
    final avgCarbs = totalCarbs / foodLogs.length;
    final avgFat = totalFat / foodLogs.length;

    final weeklyGoal = _state.weeklyTargetCalories * 7;
    final currentProgress = (totalCalories / weeklyGoal).clamp(0.0, 1.0);

    return NutritionStats(
      avgCalories: avgCalories,
      avgProtein: avgProtein,
      avgCarbs: avgCarbs,
      avgFat: avgFat,
      weeklyCaloriesGoal: weeklyGoal,
      currentProgress: currentProgress,
    );
  }

  /// Refresh all data
  Future<void> refreshData({bool showLoading = true}) async {
    if (showLoading) {
      _updateState(_state.copyWith(isRefreshing: true));
    }

    try {
      await loadStatisticsData();
      _addMessage('Data refreshed successfully');
    } catch (e) {
      _addMessage('Failed to refresh data: ${e.toString()}');
    } finally {
      if (showLoading) {
        _updateState(_state.copyWith(isRefreshing: false));
      }
    }
  }
  
  /// Delete weight history entry
  Future<void> deleteWeightEntry(String entryId, WeightHistoryEntry entry) async {
    if (_userId == null) return;
    
    // Add to deleting set
    final updatedDeletingIds = Set<String>.from(_state.deletionState.deletingItemIds)
      ..add(entryId);
    _updateState(_state.copyWith(
      deletionState: _state.deletionState.copyWith(
        deletingItemIds: updatedDeletingIds,
      ),
    ));
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_history')
          .doc(entryId)
          .delete();
      
      // Store for undo functionality
      final updatedDeletedItems = Map<String, dynamic>.from(_state.deletionState.deletedItems)
        ..[entryId] = entry;
      
      // Remove from deleting set and show undo option
      final finalDeletingIds = Set<String>.from(updatedDeletingIds)
        ..remove(entryId);
      
      _updateState(_state.copyWith(
        deletionState: _state.deletionState.copyWith(
          deletingItemIds: finalDeletingIds,
          deletedItems: updatedDeletedItems,
          showUndoOption: true,
        ),
      ));
      
      _addMessage('Weight entry deleted successfully');
      
      // Hide undo option after 10 seconds
      _setupUndoTimer();
      
    } catch (e) {
      // Remove from deleting set on error
      final finalDeletingIds = Set<String>.from(updatedDeletingIds)
        ..remove(entryId);
      
      _updateState(_state.copyWith(
        deletionState: _state.deletionState.copyWith(
          deletingItemIds: finalDeletingIds,
        ),
      ));
      
      _addMessage('Failed to delete weight entry: ${e.toString()}');
    }
  }
  
  /// Undo weight entry deletion
  Future<void> undoWeightEntryDeletion(String entryId) async {
    if (_userId == null) return;
    
    final deletedEntry = _state.deletionState.deletedItems[entryId] as WeightHistoryEntry?;
    if (deletedEntry == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_history')
          .doc(entryId)
          .set({
        'weight': deletedEntry.weight,
        'timestamp': Timestamp.fromDate(deletedEntry.timestamp),
      });
      
      // Remove from deleted items
      final updatedDeletedItems = Map<String, dynamic>.from(_state.deletionState.deletedItems)
        ..remove(entryId);
      
      _updateState(_state.copyWith(
        deletionState: _state.deletionState.copyWith(
          deletedItems: updatedDeletedItems,
          showUndoOption: updatedDeletedItems.isNotEmpty,
        ),
      ));
      
      _addMessage('Weight entry restored successfully');
      
    } catch (e) {
      _addMessage('Failed to restore weight entry: ${e.toString()}');
    }
  }
  
  /// Setup timer to hide undo option
  void _setupUndoTimer() {
    Timer(const Duration(seconds: 10), () {
      if (_state.deletionState.showUndoOption) {
        _updateState(_state.copyWith(
          deletionState: _state.deletionState.copyWith(
            deletedItems: {},
            showUndoOption: false,
          ),
        ));
      }
    });
  }
  
  /// Update user preferences
  void updatePreferences(StatisticsPreferences preferences) {
    _updateState(_state.copyWith(preferences: preferences));
    _saveUserPreferences(preferences);
  }
  
  /// Save preferences to persistent storage
  void _saveUserPreferences(StatisticsPreferences preferences) {
    // In a real app, save to SharedPreferences or similar
    // Implementation would depend on your persistence strategy
  }
  
  /// Toggle charts collapsed state
  void toggleChartsCollapsed() {
    final newPreferences = _state.preferences.copyWith(
      isChartsCollapsed: !_state.preferences.isChartsCollapsed,
    );
    updatePreferences(newPreferences);
  }
  
  /// Toggle tables collapsed state
  void toggleTablesCollapsed() {
    final newPreferences = _state.preferences.copyWith(
      isTablesCollapsed: !_state.preferences.isTablesCollapsed,
    );
    updatePreferences(newPreferences);
  }
  
  /// Change view mode
  void setViewMode(ViewMode mode) {
    final newPreferences = _state.preferences.copyWith(viewMode: mode);
    updatePreferences(newPreferences);
  }
  
  /// Change chart display mode
  void setChartDisplayMode(ChartDisplayMode mode) {
    final newPreferences = _state.preferences.copyWith(chartDisplayMode: mode);
    updatePreferences(newPreferences);
  }
  
  /// Toggle delete buttons visibility
  void toggleDeleteButtons() {
    final newPreferences = _state.preferences.copyWith(
      showDeleteButtons: !_state.preferences.showDeleteButtons,
    );
    updatePreferences(newPreferences);
  }
  
  /// Change page
  void changePage(int page) {
    _updateState(_state.copyWith(currentPage: page));
  }
  
  /// Set items per page
  void setItemsPerPage(int itemsPerPage) {
    final newPreferences = _state.preferences.copyWith(itemsPerPage: itemsPerPage);
    updatePreferences(newPreferences);
    
    // Reset to first page when changing items per page
    _updateState(_state.copyWith(currentPage: 0));
  }
  
  /// Initialize preferences based on context
  void initializeResponsivePreferences(BuildContext context) {
    final shouldUseCompact = ResponsiveLayoutUtils.shouldUseCompactMode(context);
    final maxItemsPerPage = ResponsiveLayoutUtils.getMaxItemsPerPage(context);
    
    final responsivePreferences = _state.preferences.copyWith(
      viewMode: shouldUseCompact ? ViewMode.compact : ViewMode.detailed,
      itemsPerPage: maxItemsPerPage,
      isChartsCollapsed: shouldUseCompact,
      chartDisplayMode: shouldUseCompact 
        ? ChartDisplayMode.compressed 
        : ChartDisplayMode.full,
    );
    
    if (responsivePreferences != _state.preferences) {
      updatePreferences(responsivePreferences);
    }
  }

  /// Add a weight entry
  Future<void> addWeightEntry(double weight) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('weight_history')
          .add({
        'weight': weight,
        'timestamp': Timestamp.now(),
      });

      // Update user's current weight
      await _firestore.collection('users').doc(_userId).update({
        'weight': weight,
        'lastWeightUpdate': Timestamp.now(),
      });

      _addMessage('Weight entry added successfully');
    } catch (e) {
      _addMessage('Failed to add weight entry: ${e.toString()}');
    }
  }

  /// Toggle notifications
  Future<void> toggleNotifications() async {
    final newValue = !_state.notificationsEnabled;
    _updateState(_state.copyWith(notificationsEnabled: newValue));
    
    if (_userId != null) {
      try {
        await _firestore.collection('users').doc(_userId).update({
          'notificationsEnabled': newValue,
        });
        _addMessage(newValue ? 'Notifications enabled' : 'Notifications disabled');
      } catch (e) {
        // Revert on error
        _updateState(_state.copyWith(notificationsEnabled: !newValue));
        _addMessage('Failed to update notification settings');
      }
    }
  }

  /// Clear all messages
  void clearMessages() {
    _updateState(_state.copyWith(messages: []));
  }

  /// Private helper methods

  /// Update state and notify listeners
  void _updateState(StatisticsStateModel newState) {
    _state = newState;
    notifyListeners();
  }

  /// Update section-specific status
  void _updateSectionStatus(StatisticsSection section, StatisticsDataStatus status) {
    final newSectionStatus = Map<StatisticsSection, StatisticsDataStatus>.from(_state.sectionStatus);
    newSectionStatus[section] = status;
    
    _updateState(_state.copyWith(sectionStatus: newSectionStatus));
  }

  /// Add a message to the state
  void _addMessage(String message) {
    final messages = List<String>.from(_state.messages);
    messages.add(message);
    if (messages.length > 5) {
      messages.removeAt(0); // Keep only last 5 messages
    }
    
    _updateState(_state.copyWith(messages: messages));
  }

  /// Cleanup resources
  @override
  void dispose() {
    _userProfileSubscription?.cancel();
    _weightHistorySubscription?.cancel();
    _foodLogsSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
