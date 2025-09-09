import '../../../models/user_model.dart';
import '../../../models/food_model.dart';
import '../utils/responsive_layout_utils.dart';

/// Enumeration for different sections of the statistics screen
enum StatisticsSection {
  userProfile,
  latestMetrics,
  weeklyActivity,
  weightProgress,
  nutritionStats,
}

/// Enumeration for data loading status
enum StatisticsDataStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

/// Model for weekly activity data
class WeeklyActivityData {
  final DateTime date;
  final double calories;
  final int steps;
  final double distance;
  final String dayOfWeek;

  const WeeklyActivityData({
    required this.date,
    required this.calories,
    required this.steps,
    required this.distance,
    required this.dayOfWeek,
  });

  factory WeeklyActivityData.fromFoodLog(FoodLogModel? foodLog, DateTime date) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayOfWeek = dayNames[date.weekday - 1];
    
    return WeeklyActivityData(
      date: date,
      calories: foodLog?.totalCalories ?? 0.0,
      steps: 0, // Will be updated from activity data if available
      distance: 0.0, // Will be updated from activity data if available
      dayOfWeek: dayOfWeek,
    );
  }
}

/// Model for weight history entry
class WeightHistoryEntry {
  final double weight;
  final DateTime timestamp;

  const WeightHistoryEntry({
    required this.weight,
    required this.timestamp,
  });
}

/// Model for nutrition statistics
class NutritionStats {
  final double avgCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final double weeklyCaloriesGoal;
  final double currentProgress;

  const NutritionStats({
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.weeklyCaloriesGoal,
    required this.currentProgress,
  });
}

/// User preferences for statistics display
class StatisticsPreferences {
  final ViewMode viewMode;
  final ChartDisplayMode chartDisplayMode;
  final bool isChartsCollapsed;
  final bool isTablesCollapsed;
  final bool showDeleteButtons;
  final int itemsPerPage;
  final bool autoRefreshEnabled;
  
  const StatisticsPreferences({
    this.viewMode = ViewMode.detailed,
    this.chartDisplayMode = ChartDisplayMode.full,
    this.isChartsCollapsed = false,
    this.isTablesCollapsed = false,
    this.showDeleteButtons = false,
    this.itemsPerPage = 7,
    this.autoRefreshEnabled = true,
  });
  
  StatisticsPreferences copyWith({
    ViewMode? viewMode,
    ChartDisplayMode? chartDisplayMode,
    bool? isChartsCollapsed,
    bool? isTablesCollapsed,
    bool? showDeleteButtons,
    int? itemsPerPage,
    bool? autoRefreshEnabled,
  }) {
    return StatisticsPreferences(
      viewMode: viewMode ?? this.viewMode,
      chartDisplayMode: chartDisplayMode ?? this.chartDisplayMode,
      isChartsCollapsed: isChartsCollapsed ?? this.isChartsCollapsed,
      isTablesCollapsed: isTablesCollapsed ?? this.isTablesCollapsed,
      showDeleteButtons: showDeleteButtons ?? this.showDeleteButtons,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
    );
  }
}

/// Deletion state for tracking ongoing delete operations
class DeletionState {
  final Set<String> deletingItemIds;
  final Map<String, dynamic> deletedItems; // For undo functionality
  final bool showUndoOption;
  
  const DeletionState({
    this.deletingItemIds = const {},
    this.deletedItems = const {},
    this.showUndoOption = false,
  });
  
  DeletionState copyWith({
    Set<String>? deletingItemIds,
    Map<String, dynamic>? deletedItems,
    bool? showUndoOption,
  }) {
    return DeletionState(
      deletingItemIds: deletingItemIds ?? this.deletingItemIds,
      deletedItems: deletedItems ?? this.deletedItems,
      showUndoOption: showUndoOption ?? this.showUndoOption,
    );
  }
}

