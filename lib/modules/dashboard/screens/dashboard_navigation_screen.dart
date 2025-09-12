import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../food_logging/screens/food_logging_screen_with_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_state_model.dart';

// Import your existing screens  
import '../../home/screens/home_screen_with_provider.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../profile/screens/profile_screen_beautiful.dart';

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
    
    // Initialize page controller with initial page 0
    _pageController = PageController(initialPage: 0);
    
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
    
    // Initialize dashboard provider after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.navigateToPageByIndex(0); // Ensure we start at home
      
      // Add listener to sync PageView with provider state changes
      dashboardProvider.addListener(() {
        if (mounted && _pageController.hasClients) {
          final currentIndex = dashboardProvider.currentPageIndex;
          if (_pageController.page?.round() != currentIndex) {
            _pageController.animateToPage(
              currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    });
    
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
        return const ProfileScreenBeautiful();
    }
  }

  /// Handle page change from PageView
  void _onPageChanged(int index) {
    // Validate index bounds
    if (index < 0 || index >= DashboardPage.values.length) {
      debugPrint('❌ Invalid index $index for page change, ignoring');
      return;
    }
    
    debugPrint('🔄 PageView changed to index: $index, page: ${DashboardPage.values[index]}');
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    dashboardProvider.navigateToPageByIndex(index);
    debugPrint('✅ Provider updated from PageView change');
  }

  /// Handle bottom navigation tap
  void _onBottomNavTap(int index) {
    // Validate index bounds
    if (index < 0 || index >= DashboardPage.values.length) {
      debugPrint('❌ Invalid index $index for bottom nav tap, ignoring');
      return;
    }
    
    debugPrint('🔴 Bottom nav tap: index $index, page: ${DashboardPage.values[index]}');
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    
    debugPrint('🔵 Current provider state - index: ${dashboardProvider.currentPageIndex}, page: ${dashboardProvider.currentPage}');
    
    // Update provider state first
    dashboardProvider.navigateToPageByIndex(index);
    
    debugPrint('🟢 After provider update - index: ${dashboardProvider.currentPageIndex}, page: ${dashboardProvider.currentPage}');
    
    // Then animate PageView to the correct page
    if (_pageController.hasClients) {
      debugPrint('🟡 Animating PageView to index $index');
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        debugPrint('🟣 PageView animation completed for index $index');
      });
    } else {
      debugPrint('❌ PageController has no clients');
    }
  }

  /// 🧝 Beautiful bottom navigation matching reference design
  Widget _buildBottomNavigationBar(DashboardProvider dashboardProvider) {
    return IntrinsicHeight(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 85, // Maximum total height including safe area
        ),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground, // Clean white background
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXxxl), // 28px
            topRight: Radius.circular(AppTheme.radiusXxxl),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor,
              blurRadius: 20,
              offset: const Offset(0, -4),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: AppTheme.borderColor,
            width: 0.5,
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 68, // Further reduced to 68
            constraints: const BoxConstraints(
              maxHeight: 68,
              minHeight: 60, // Minimum height
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceXl,
              vertical: 4, // Further reduced to 4
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dashboardProvider.navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = dashboardProvider.isPageActive(item.page);
                
                return _buildNavItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => _onBottomNavTap(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
  
  /// 📱 Individual nav item with pill-style active state
  Widget _buildNavItem({
    required dynamic item,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: 8, // Further reduced padding
            horizontal: 4, // Further reduced padding
          ),
          decoration: BoxDecoration(
            color: isActive 
                ? AppTheme.nabdBlue.withOpacity(0.1) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg), // Pill shape
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with smooth transition
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? AppTheme.nabdBlue : AppTheme.textTertiary,
                  size: 22, // Reduced from 24 to 22
                ),
              ),
              
              const SizedBox(height: 2), // Further reduced spacing
              
              // Label with color transition and proper overflow handling
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isActive ? AppTheme.nabdBlue : AppTheme.textTertiary,
                  fontSize: 10, // Reduced font size
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                child: SizedBox(
                  height: 12, // Further reduced height
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
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
        backgroundColor: AppTheme.nabdBlue,
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SizedBox(
                      height: constraints.maxHeight,
                      child: PageView.builder(
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
