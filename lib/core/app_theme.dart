import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ Beautiful Nabd Al-Hayah Design System - Inspired by modern health apps
class AppTheme {
  // 🎨 New Nabd Al-Hayah Color Palette (extracted from reference design)
  
  // === PRIMARY BRAND COLORS ===
  static const Color nabdGreen = Color(0xFF58D68D);      // Success/Completed goals
  static const Color nabdBlue = Color(0xFF5DADE2);       // Water tracking & primary actions  
  static const Color nabdPurple = Color(0xFF8E7CC3);     // Mental wellbeing
  static const Color nabdOrange = Color(0xFFFF9F43);     // Energy/Warning states
  static const Color nabdYellow = Color(0xFFF7DC6F);     // Mood tracking/Happiness
  
  // === BACKGROUND & SURFACES ===
  static const Color background = Color(0xFFFAFAFB);     // Clean app background
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white cards
  static const Color surfaceLight = Color(0xFFF8F9FA);   // Secondary surfaces
  static const Color cardBg = cardBackground;             // alias for compatibility
  static const Color backgroundLight = cardBackground;    // alias for compatibility
  
  // === TEXT COLORS ===
  static const Color textPrimary = Color(0xFF2C3E50);    // Main headings
  static const Color textSecondary = Color(0xFF7F8C8D);  // Secondary text
  static const Color textTertiary = Color(0xFFBDC3C7);   // Subtle text
  static const Color textLight = textTertiary;            // alias for compatibility
  
  // === SEMANTIC COLORS ===
  static const Color successGreen = nabdGreen;           // Success states
  static const Color warningOrange = nabdOrange;         // Warning states  
  static const Color errorColor = Color(0xFFE74C3C);     // Error states
  static const Color infoBlue = nabdBlue;                // Info states
  
  // === MOOD TRACKING COLORS ===
  static const Color moodTerrible = Color(0xFFE74C3C);   // Red
  static const Color moodBad = Color(0xFFFF9F43);        // Orange
  static const Color moodNeutral = Color(0xFFBDC3C7);    // Gray
  static const Color moodGood = Color(0xFFF7DC6F);       // Yellow  
  static const Color moodAwesome = Color(0xFF58D68D);    // Green
  
  // === CHART COLORS ===
  static const Color chartBlue = Color(0xFF74B9FF);      // Primary chart color
  static const Color chartGreen = Color(0xFF00CEC9);     // Secondary chart color
  static const Color chartYellow = Color(0xFFFDCB6E);    // Tertiary chart color
  static const Color chartPurple = Color(0xFDA7DF);      // Quaternary chart color
  
  // === BORDERS & DIVIDERS ===
  static const Color borderColor = Color(0xFFECF0F1);    // Subtle borders
  static const Color dividerColor = borderColor;         // alias
  static const Color shadowColor = Color(0x0D000000);    // Soft shadows
  
  // === BACKWARD COMPATIBILITY ALIASES ===
  static const Color primaryGreen = nabdGreen;           // Keep existing references working
  static const Color secondaryGreen = Color(0xFF6FCF97); 
  static const Color waterBlue = nabdBlue;               
  static const Color stepsOrange = nabdOrange;           
  static const Color accentBlue = nabdBlue;              
  static const Color accentOrange = nabdOrange;          
  static const Color accentBlack = Color(0xFF2C3E50);    
  static const Color highlightBg = Color(0xFFEBF8FF);    // Light blue highlight
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  
  // === DARK THEME COLORS ===
  static const Color backgroundDark = Color(0xFF1A1A1A);       // Rich dark background
  static const Color cardBackgroundDark = Color(0xFF2D2D30);   // Dark cards
  static const Color surfaceDark = Color(0xFF2D2D30);          // Dark surfaces
  static const Color surfaceDarkElevated = Color(0xFF3E3E42);  // Elevated dark surfaces
  static const Color surfaceDarkCard = cardBackgroundDark;     // alias
  static const Color textPrimaryDark = Color(0xFFFAFAFA);      // Pure white text
  static const Color textSecondaryDark = Color(0xFFE1E1E6);    // Dimmed text
  static const Color textTertiaryDark = Color(0xFFA1A1AA);     // Subtle dark text
  static const Color textLightDark = textTertiaryDark;         // alias
  static const Color borderColorDark = Color(0xFF3A3A3C);      // Dark borders
  static const Color dividerDark = borderColorDark;            // alias
  static const Color shadowColorDark = Color(0x33000000);      // Darker shadows
  
  // === DESIGN SYSTEM TOKENS ===
  
  // Spacing scale (4px base unit)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0; 
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 20.0;
  static const double spaceXxl = 24.0;
  static const double spaceXxxl = 32.0;
  
  // Border radius tokens
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;   // Controls, chips
  static const double radiusLg = 16.0;   // Cards, dialogs
  static const double radiusXl = 20.0;   // Buttons
  static const double radiusXxl = 24.0;  // Bottom sheets
  static const double radiusXxxl = 28.0; // Large containers
  
  // Elevation tokens
  static const double elevationNone = 0.0;
  static const double elevationSm = 1.0;   // Subtle elevation
  static const double elevationMd = 2.0;   // Cards
  static const double elevationLg = 4.0;   // Bottom sheets
  static const double elevationXl = 8.0;   // FAB, app bar
  