/// State model for statistics screen with provider pattern
class StatisticsStateModel {
  final StatisticsDataStatus status;
  final Map<StatisticsSection, StatisticsDataStatus> sectionStatus;
  final UserModel? userProfile;
  final List<WeeklyActivityData> weeklyActivityData;
  final List<WeightHistoryEntry> weightHistory;
  final double? latestWeight;
  final double todayCalories;
  final NutritionStats? nutritionStats;
  final List<String> messages;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool notificationsEnabled;
  final bool isRefreshing;
  final StatisticsPreferences preferences;
  final DeletionState deletionState;
  final int currentPage;
  final bool hasMoreData;

  const StatisticsStateModel({
    this.status = StatisticsDataStatus.initial,
    this.sectionStatus = const {},
    this.userProfile,
    this.weeklyActivityData = const [],
    this.weightHistory = const [],
    this.latestWeight,
    this.todayCalories = 0.0,
    this.nutritionStats,
    this.messages = const [],
    this.errorMessage,
    this.lastUpdated,
    this.notificationsEnabled = true,
    this.isRefreshing = false,
    this.preferences = const StatisticsPreferences(),
    this.deletionState = const DeletionState(),
    this.currentPage = 0,
    this.hasMoreData = false,
  });

  /// Computed getters for convenience
  bool get isLoading => status == StatisticsDataStatus.loading;
  bool get hasError => status == StatisticsDataStatus.error;
  bool get isInitial => status == StatisticsDataStatus.initial;
  bool get isLoaded => status == StatisticsDataStatus.loaded;

  /// Section-specific loading states
  bool isSectionLoading(StatisticsSection section) =>
      sectionStatus[section] == StatisticsDataStatus.loading;

  bool hasSectionError(StatisticsSection section) =>
      sectionStatus[section] == StatisticsDataStatus.error;

  bool isSectionLoaded(StatisticsSection section) =>
      sectionStatus[section] == StatisticsDataStatus.loaded;

  /// User profile data getters
  String get displayName => userProfile?.displayName ?? '';
  int get userAge => userProfile?.age ?? 25;
  double get userWeight => userProfile?.weight ?? 70.0;
  double get idealWeight => userProfile?.idealWeight ?? 65.0;
  
  /// Weekly target calories based on age
  double get weeklyTargetCalories {
    if (userAge < 18) return 1500.0;
    if (userAge < 30) return 2000.0;
    if (userAge < 50) return 1800.0;
    return 1600.0;
  }

  /// Progress calculations
  double get weightProgress {
    if (latestWeight == null || idealWeight == 0) return 0.0;
    if (latestWeight! <= idealWeight) return 1.0;
    
    final initialWeight = userWeight;
    final totalLoss = initialWeight - idealWeight;
    final currentLoss = initialWeight - latestWeight!;
    
    return (currentLoss / totalLoss).clamp(0.0, 1.0);
  }

  /// Has weight history data
  bool get hasWeightHistory => weightHistory.isNotEmpty;
  
  /// Has weekly activity data
  bool get hasWeeklyActivity => weeklyActivityData.isNotEmpty;

  /// Data freshness check
  bool get needsRefresh {
    if (lastUpdated == null) return true;
    if (!preferences.autoRefreshEnabled) return false;
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    return difference.inMinutes > 10; // Refresh after 10 minutes
  }
  
  /// Get paginated weight history
  List<WeightHistoryEntry> get paginatedWeightHistory {
    final startIndex = currentPage * preferences.itemsPerPage;
    final endIndex = (startIndex + preferences.itemsPerPage).clamp(0, weightHistory.length);
    
    if (startIndex >= weightHistory.length) return [];
    return weightHistory.sublist(startIndex, endIndex);
  }
  
  /// Get paginated weekly activity data
  List<WeeklyActivityData> get paginatedWeeklyData {
    final startIndex = currentPage * preferences.itemsPerPage;
    final endIndex = (startIndex + preferences.itemsPerPage).clamp(0, weeklyActivityData.length);
    
    if (startIndex >= weeklyActivityData.length) return [];
    return weeklyActivityData.sublist(startIndex, endIndex);
  }
  
