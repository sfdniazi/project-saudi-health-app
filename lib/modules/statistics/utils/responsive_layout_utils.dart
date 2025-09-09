import 'package:flutter/material.dart';

/// Utilities for responsive layout calculations and screen adaptations
class ResponsiveLayoutUtils {
  /// Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Get screen type based on width
  static ScreenType getScreenType(double width) {
    if (width < mobileBreakpoint) return ScreenType.mobile;
    if (width < tabletBreakpoint) return ScreenType.tablet;
    if (width < desktopBreakpoint) return ScreenType.desktop;
    return ScreenType.largeDesktop;
  }

  /// Calculate responsive chart height based on screen size and data count
  static double calculateChartHeight({
    required BuildContext context,
    required int dataCount,
    double baseHeight = 280,
    double minHeight = 200,
    double maxHeight = 400,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final screenType = getScreenType(screenSize.width);
    
    // Adjust base height for screen type
    double adjustedHeight = baseHeight;
    switch (screenType) {
      case ScreenType.mobile:
        adjustedHeight = baseHeight * 0.8;
        break;
      case ScreenType.tablet:
        adjustedHeight = baseHeight * 1.1;
        break;
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        adjustedHeight = baseHeight * 1.2;
        break;
    }

    // Adjust for data density
    if (dataCount > 20) {
      adjustedHeight *= 1.3;
    } else if (dataCount > 10) {
      adjustedHeight *= 1.1;
    }

    // Apply constraints
    return adjustedHeight.clamp(minHeight, maxHeight);
  }

  /// Calculate responsive table row height
  static double calculateTableRowHeight({
    required BuildContext context,
    bool isCompactMode = false,
  }) {
    final screenType = getScreenType(MediaQuery.of(context).size.width);
    
    double baseHeight = isCompactMode ? 40 : 56;
    
    switch (screenType) {
      case ScreenType.mobile:
        return baseHeight * 0.9;
      case ScreenType.tablet:
        return baseHeight;
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return baseHeight * 1.1;
    }
  }

  /// Calculate responsive font sizes
  static double getResponsiveFontSize({
    required BuildContext context,
    required double baseFontSize,
  }) {
    final screenType = getScreenType(MediaQuery.of(context).size.width);
    
    switch (screenType) {
      case ScreenType.mobile:
        return baseFontSize * 0.9;
      case ScreenType.tablet:
        return baseFontSize;
      case ScreenType.desktop:
        return baseFontSize * 1.1;
      case ScreenType.largeDesktop:
        return baseFontSize * 1.2;
    }
  }

  /// Calculate responsive padding
  static EdgeInsets getResponsivePadding({
    required BuildContext context,
    EdgeInsets basePadding = const EdgeInsets.all(16),
  }) {
    final screenType = getScreenType(MediaQuery.of(context).size.width);
    
    switch (screenType) {
      case ScreenType.mobile:
        return basePadding * 0.8;
      case ScreenType.tablet:
        return basePadding;
      case ScreenType.desktop:
        return basePadding * 1.2;
      case ScreenType.largeDesktop:
        return basePadding * 1.4;
    }
  }

  /// Calculate columns for responsive grid
  static int getResponsiveColumns(BuildContext context, {
    int mobileColumns = 1,
    int tabletColumns = 2,
    int desktopColumns = 3,
  }) {
    final screenType = getScreenType(MediaQuery.of(context).size.width);
    
    switch (screenType) {
      case ScreenType.mobile:
        return mobileColumns;
      case ScreenType.tablet:
        return tabletColumns;
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return desktopColumns;
    }
  }

  /// Check if screen can handle full features
  static bool canShowFullFeatures(BuildContext context) {
    return getScreenType(MediaQuery.of(context).size.width) != ScreenType.mobile;
  }

  /// Check if should show compact mode by default
  static bool shouldUseCompactMode(BuildContext context) {
    return getScreenType(MediaQuery.of(context).size.width) == ScreenType.mobile;
  }

  /// Calculate maximum items per page based on screen size
  static int getMaxItemsPerPage(BuildContext context) {
    final screenType = getScreenType(MediaQuery.of(context).size.width);
    
    switch (screenType) {
      case ScreenType.mobile:
        return 7; // One week
      case ScreenType.tablet:
        return 14; // Two weeks
      case ScreenType.desktop:
        return 21; // Three weeks
      case ScreenType.largeDesktop:
        return 28; // Four weeks
    }
  }

  /// Get chart interval based on data count and screen size
  static double getChartInterval({
    required BuildContext context,
    required int dataCount,
    required double dataRange,
  }) {
    final screenType = getScreenType(MediaQuery.of(context).size.width);
    
    // Base intervals
    int targetIntervals = 5;
    
    switch (screenType) {
      case ScreenType.mobile:
        targetIntervals = dataCount > 10 ? 3 : 4;
        break;
      case ScreenType.tablet:
        targetIntervals = dataCount > 20 ? 4 : 5;
        break;
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        targetIntervals = dataCount > 30 ? 5 : 6;
        break;
    }

    return dataRange / targetIntervals;
  }
}

/// Screen size enumeration
enum ScreenType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// View mode for different display options
enum ViewMode {
  detailed,
  compact,
  minimal,
}

/// Chart display mode
enum ChartDisplayMode {
  full,
  compressed,
  overview,
}

/// Extension methods for responsive calculations
extension ResponsiveExtensions on BuildContext {
  /// Get screen type for current context
  ScreenType get screenType => ResponsiveLayoutUtils.getScreenType(
    MediaQuery.of(this).size.width,
  );

  /// Check if mobile screen
  bool get isMobile => screenType == ScreenType.mobile;

  /// Check if tablet or larger
  bool get isTabletOrLarger => screenType != ScreenType.mobile;

  /// Check if desktop or larger
  bool get isDesktopOrLarger => 
    screenType == ScreenType.desktop || screenType == ScreenType.largeDesktop;

  /// Get responsive font size
  double responsiveFontSize(double baseFontSize) =>
    ResponsiveLayoutUtils.getResponsiveFontSize(
      context: this,
      baseFontSize: baseFontSize,
    );

  /// Get responsive padding
  EdgeInsets responsivePadding([EdgeInsets? basePadding]) =>
    ResponsiveLayoutUtils.getResponsivePadding(
      context: this,
      basePadding: basePadding ?? const EdgeInsets.all(16),
    );
}
