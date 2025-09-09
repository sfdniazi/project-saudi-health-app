import 'package:flutter/material.dart';

/// ✅ Responsive design utility for pixel-perfect rendering across devices
/// 
/// This utility provides consistent responsive sizing methods to prevent
/// pixel overflow issues on different screen sizes and densities.
class ResponsiveUtils {
  
  /// Private constructor to prevent instantiation
  ResponsiveUtils._();
  
  // Base design dimensions (can be adjusted based on your design system)
  static const double _baseWidth = 375.0; // iPhone X width as base
  static const double _baseHeight = 812.0; // iPhone X height as base
  
  /// Get responsive width based on percentage of screen width
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [percentage] - Percentage of screen width (0.0 to 1.0)
  /// [minSize] - Minimum size in pixels (optional)
  /// [maxSize] - Maximum size in pixels (optional)
  /// 
  /// Example: `ResponsiveUtils.getWidth(context, 0.04)` = 4% of screen width
  static double getWidth(BuildContext context, double percentage, {double? minSize, double? maxSize}) {
    final screenWidth = MediaQuery.of(context).size.width;
    double size = screenWidth * percentage;
    
    if (minSize != null) size = size < minSize ? minSize : size;
    if (maxSize != null) size = size > maxSize ? maxSize : size;
    
    return size;
  }
  
  /// Get responsive height based on percentage of screen height
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [percentage] - Percentage of screen height (0.0 to 1.0)
  /// [minSize] - Minimum size in pixels (optional)
  /// [maxSize] - Maximum size in pixels (optional)
  /// 
  /// Example: `ResponsiveUtils.getHeight(context, 0.02)` = 2% of screen height
  static double getHeight(BuildContext context, double percentage, {double? minSize, double? maxSize}) {
    final screenHeight = MediaQuery.of(context).size.height;
    double size = screenHeight * percentage;
    
    if (minSize != null) size = size < minSize ? minSize : size;
    if (maxSize != null) size = size > maxSize ? maxSize : size;
    
    return size;
  }
  
  /// Get responsive font size based on screen width
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [baseFontSize] - Base font size at design width
  /// [minSize] - Minimum font size (default: 10.0)
  /// [maxSize] - Maximum font size (default: 32.0)
  static double getFontSize(BuildContext context, double baseFontSize, {double minSize = 10.0, double maxSize = 32.0}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / _baseWidth;
    
    double fontSize = baseFontSize * scaleFactor;
    
    // Clamp font size to prevent extremes
    fontSize = fontSize < minSize ? minSize : fontSize;
    fontSize = fontSize > maxSize ? maxSize : fontSize;
    
    return fontSize;
  }
  
  /// Get responsive EdgeInsets for padding/margin
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [top], [right], [bottom], [left] - Percentages of screen dimensions
  static EdgeInsets getEdgeInsets(
    BuildContext context, {
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
    double left = 0.0,
  }) {
    return EdgeInsets.only(
      top: getHeight(context, top),
      right: getWidth(context, right),
      bottom: getHeight(context, bottom),
      left: getWidth(context, left),
    );
  }
  
  /// Get symmetric EdgeInsets for padding/margin
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [horizontal] - Percentage of screen width for left and right
  /// [vertical] - Percentage of screen height for top and bottom
  static EdgeInsets getSymmetricEdgeInsets(
    BuildContext context, {
    double horizontal = 0.0,
    double vertical = 0.0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getWidth(context, horizontal),
      vertical: getHeight(context, vertical),
    );
  }
  
  /// Get responsive avatar size with constraints
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [basePercentage] - Base percentage of screen width (default: 0.08 = 8%)
  /// [minSize] - Minimum avatar size (default: 28.0)
  /// [maxSize] - Maximum avatar size (default: 48.0)
  static double getAvatarSize(BuildContext context, {double basePercentage = 0.08, double minSize = 28.0, double maxSize = 48.0}) {
    return getWidth(context, basePercentage, minSize: minSize, maxSize: maxSize);
  }
  
  /// Get responsive icon size proportional to container
  /// 
  /// [containerSize] - Size of the container holding the icon
  /// [ratio] - Icon size ratio relative to container (default: 0.5 = 50%)
  static double getIconSize(double containerSize, {double ratio = 0.5}) {
    return containerSize * ratio;
  }
  
  /// Get responsive border radius
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [percentage] - Percentage of screen width for border radius
  /// [minRadius] - Minimum border radius (default: 8.0)
  /// [maxRadius] - Maximum border radius (default: 24.0)
  static double getBorderRadius(BuildContext context, double percentage, {double minRadius = 8.0, double maxRadius = 24.0}) {
    return getWidth(context, percentage, minSize: minRadius, maxSize: maxRadius);
  }
  
  /// Check if device is considered small screen
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [threshold] - Width threshold for small screen (default: 360.0)
  static bool isSmallScreen(BuildContext context, {double threshold = 360.0}) {
    return MediaQuery.of(context).size.width <= threshold;
  }
  
  /// Check if device is considered large screen
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [threshold] - Width threshold for large screen (default: 600.0)
  static bool isLargeScreen(BuildContext context, {double threshold = 600.0}) {
    return MediaQuery.of(context).size.width >= threshold;
  }
  
  /// Get screen size category
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// Returns: 'small', 'medium', or 'large'
  static String getScreenSizeCategory(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) return 'small';
    if (width < 600) return 'medium';
    return 'large';
  }
  
  /// Get device pixel ratio for high-density screen adjustments
  /// 
  /// [context] - BuildContext to access MediaQuery
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  
  /// Get responsive spacing based on screen size category
  /// 
  /// [context] - BuildContext to access MediaQuery
  /// [small] - Spacing for small screens
  /// [medium] - Spacing for medium screens  
  /// [large] - Spacing for large screens
  static double getResponsiveSpacing(BuildContext context, {double small = 8.0, double medium = 12.0, double large = 16.0}) {
    final category = getScreenSizeCategory(context);
    
    switch (category) {
      case 'small':
        return small;
      case 'large':
        return large;
      default:
        return medium;
    }
  }
}
