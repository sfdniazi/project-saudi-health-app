import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/dashboard_state_model.dart';
import '../../../services/global_step_counter_provider.dart';

class DashboardProvider with ChangeNotifier {
  // Private fields
  DashboardStateModel _dashboardState = DashboardStateModel.initial();
  final List<DashboardPage> _navigationHistory = [DashboardPage.home];
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Global step counter reference
  GlobalStepCounterProvider? _globalStepCounter;

  // Getters
  DashboardStateModel get dashboardState => _dashboardState;
  int get currentPageIndex => _dashboardState.currentPageIndex;
  DashboardPage get currentPage => _dashboardState.currentPage;
  bool get isLoading => _dashboardState.isLoading;
  bool get isBottomNavVisible => _dashboardState.isBottomNavVisible;
  String? get errorMessage => _dashboardState.errorMessage;
  String? get successMessage => _dashboardState.successMessage;
  String get pageTitle => _dashboardState.pageTitle;
  List<DashboardPage> get navigationHistory => List.unmodifiable(_navigationHistory);
  
  // Step counter getters
  int get currentSteps {
    if (_globalStepCounter != null && _globalStepCounter!.isInitialized) {
      return _globalStepCounter!.primarySteps;
    }
    return 0;
  }

  /// Initialize dashboard provider
  DashboardProvider() {
    _initializeDashboard();
  }

  void _initializeDashboard() {
    // Set initial state to home page
    _setDashboardState(DashboardStateModel.navigating(
      pageIndex: 0,
      page: DashboardPage.home,
    ));
  }

  /// Set dashboard state and notify listeners
  void _setDashboardState(DashboardStateModel state) {
    _dashboardState = state;
    notifyListeners();
  }

  /// Navigate to a specific page by index
  void navigateToPageByIndex(int index) {
    if (index < 0 || index >= DashboardPage.values.length) {
      _setDashboardState(DashboardStateModel.error('Invalid page index: $index'));
      return;
    }

    final page = DashboardPage.values[index];
    navigateToPage(page, index: index);
  }

  /// Navigate to a specific page
  void navigateToPage(DashboardPage page, {int? index}) {
    try {
      final pageIndex = index ?? _getPageIndex(page);
      
      // Add to navigation history if it's a new page
      if (_navigationHistory.isEmpty || _navigationHistory.last != page) {
        _navigationHistory.add(page);
        
        // Keep history limited to prevent memory issues
        if (_navigationHistory.length > 10) {
          _navigationHistory.removeAt(0);
        }
      }

      // Update state
      _setDashboardState(DashboardStateModel.navigating(
        pageIndex: pageIndex,
        page: page,
        isBottomNavVisible: _shouldShowBottomNav(page),
      ));

      debugPrint('Navigated to: ${page.toString().split('.').last} (index: $pageIndex)');
    } catch (e) {
      _setDashboardState(DashboardStateModel.error('Navigation failed: ${e.toString()}'));
    }
  }

  /// Navigate to home page
  void navigateToHome() {
    navigateToPage(DashboardPage.home);
  }


  /// Navigate to food logging page
  void navigateToFoodLogging() {
    navigateToPage(DashboardPage.foodLogging);
  }

  /// Navigate to statistics page
  void navigateToStatistics() {
    navigateToPage(DashboardPage.statistics);
  }

  /// Navigate to profile page
  void navigateToProfile() {
    navigateToPage(DashboardPage.profile);
  }


  /// Navigate back in history
  bool navigateBack() {
    if (_navigationHistory.length > 1) {
      _navigationHistory.removeLast(); // Remove current page
      final previousPage = _navigationHistory.last;
      
      final pageIndex = _getPageIndex(previousPage);
      _setDashboardState(DashboardStateModel.navigating(
        pageIndex: pageIndex,
        page: previousPage,
        isBottomNavVisible: _shouldShowBottomNav(previousPage),
      ));
      
      debugPrint('Navigated back to: ${previousPage.toString().split('.').last}');
      return true;
    }
    return false;
  }

  /// Toggle bottom navigation visibility
  void toggleBottomNavVisibility() {
    _setDashboardState(_dashboardState.copyWith(
      isBottomNavVisible: !_dashboardState.isBottomNavVisible,
    ));
  }

