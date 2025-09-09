import '../../../models/food_model.dart';
import '../../../models/user_model.dart';

/// Enumeration for different sections of the food logging screen
enum FoodLoggingSection {
  userProfile,
  dailySummary,
  todaysMeals,
  scanHistory,
}

/// Enumeration for data loading status
enum FoodLoggingDataStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

/// State model for food logging screen with provider pattern
class FoodLoggingStateModel {
  final FoodLoggingDataStatus status;
  final Map<FoodLoggingSection, FoodLoggingDataStatus> sectionStatus;
  final UserModel? userProfile;
  final FoodLogModel? dailyFoodLog;
  final List<Map<String, dynamic>> scanHistory;
  final DateTime selectedDate;
  final List<String> messages;
  final String? errorMessage;
  final DateTime? lastUpdated;
  final bool notificationsEnabled;
  final bool isRefreshing;

  FoodLoggingStateModel({
    this.status = FoodLoggingDataStatus.initial,
    this.sectionStatus = const {},
    this.userProfile,
    this.dailyFoodLog,
    this.scanHistory = const [],
    DateTime? selectedDate,
    this.messages = const [],
    this.errorMessage,
    this.lastUpdated,
    this.notificationsEnabled = true,
    this.isRefreshing = false,
  }) : selectedDate = selectedDate ?? DateTime.now();

  /// Create a default state with current date
  static FoodLoggingStateModel createDefault() {
    return FoodLoggingStateModel(
      status: FoodLoggingDataStatus.initial,
      sectionStatus: const {},
      userProfile: null,
      dailyFoodLog: null,
      scanHistory: const [],
      selectedDate: DateTime.now(),
      messages: const [],
      errorMessage: null,
      lastUpdated: null,
      notificationsEnabled: true,
      isRefreshing: false,
    );
  }

  /// Computed getters for convenience
  bool get isLoading => status == FoodLoggingDataStatus.loading;
  bool get hasError => status == FoodLoggingDataStatus.error;
  bool get isInitial => status == FoodLoggingDataStatus.initial;
  bool get isLoaded => status == FoodLoggingDataStatus.loaded;

  /// Section-specific loading states
  bool isSectionLoading(FoodLoggingSection section) =>
      sectionStatus[section] == FoodLoggingDataStatus.loading;

  bool hasSectionError(FoodLoggingSection section) =>
      sectionStatus[section] == FoodLoggingDataStatus.error;

  bool isSectionLoaded(FoodLoggingSection section) =>
      sectionStatus[section] == FoodLoggingDataStatus.loaded;

  /// Nutrition data getters
  double get totalCalories => dailyFoodLog?.totalCalories ?? 0.0;
  double get totalProtein => dailyFoodLog?.totalProtein ?? 0.0;
  double get totalCarbs => dailyFoodLog?.totalCarbs ?? 0.0;
  double get totalFat => dailyFoodLog?.totalFat ?? 0.0;
  
  List<FoodEntry> get todaysMeals => dailyFoodLog?.meals ?? [];
  bool get hasMeals => todaysMeals.isNotEmpty;
  
  /// User profile data getters
  String get displayName => userProfile?.displayName ?? '';
  double get userWeight => userProfile?.weight ?? 70.0; // Default weight
  
  /// Data freshness check
  bool get needsRefresh {
    if (lastUpdated == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    return difference.inMinutes > 5; // Refresh after 5 minutes
  }

  /// Create copy with updated values
  FoodLoggingStateModel copyWith({
    FoodLoggingDataStatus? status,
    Map<FoodLoggingSection, FoodLoggingDataStatus>? sectionStatus,
    UserModel? userProfile,
    FoodLogModel? dailyFoodLog,
    List<Map<String, dynamic>>? scanHistory,
    DateTime? selectedDate,
    List<String>? messages,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? notificationsEnabled,
    bool? isRefreshing,
  }) {
    return FoodLoggingStateModel(
      status: status ?? this.status,
      sectionStatus: sectionStatus ?? this.sectionStatus,
      userProfile: userProfile ?? this.userProfile,
      dailyFoodLog: dailyFoodLog ?? this.dailyFoodLog,
      scanHistory: scanHistory ?? this.scanHistory,
      selectedDate: selectedDate ?? this.selectedDate,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  String toString() {
    return 'FoodLoggingStateModel('
        'status: $status, '
        'sectionStatus: $sectionStatus, '
        'hasProfile: ${userProfile != null}, '
        'hasFoodLog: ${dailyFoodLog != null}, '
        'scanHistoryCount: ${scanHistory.length}, '
        'selectedDate: $selectedDate, '
        'messagesCount: ${messages.length}, '
        'errorMessage: $errorMessage, '
        'lastUpdated: $lastUpdated, '
        'notificationsEnabled: $notificationsEnabled, '
        'isRefreshing: $isRefreshing'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodLoggingStateModel &&
        other.status == status &&
        other.sectionStatus.toString() == sectionStatus.toString() &&
        other.userProfile == userProfile &&
        other.dailyFoodLog == dailyFoodLog &&
        other.scanHistory.toString() == scanHistory.toString() &&
        other.selectedDate == selectedDate &&
        other.messages.toString() == messages.toString() &&
        other.errorMessage == errorMessage &&
        other.lastUpdated == lastUpdated &&
        other.notificationsEnabled == notificationsEnabled &&
        other.isRefreshing == isRefreshing;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      sectionStatus.toString(),
      userProfile,
      dailyFoodLog,
      scanHistory.toString(),
      selectedDate,
      messages.toString(),
      errorMessage,
      lastUpdated,
      notificationsEnabled,
      isRefreshing,
    );
  }
}
