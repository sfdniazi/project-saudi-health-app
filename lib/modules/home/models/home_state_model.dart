import '../../../models/user_model.dart';
import '../../../models/activity_model.dart';
import '../../../models/hydration_model.dart';
import '../../../models/food_model.dart';
import '../../../models/recommendation_model.dart';

enum HomeDataStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

enum HomeSection {
  userProfile,
  activityData,
  hydrationData,
  foodLogData,
  recommendations,
  all,
}

class HomeStateModel {
  final HomeDataStatus status;
  final String? errorMessage;
  final String? successMessage;
  
  // Data fields
  final UserModel? userProfile;
  final ActivityModel? activityData;
  final HydrationModel? hydrationData;
  final FoodLogModel? foodLogData;
  final List<RecommendationModel> recommendations;
  
  // Loading states for individual sections
  final Set<HomeSection> loadingSections;
  
  // Settings
  final bool notificationsEnabled;
  final DateTime lastRefreshTime;

  HomeStateModel({
    this.status = HomeDataStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.userProfile,
    this.activityData,
    this.hydrationData,
    this.foodLogData,
    this.recommendations = const [],
    this.loadingSections = const {},
    this.notificationsEnabled = true,
    DateTime? lastRefreshTime,
  }) : lastRefreshTime = lastRefreshTime ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Factory constructors for common states
  factory HomeStateModel.initial() {
    return HomeStateModel(
      status: HomeDataStatus.initial,
      lastRefreshTime: DateTime.now(),
    );
  }

  factory HomeStateModel.loading({Set<HomeSection>? sections}) {
    return HomeStateModel(
      status: HomeDataStatus.loading,
      loadingSections: sections ?? {HomeSection.all},
      lastRefreshTime: DateTime.now(),
    );
  }

  factory HomeStateModel.loaded({
    UserModel? userProfile,
    ActivityModel? activityData,
    HydrationModel? hydrationData,
    FoodLogModel? foodLogData,
    List<RecommendationModel>? recommendations,
    bool? notificationsEnabled,
    String? successMessage,
  }) {
    return HomeStateModel(
      status: HomeDataStatus.loaded,
      userProfile: userProfile,
      activityData: activityData,
      hydrationData: hydrationData,
      foodLogData: foodLogData,
      recommendations: recommendations ?? [],
      notificationsEnabled: notificationsEnabled ?? true,
      successMessage: successMessage,
      lastRefreshTime: DateTime.now(),
    );
  }

  factory HomeStateModel.error(String errorMessage) {
    return HomeStateModel(
      status: HomeDataStatus.error,
      errorMessage: errorMessage,
      lastRefreshTime: DateTime.now(),
    );
  }

  factory HomeStateModel.refreshing({
    required HomeStateModel currentState,
    Set<HomeSection>? sectionsToRefresh,
  }) {
    return currentState.copyWith(
      status: HomeDataStatus.refreshing,
      loadingSections: sectionsToRefresh ?? {HomeSection.all},
      errorMessage: null,
      lastRefreshTime: DateTime.now(),
    );
  }

  /// Check if the current state is loading
  bool get isLoading => status == HomeDataStatus.loading;

  /// Check if the current state is refreshing
  bool get isRefreshing => status == HomeDataStatus.refreshing;

  /// Check if currently loading any data
  bool get isLoadingAnyData => isLoading || isRefreshing || loadingSections.isNotEmpty;

  /// Check if there's an error
  bool get hasError => status == HomeDataStatus.error;

  /// Check if data is loaded
  bool get isLoaded => status == HomeDataStatus.loaded;

  /// Check if a specific section is loading
  bool isSectionLoading(HomeSection section) {
    return loadingSections.contains(section) || loadingSections.contains(HomeSection.all);
  }

  /// Check if we have user profile data
  bool get hasUserProfile => userProfile != null;

  /// Check if we have activity data for today
  bool get hasActivityData => activityData != null;

  /// Check if we have hydration data for today
  bool get hasHydrationData => hydrationData != null;

  /// Check if we have food log data for today
  bool get hasFoodLogData => foodLogData != null;

  /// Check if we have recommendations
  bool get hasRecommendations => recommendations.isNotEmpty;

  /// Get current steps count
  int get currentSteps => activityData?.steps ?? 0;

  /// Get current water intake
  double get currentWaterIntake => hydrationData?.waterIntake ?? 0.0;

  /// Get current calories consumed
  double get currentCalories => foodLogData?.totalCalories ?? 0.0;

  /// Get daily calorie goal
  double get calorieGoal => (userProfile?.calculatedDailyGoal ?? 2000).toDouble();

  /// Get water goal
  double get waterGoal => hydrationData?.goalAmount ?? 2.5;

  /// Get steps goal
  int get stepsGoal => 10000;

  /// Get time since last refresh
  Duration get timeSinceLastRefresh => DateTime.now().difference(lastRefreshTime);

  /// Check if data needs refresh (older than 5 minutes)
  bool get needsRefresh => timeSinceLastRefresh.inMinutes > 5;

  /// Get progress percentages
  double get stepsProgress => (currentSteps / stepsGoal).clamp(0.0, 1.0);
  double get waterProgress => (currentWaterIntake / waterGoal).clamp(0.0, 1.0);
  double get caloriesProgress => (currentCalories / calorieGoal).clamp(0.0, 1.0);

  /// Copy with new values
  HomeStateModel copyWith({
    HomeDataStatus? status,
    String? errorMessage,
    String? successMessage,
    UserModel? userProfile,
    ActivityModel? activityData,
    HydrationModel? hydrationData,
    FoodLogModel? foodLogData,
    List<RecommendationModel>? recommendations,
    Set<HomeSection>? loadingSections,
    bool? notificationsEnabled,
    DateTime? lastRefreshTime,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return HomeStateModel(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      userProfile: userProfile ?? this.userProfile,
      activityData: activityData ?? this.activityData,
      hydrationData: hydrationData ?? this.hydrationData,
      foodLogData: foodLogData ?? this.foodLogData,
      recommendations: recommendations ?? this.recommendations,
      loadingSections: loadingSections ?? this.loadingSections,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastRefreshTime: lastRefreshTime ?? this.lastRefreshTime,
    );
  }

  @override
  String toString() {
    return 'HomeStateModel{status: $status, errorMessage: $errorMessage, successMessage: $successMessage, userProfile: ${userProfile?.displayName}, hasActivityData: $hasActivityData, hasHydrationData: $hasHydrationData, hasFoodLogData: $hasFoodLogData, recommendationsCount: ${recommendations.length}, loadingSections: $loadingSections, notificationsEnabled: $notificationsEnabled, lastRefreshTime: $lastRefreshTime}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeStateModel &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.successMessage == successMessage &&
        other.userProfile == userProfile &&
        other.activityData == activityData &&
        other.hydrationData == hydrationData &&
        other.foodLogData == foodLogData &&
        other.recommendations == recommendations &&
        other.loadingSections == loadingSections &&
        other.notificationsEnabled == notificationsEnabled &&
        other.lastRefreshTime == lastRefreshTime;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        errorMessage.hashCode ^
        successMessage.hashCode ^
        userProfile.hashCode ^
        activityData.hashCode ^
        hydrationData.hashCode ^
        foodLogData.hashCode ^
        recommendations.hashCode ^
        loadingSections.hashCode ^
        notificationsEnabled.hashCode ^
        lastRefreshTime.hashCode;
  }
}