  /// Check if item is being deleted
  bool isItemBeingDeleted(String itemId) {
    return deletionState.deletingItemIds.contains(itemId);
  }
  
  /// Check if can undo deletion
  bool get canUndo => deletionState.showUndoOption && deletionState.deletedItems.isNotEmpty;

  /// Create copy with updated values
  StatisticsStateModel copyWith({
    StatisticsDataStatus? status,
    Map<StatisticsSection, StatisticsDataStatus>? sectionStatus,
    UserModel? userProfile,
    List<WeeklyActivityData>? weeklyActivityData,
    List<WeightHistoryEntry>? weightHistory,
    double? latestWeight,
    double? todayCalories,
    NutritionStats? nutritionStats,
    List<String>? messages,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? notificationsEnabled,
    bool? isRefreshing,
    StatisticsPreferences? preferences,
    DeletionState? deletionState,
    int? currentPage,
    bool? hasMoreData,
  }) {
    return StatisticsStateModel(
      status: status ?? this.status,
      sectionStatus: sectionStatus ?? this.sectionStatus,
      userProfile: userProfile ?? this.userProfile,
      weeklyActivityData: weeklyActivityData ?? this.weeklyActivityData,
      weightHistory: weightHistory ?? this.weightHistory,
      latestWeight: latestWeight ?? this.latestWeight,
      todayCalories: todayCalories ?? this.todayCalories,
      nutritionStats: nutritionStats ?? this.nutritionStats,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      preferences: preferences ?? this.preferences,
      deletionState: deletionState ?? this.deletionState,
      currentPage: currentPage ?? this.currentPage,
      hasMoreData: hasMoreData ?? this.hasMoreData,
    );
  }

  @override
  String toString() {
    return 'StatisticsStateModel('
        'status: $status, '
        'sectionStatus: $sectionStatus, '
        'hasProfile: ${userProfile != null}, '
        'weeklyActivityCount: ${weeklyActivityData.length}, '
        'weightHistoryCount: ${weightHistory.length}, '
        'latestWeight: $latestWeight, '
        'todayCalories: $todayCalories, '
        'messagesCount: ${messages.length}, '
        'errorMessage: $errorMessage, '
        'lastUpdated: $lastUpdated, '
        'notificationsEnabled: $notificationsEnabled, '
        'isRefreshing: $isRefreshing, '
        'preferences: $preferences, '
        'deletionState: $deletionState, '
        'currentPage: $currentPage, '
        'hasMoreData: $hasMoreData'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StatisticsStateModel &&
        other.status == status &&
        other.sectionStatus.toString() == sectionStatus.toString() &&
        other.userProfile == userProfile &&
        other.weeklyActivityData.toString() == weeklyActivityData.toString() &&
        other.weightHistory.toString() == weightHistory.toString() &&
        other.latestWeight == latestWeight &&
        other.todayCalories == todayCalories &&
        other.nutritionStats == nutritionStats &&
        other.messages.toString() == messages.toString() &&
        other.errorMessage == errorMessage &&
        other.lastUpdated == lastUpdated &&
        other.notificationsEnabled == notificationsEnabled &&
        other.isRefreshing == isRefreshing &&
        other.preferences == preferences &&
        other.deletionState == deletionState &&
        other.currentPage == currentPage &&
        other.hasMoreData == hasMoreData;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      sectionStatus.toString(),
      userProfile,
      weeklyActivityData.toString(),
      weightHistory.toString(),
      latestWeight,
      todayCalories,
      nutritionStats,
      messages.toString(),
      errorMessage,
      lastUpdated,
      notificationsEnabled,
      isRefreshing,
      preferences,
      deletionState,
      currentPage,
      hasMoreData,
    );
  }
}
