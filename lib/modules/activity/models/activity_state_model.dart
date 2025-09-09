import 'package:flutter/foundation.dart';
import '../../../models/activity_model.dart';
import '../../../models/hydration_model.dart';
import '../../../models/user_model.dart';

/// Enum to represent the status of data loading/operations
enum ActivityDataStatus {
  initial,
  loading,
  loaded,
  error,
  refreshing,
}

/// Enum to represent different sections of the activity screen
enum ActivitySection {
  userProfile,
  activityData,
  hydrationData,
  all,
}

/// State model for the Activity screen
/// Manages all activity-related data and loading states
class ActivityStateModel {
  // Data properties
  final UserModel? userProfile;
  final ActivityModel? activityData;
  final HydrationModel? hydrationData;

  // Loading state properties
  final ActivityDataStatus status;
  final Map<ActivitySection, ActivityDataStatus> sectionStatus;

  // Error handling
  final String? errorMessage;
  final DateTime? lastUpdated;

  // UI state
  final bool isRefreshing;
  final bool notificationsEnabled;
  final List<String> messages;

  // Goals and settings
  final int stepGoal;
  final double waterGoal;

  // Step counter specific properties
  final bool isPedometerAvailable;
  final bool isStepCounterListening;
  final int deviceSteps;
  final int dailyStepBaseline;
  final bool isStepCounterActive;
  final String? stepCounterError;

  const ActivityStateModel({
    this.userProfile,
    this.activityData,
    this.hydrationData,
    this.status = ActivityDataStatus.initial,
    this.sectionStatus = const {},
    this.errorMessage,
    this.lastUpdated,
    this.isRefreshing = false,
    this.notificationsEnabled = true,
    this.messages = const [],
    this.stepGoal = 10000,
    this.waterGoal = 2.5,
    this.isPedometerAvailable = false,
    this.isStepCounterListening = false,
    this.deviceSteps = 0,
    this.dailyStepBaseline = 0,
    this.isStepCounterActive = false,
    this.stepCounterError,
  });

  /// Creates a copy of this state with updated fields
  ActivityStateModel copyWith({
    UserModel? userProfile,
    ActivityModel? activityData,
    HydrationModel? hydrationData,
    ActivityDataStatus? status,
    Map<ActivitySection, ActivityDataStatus>? sectionStatus,
    String? errorMessage,
    DateTime? lastUpdated,
    bool? isRefreshing,
    bool? notificationsEnabled,
    List<String>? messages,
    int? stepGoal,
    double? waterGoal,
    bool? isPedometerAvailable,
    bool? isStepCounterListening,
    int? deviceSteps,
    int? dailyStepBaseline,
    bool? isStepCounterActive,
    String? stepCounterError,
  }) {
    return ActivityStateModel(
      userProfile: userProfile ?? this.userProfile,
      activityData: activityData ?? this.activityData,
      hydrationData: hydrationData ?? this.hydrationData,
      status: status ?? this.status,
      sectionStatus: sectionStatus ?? this.sectionStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      messages: messages ?? this.messages,
      stepGoal: stepGoal ?? this.stepGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      isPedometerAvailable: isPedometerAvailable ?? this.isPedometerAvailable,
      isStepCounterListening: isStepCounterListening ?? this.isStepCounterListening,
      deviceSteps: deviceSteps ?? this.deviceSteps,
      dailyStepBaseline: dailyStepBaseline ?? this.dailyStepBaseline,
      isStepCounterActive: isStepCounterActive ?? this.isStepCounterActive,
      stepCounterError: stepCounterError ?? this.stepCounterError,
    );
  }

  /// Checks if the overall state is loading
  bool get isLoading => status == ActivityDataStatus.loading;

  /// Checks if a specific section is loading
  bool isSectionLoading(ActivitySection section) {
    return sectionStatus[section] == ActivityDataStatus.loading ||
           (sectionStatus[section] == null && status == ActivityDataStatus.loading);
  }

  /// Checks if there's an error in the overall state
  bool get hasError => status == ActivityDataStatus.error;

  /// Checks if a specific section has an error
  bool hasSectionError(ActivitySection section) {
    return sectionStatus[section] == ActivityDataStatus.error;
  }

  /// Checks if the data is loaded successfully
  bool get isLoaded => status == ActivityDataStatus.loaded;

  /// Gets current steps count (prioritizes pedometer when active)
  int get currentSteps {
    // If pedometer is available and listening, use pedometer steps
    if (isPedometerAvailable && isStepCounterListening) {
      return pedometerDailySteps;
    }
    // Otherwise use manual/Firebase steps
    return activityData?.steps ?? 0;
  }

  /// Gets manual steps count (from Firebase)
  int get manualSteps => activityData?.steps ?? 0;

  /// Gets current step progress (0.0 to 1.0)
  double get stepsProgress => (currentSteps / stepGoal).clamp(0.0, 1.0);

