import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../food_logging/screens/food_logging_screen_with_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_state_model.dart';

// Import your existing screens  
import '../../home/screens/home_screen_with_provider.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../profile/screens/profile_screen_with_provider.dart';
import '../../activity/screens/activity_screen_with_provider.dart';

import '../../../core/app_theme.dart';

class DashboardNavigationScreen extends StatefulWidget {
  const DashboardNavigationScreen({super.key});

  @override
  State<DashboardNavigationScreen> createState() => _DashboardNavigationScreenState();
}

class _DashboardNavigationScreenState extends State<DashboardNavigationScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _bottomNavAnimationController;
  late Animation<Offset> _bottomNavSlideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Initialize bottom navigation animation
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bottomNavSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bottomNavAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation
    _bottomNavAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }

  /// Get the widget for the current page
  Widget _getPageWidget(DashboardPage page) {
    switch (page) {
      case DashboardPage.home:
        return const HomeScreenWithProvider();

      case DashboardPage.foodLogging:
        return const FoodLoggingScreenWithProvider();
      case DashboardPage.statistics:
        return const StatisticsScreen();
      case DashboardPage.profile:
        return const ProfileScreenWithProvider();
      case DashboardPage.activity:
        return const ActivityScreenWithProvider();
    }
  }

  /// Handle page change from PageView
  void _onPageChanged(int index) {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.navigateToPageByIndex(index);
  }

  /// Handle bottom navigation tap
  void _onBottomNavTap(int index) {
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.navigateToPageByIndex(index);
    
    // Animate to the page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Build custom bottom navigation bar
  Widget _buildBottomNavigationBar(DashboardProvider dashboardProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: dashboardProvider.currentPageIndex,
          onTap: _onBottomNavTap,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 10,
          iconSize: 24,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          items: dashboardProvider.navigationItems.map((item) {
            final isActive = dashboardProvider.isPageActive(item.page);
            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive 
                    ? AppTheme.primaryGreen.withOpacity(0.1) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? AppTheme.primaryGreen : Colors.grey[600],
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Build floating action button for quick actions
  Widget? _buildFloatingActionButton(DashboardProvider dashboardProvider) {
    // Show FAB only on certain pages
    if (dashboardProvider.currentPage == DashboardPage.foodLogging) {
      return FloatingActionButton.extended(
        onPressed: () {
          // Quick add food action
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quick Add Food'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Quick Add',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      );
    }
    return null;
  }

  /// Handle back button press
  Future<bool> _onWillPop(DashboardProvider dashboardProvider) async {
    // Try to navigate back in provider history first
    if (dashboardProvider.navigateBack()) {
      _pageController.animateToPage(
        dashboardProvider.currentPageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return false; // Prevent default back behavior
    }
    
    // If on home page, show exit confirmation
    if (dashboardProvider.currentPage == DashboardPage.home) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit App'),
          content: const Text('Are you sure you want to exit?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Exit'),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    
    // Navigate to home page
    dashboardProvider.navigateToHome();
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return WillPopScope(
          onWillPop: () => _onWillPop(dashboardProvider),
          child: Scaffold(
            // Main body with Stack for overlays
            body: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: DashboardPage.values.length,
                  itemBuilder: (context, index) {
                    final page = DashboardPage.values[index];
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _getPageWidget(page),
                    );
                  },
                ),
                
                // Loading overlay
                if (dashboardProvider.isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                
                // Error message
                if (dashboardProvider.errorMessage != null)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[600],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                dashboardProvider.errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: dashboardProvider.clearMessages,
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            
            // Bottom Navigation Bar with animation
            bottomNavigationBar: dashboardProvider.isBottomNavVisible
                ? SlideTransition(
                    position: _bottomNavSlideAnimation,
                    child: _buildBottomNavigationBar(dashboardProvider),
                  )
                : null,
            
            // Floating Action Button
            floatingActionButton: _buildFloatingActionButton(dashboardProvider),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          ),
        );
      },
    );
  }
}