  /// Hide bottom navigation
  void hideBottomNav() {
    if (_dashboardState.isBottomNavVisible) {
      _setDashboardState(_dashboardState.copyWith(
        isBottomNavVisible: false,
      ));
    }
  }

  /// Show bottom navigation
  void showBottomNav() {
    if (!_dashboardState.isBottomNavVisible) {
      _setDashboardState(_dashboardState.copyWith(
        isBottomNavVisible: true,
      ));
    }
  }

  /// Get the index of a specific page
  int _getPageIndex(DashboardPage page) {
    switch (page) {
      case DashboardPage.home:
        return 0;
      case DashboardPage.foodLogging:
        return 1;
      case DashboardPage.statistics:
        return 2;
      case DashboardPage.profile:
        return 3;
    }
  }

  /// Determine if bottom navigation should be shown for specific page
  bool _shouldShowBottomNav(DashboardPage page) {
    // You can customize this logic based on your needs
    // For example, hide bottom nav on certain pages like profile settings
    switch (page) {
      case DashboardPage.home:
      case DashboardPage.foodLogging:
      case DashboardPage.statistics:
      case DashboardPage.profile:
        return true;
    }
  }

  /// Clear navigation history
  void clearNavigationHistory() {
    _navigationHistory.clear();
    _navigationHistory.add(_dashboardState.currentPage);
    debugPrint('Navigation history cleared');
  }

  /// Reset dashboard to initial state
  void resetDashboard() {
    _navigationHistory.clear();
    _navigationHistory.add(DashboardPage.home);
    _setDashboardState(DashboardStateModel.initial());
    debugPrint('Dashboard reset to initial state');
  }

  /// Check if user is authenticated before navigation
  bool get isUserAuthenticated {
    return _firebaseAuth.currentUser != null;
  }

  /// Navigate with authentication check
  void navigateWithAuthCheck(DashboardPage page) {
    if (!isUserAuthenticated) {
      _setDashboardState(DashboardStateModel.error('User not authenticated'));
      return;
    }
    navigateToPage(page);
  }

  /// Clear error and success messages
  void clearMessages() {
    if (_dashboardState.hasError || _dashboardState.successMessage != null) {
      _setDashboardState(_dashboardState.copyWith(
        errorMessage: null,
        successMessage: null,
      ));
    }
  }

  /// Get current page widget key for PageView
  String get currentPageKey {
    return 'page_${_dashboardState.currentPage.toString().split('.').last}';
  }

  /// Check if specific page is currently active
  bool isPageActive(DashboardPage page) {
    return _dashboardState.currentPage == page;
  }

  /// Get navigation items for bottom navigation (Original 4-tab layout)
  List<NavigationItem> get navigationItems {
    return [
      NavigationItem(
        page: DashboardPage.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      NavigationItem(
        page: DashboardPage.foodLogging,
        icon: Icons.restaurant_outlined,
        activeIcon: Icons.restaurant,
        label: 'Food Log',
      ),
      NavigationItem(
        page: DashboardPage.statistics,
        icon: Icons.analytics_outlined,
        activeIcon: Icons.analytics,
        label: 'Statistics',
      ),
      NavigationItem(
        page: DashboardPage.profile,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];
  }
  
  // =================== STEP COUNTER METHODS ===================
  
  /// Sets the global step counter reference (called from UI)
  void setGlobalStepCounter(GlobalStepCounterProvider globalStepCounter) {
    _globalStepCounter = globalStepCounter;
    
    // Listen to step counter changes
    _globalStepCounter!.addListener(_onGlobalStepCounterChanged);
    
    debugPrint('DashboardProvider: Connected to GlobalStepCounterProvider');
    notifyListeners(); // Trigger UI update with new step data
  }
  
  /// Called when global step counter changes
  void _onGlobalStepCounterChanged() {
    // Trigger UI update when step count changes
    notifyListeners();
  }

  @override
  void dispose() {
    // Remove listener from global step counter
    if (_globalStepCounter != null) {
      _globalStepCounter!.removeListener(_onGlobalStepCounterChanged);
    }
    
    _navigationHistory.clear();
    super.dispose();
  }
}

/// Navigation item model for bottom navigation
class NavigationItem {
  final DashboardPage page;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavigationItem({
    required this.page,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