  // Typography scale (matching reference design)
  static const double fontSizeXs = 10.0;
  static const double fontSizeSm = 12.0;  // Labels, captions
  static const double fontSizeMd = 14.0;  // Body text
  static const double fontSizeLg = 16.0;  // Larger body
  static const double fontSizeXl = 18.0;  // Subtitles
  static const double fontSizeXxl = 20.0; // Titles
  static const double fontSizeXxxl = 24.0; // Headings
  static const double fontSizeDisplay = 32.0; // Large display

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, secondaryGreen],
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, secondaryGreen],
  );
  
  static const LinearGradient headerGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D3748), Color(0xFF4A5568)],
  );

  /// ✅ Beautiful Nabd Al-Hayah Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: nabdBlue,              // Primary blue for actions
      onPrimary: Colors.white,
      secondary: nabdGreen,           // Success green
      onSecondary: Colors.white,
      tertiary: nabdPurple,           // Wellbeing purple
      onTertiary: Colors.white,
      error: errorColor,
      onError: Colors.white,
      background: background,         // Clean light background
      onBackground: textPrimary,
      surface: cardBackground,        // Pure white surfaces
      onSurface: textPrimary,
      surfaceVariant: surfaceLight,   // Secondary surfaces
      onSurfaceVariant: textSecondary,
      outline: borderColor,           // Subtle borders
      outlineVariant: dividerColor,
    ),
    scaffoldBackgroundColor: background,
    
    // Enhanced Material 3 typography
    textTheme: GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textLight,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textLight,
      ),
    ),
    
    // Material 3 component themes
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    iconTheme: const IconThemeData(color: textLight),

    // 🧝 Beautiful bottom navigation matching reference
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardBackground,          // Clean white background
      selectedItemColor: nabdBlue,             // Primary blue for active items
      unselectedItemColor: textTertiary,       // Subtle gray for inactive
      showUnselectedLabels: true,
      elevation: elevationLg,                  // Subtle elevation
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: fontSizeSm,                  // 12px labels
        fontWeight: FontWeight.w600,
        color: nabdBlue,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: fontSizeSm,
        fontWeight: FontWeight.w500,
        color: textTertiary,
      ),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryGreen,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: primaryGreen.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    
    // 🎴 Beautiful card theme matching reference design
    cardTheme: CardThemeData(
      color: cardBackground,                    // Pure white cards
      elevation: elevationMd,                   // Subtle elevation
      shadowColor: shadowColor,                 // Soft shadows
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLg), // 16px rounded corners
        side: BorderSide(
          color: borderColor,                     // Subtle border
          width: 0.5,
        ),
      ),
      margin: EdgeInsets.all(spaceSm),          // 8px margin
      clipBehavior: Clip.antiAlias,
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: background,
      selectedColor: primaryGreen.withOpacity(0.12),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceLight,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surfaceLight,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: accentBlack,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
  
  /// ✅ Material 3 Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryGreen,
      onPrimary: Colors.white,
      secondary: secondaryGreen,
      onSecondary: Colors.white,
      error: stepsOrange,
      onError: Colors.white,
      background: backgroundDark,
      onBackground: textPrimaryDark,
      surface: surfaceDark,
      onSurface: textPrimaryDark,
    ),
    scaffoldBackgroundColor: backgroundDark,
    
    // Enhanced Material 3 typography for dark theme
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: textPrimaryDark,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w400,
        color: textPrimaryDark,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: textPrimaryDark,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textPrimaryDark,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: textPrimaryDark,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textSecondaryDark,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: textLightDark,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: textPrimaryDark,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: textSecondaryDark,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: textLightDark,
      ),
    ),
    
    // Material 3 component themes for dark theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),

    iconTheme: const IconThemeData(color: textLightDark),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: backgroundDark,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textLightDark,
      showUnselectedLabels: true,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryGreen,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 1,
        shadowColor: primaryGreen.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryGreen,
        side: const BorderSide(color: primaryGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
    
    // 🌙 Enhanced dark theme card styling for premium feel
    cardTheme: CardThemeData(
      color: surfaceDarkCard,
      elevation: 2,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dividerDark, width: 0.5),
      ),
      margin: const EdgeInsets.all(8),
    ),
    
    chipTheme: ChipThemeData(
      backgroundColor: surfaceDarkElevated,
      selectedColor: primaryGreen.withOpacity(0.2),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimaryDark,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    dialogTheme: DialogThemeData(
      backgroundColor: surfaceDark,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
    ),
    
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceDark,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
    ),
    
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceDarkElevated,
      contentTextStyle: GoogleFonts.inter(
        color: textPrimaryDark,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );

  /// ✅ Theme manager for persisting theme preferences
  static const String _themeKey = 'theme_mode';
  
  static Future<ThemeMode> getSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  static Future<void> saveThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString = 'system';
    
    switch (themeMode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    
    await prefs.setString(_themeKey, themeString);
  }
  
  // 🎨 Original theme helpers - light theme only
  static LinearGradient getHeaderGradient(BuildContext context) {
    return headerGradient; // Always use light theme header gradient
  }
  
  static Color getSurfaceColor(BuildContext context) {
    return surfaceLight; // Always use light theme surface
  }
  
  static Color getBackgroundColor(BuildContext context) {
    return background; // Always use light theme background
  }
}
