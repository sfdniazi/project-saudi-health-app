enum DashboardPage {
  home,
  foodLogging,
  statistics,
  profile,
  activity,
}

enum NavigationStatus {
  initial,
  loading,
  navigating,
  error,
}

class DashboardStateModel {
  final int currentPageIndex;
  final DashboardPage currentPage;
  final NavigationStatus status;
  final String? errorMessage;
  final String? successMessage;
  final bool isBottomNavVisible;

  const DashboardStateModel({
    this.currentPageIndex = 0,
    this.currentPage = DashboardPage.home,
    this.status = NavigationStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.isBottomNavVisible = true,
  });

  /// Factory constructors for common states
  factory DashboardStateModel.initial() {
    return const DashboardStateModel();
  }

  factory DashboardStateModel.loading() {
    return const DashboardStateModel(status: NavigationStatus.loading);
  }

  factory DashboardStateModel.navigating({
    required int pageIndex,
    required DashboardPage page,
    bool isBottomNavVisible = true,
  }) {
    return DashboardStateModel(
      currentPageIndex: pageIndex,
      currentPage: page,
      status: NavigationStatus.navigating,
      isBottomNavVisible: isBottomNavVisible,
    );
  }

  factory DashboardStateModel.error(String errorMessage) {
    return DashboardStateModel(
      status: NavigationStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Check if the current state is loading
  bool get isLoading => status == NavigationStatus.loading;

  /// Check if currently navigating
  bool get isNavigating => status == NavigationStatus.navigating;

  /// Check if there's an error
  bool get hasError => status == NavigationStatus.error;

  /// Get page name as string
  String get pageTitle {
    switch (currentPage) {
      case DashboardPage.home:
        return 'Home';
      case DashboardPage.foodLogging:
        return 'Food Log';
      case DashboardPage.statistics:
        return 'Statistics';
      case DashboardPage.profile:
        return 'Profile';
      case DashboardPage.activity:
        return 'Activity';
    }
  }

  /// Get page icon
  String get pageIcon {
    switch (currentPage) {
      case DashboardPage.home:
        return 'home';

      case DashboardPage.foodLogging:
        return 'restaurant';
      case DashboardPage.statistics:
        return 'analytics';
      case DashboardPage.profile:
        return 'person';
      case DashboardPage.activity:
        return 'fitness_center';
    }
  }

  /// Copy with new values
  DashboardStateModel copyWith({
    int? currentPageIndex,
    DashboardPage? currentPage,
    NavigationStatus? status,
    String? errorMessage,
    String? successMessage,
    bool? isBottomNavVisible,
  }) {
    return DashboardStateModel(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isBottomNavVisible: isBottomNavVisible ?? this.isBottomNavVisible,
    );
  }

  @override
  String toString() {
    return 'DashboardStateModel{currentPageIndex: $currentPageIndex, currentPage: $currentPage, status: $status, errorMessage: $errorMessage, successMessage: $successMessage, isBottomNavVisible: $isBottomNavVisible}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DashboardStateModel &&
        other.currentPageIndex == currentPageIndex &&
        other.currentPage == currentPage &&
        other.status == status &&
        other.errorMessage == errorMessage &&
        other.successMessage == successMessage &&
        other.isBottomNavVisible == isBottomNavVisible;
  }

  @override
  int get hashCode {
    return currentPageIndex.hashCode ^
        currentPage.hashCode ^
        status.hashCode ^
        errorMessage.hashCode ^
        successMessage.hashCode ^
        isBottomNavVisible.hashCode;
  }
}
