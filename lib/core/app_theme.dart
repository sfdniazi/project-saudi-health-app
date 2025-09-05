import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ Enhanced Material 3 theme with dark mode support
class AppTheme {
  // Brand colors for both light and dark themes
  // Green theme tokens per spec
  static const Color primaryGreen = Color(0xFFA9E563); // PRIMARY_GREEN
  static const Color secondaryGreen = Color(0xFF6FCF97); // SECONDARY_GREEN
  static const Color waterBlue = Color(0xFF2D9CDB); // WATER_BLUE
  static const Color stepsOrange = Color(0xFFF2994A); // STEPS_ORANGE
  // Backward-compatible aliases for existing code references
  static const Color accentBlue = waterBlue; // alias for previous accentBlue
  static const Color accentOrange = stepsOrange; // alias for previous accentOrange
  static const Color accentBlack = Color(0xFF1A1A1A);
  
  // Light theme colors
  static const Color background = Color(0xFFFFFFFF); // MAIN_BACKGROUND kept
  static const Color surfaceLight = Color(0xFFF8F9FA); // CARD_BG
  static const Color cardBg = Color(0xFFF8F9FA); // alias
  static const Color highlightBg = Color(0xFFE9F8E1); // HIGHLIGHT_BG
  static const Color textPrimary = Color(0xFF1E1E1E); // PRIMARY_TEXT
  static const Color textSecondary = Color(0xFF6C6C6C); // SECONDARY_TEXT
  static const Color textLight = Color(0xFF828282);
  
  // Enhanced Dark theme colors for premium luxury feel
  static const Color backgroundDark = Color(0xFF0A0A0A); // Deeper black for premium feel
  static const Color surfaceDark = Color(0xFF1C1C1E); // iOS-inspired dark surface
  static const Color surfaceDarkElevated = Color(0xFF2C2C2E); // Elevated surfaces
  static const Color surfaceDarkCard = Color(0xFF1F1F23); // Cards with subtle elevation
  static const Color textPrimaryDark = Color(0xFFFAFAFA); // Pure white for primary text
  static const Color textSecondaryDark = Color(0xFFE1E1E6); // Slightly dimmed for secondary
  static const Color textLightDark = Color(0xFFA1A1AA); // Muted for tertiary text
  static const Color accentDarkGreen = Color(0xFF00D4AA); // Brighter green for dark mode
  static const Color dividerDark = Color(0xFF3A3A3C); // Subtle dividers

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

  /// ✅ Material 3 Light Theme with enhanced design system
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryGreen,
      onPrimary: Colors.white,
      secondary: secondaryGreen,
      onSecondary: Colors.white,
      error: stepsOrange,
      onError: Colors.white,
      background: background,
      onBackground: textPrimary,
      surface: surfaceLight,
      onSurface: textPrimary,
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

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: background,
      selectedItemColor: primaryGreen,
      unselectedItemColor: textLight,
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
    
    cardTheme: CardThemeData(
      color: cardBg,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.all(8),
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