  /// Gets current distance in km
  double get currentDistance => activityData?.distance ?? 0.0;

  /// Gets current calories burned
  double get currentCalories => activityData?.calories ?? 0.0;

  /// Gets current water intake in liters
  double get currentWaterIntake => hydrationData?.waterIntake ?? 0.0;

  /// Gets current water intake progress (0.0 to 1.0)
  double get waterProgress => (currentWaterIntake / waterGoal).clamp(0.0, 1.0);

  /// Gets percentage of steps goal achieved
  double get stepsPercentage => (stepsProgress * 100).clamp(0.0, 100.0);

  /// Gets percentage of water goal achieved
  double get waterPercentage => (waterProgress * 100).clamp(0.0, 100.0);

  /// Gets user's name for display
  String get userName => userProfile?.displayName ?? 'User';

  /// Gets user's weight for calculations
  double get userWeight => userProfile?.weight ?? 70.0;

  /// Checks if data needs refreshing (older than 5 minutes)
  bool get needsRefresh {
    if (lastUpdated == null) return true;
    return DateTime.now().difference(lastUpdated!).inMinutes > 5;
  }

  /// Gets the number of unread messages
  int get unreadMessages => messages.length;

  /// Checks if the user has achieved their step goal
  bool get hasAchievedStepGoal => currentSteps >= stepGoal;

  /// Checks if the user has achieved their water goal
  bool get hasAchievedWaterGoal => currentWaterIntake >= waterGoal;

  /// Gets remaining steps to reach goal
  int get remainingSteps => (stepGoal - currentSteps).clamp(0, stepGoal);

  /// Gets remaining water to reach goal in liters
  double get remainingWater => (waterGoal - currentWaterIntake).clamp(0.0, waterGoal);

  /// Gets today's activity summary text
  String get activitySummary {
    if (activityData == null) return 'No activity data available';
    
    final steps = currentSteps.toString();
    final distance = currentDistance.toStringAsFixed(1);
    final calories = currentCalories.toInt().toString();
    
    return 'Today: $steps steps • $distance km • $calories cal';
  }

  /// Gets today's hydration summary text
  String get hydrationSummary {
    final intake = currentWaterIntake.toStringAsFixed(1);
    final goal = waterGoal.toStringAsFixed(1);
    final percentage = waterPercentage.toInt();
    
    return '$intake L of $goal L ($percentage%)';
  }

  /// Gets current daily steps from pedometer
  int get pedometerDailySteps => (deviceSteps - dailyStepBaseline).clamp(0, deviceSteps);

  /// Gets the effective current steps (combines manual + pedometer)
  int get effectiveSteps => isPedometerAvailable && isStepCounterListening ? pedometerDailySteps : currentSteps;

  /// Gets step counter status text
  String get stepCounterStatus {
    if (!isPedometerAvailable) return 'Pedometer not available';
    if (stepCounterError != null) return 'Error: $stepCounterError';
    if (isStepCounterListening) return 'Active';
    return 'Inactive';
  }

  /// Checks if step counter has an error
  bool get hasStepCounterError => stepCounterError != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is ActivityStateModel &&
        other.userProfile == userProfile &&
        other.activityData == activityData &&
        other.hydrationData == hydrationData &&
        other.status == status &&
        mapEquals(other.sectionStatus, sectionStatus) &&
        other.errorMessage == errorMessage &&
        other.lastUpdated == lastUpdated &&
        other.isRefreshing == isRefreshing &&
        other.notificationsEnabled == notificationsEnabled &&
        listEquals(other.messages, messages) &&
        other.stepGoal == stepGoal &&
        other.waterGoal == waterGoal &&
        other.isPedometerAvailable == isPedometerAvailable &&
        other.isStepCounterListening == isStepCounterListening &&
        other.deviceSteps == deviceSteps &&
        other.dailyStepBaseline == dailyStepBaseline &&
        other.isStepCounterActive == isStepCounterActive &&
        other.stepCounterError == stepCounterError;
  }

  @override
  int get hashCode {
    return Object.hash(
      userProfile,
      activityData,
      hydrationData,
      status,
      sectionStatus,
      errorMessage,
      lastUpdated,
      isRefreshing,
      notificationsEnabled,
      messages,
      stepGoal,
      waterGoal,
      isPedometerAvailable,
      isStepCounterListening,
      deviceSteps,
      dailyStepBaseline,
      isStepCounterActive,
      stepCounterError,
    );
  }

  @override
  String toString() {
    return 'ActivityStateModel('
        'status: $status, '
        'steps: $currentSteps/$stepGoal, '
        'water: ${currentWaterIntake.toStringAsFixed(1)}L/${waterGoal.toStringAsFixed(1)}L, '
        'isRefreshing: $isRefreshing, '
        'hasError: $hasError'
        ')';
  }
}
