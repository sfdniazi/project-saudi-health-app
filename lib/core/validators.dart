import 'package:flutter/material.dart';

/// Shared validation utilities for consistent input validation across the app
/// 
/// SECURITY: Implements strong password requirements and input sanitization
class Validators {
  
  /// Email validation with comprehensive pattern matching
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&\*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
      caseSensitive: false,
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }
  
  /// Strong password validation with detailed feedback
  static String? validatePassword(String? value, {bool isLogin = false}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // For login, we don't check complexity (existing users might have older passwords)
    if (isLogin) {
      return null;
    }
    
    // For signup, enforce strong password requirements
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'\d').hasMatch(value);
    final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
    
    if (!hasUpperCase) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!hasLowerCase) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!hasDigit) {
      return 'Password must contain at least one number';
    }
    
    if (!hasSpecialChar) {
      return 'Password must contain at least one special character';
    }
    
    // Check for common weak passwords
    final lowercaseValue = value.toLowerCase();
    final weakPasswords = [
      'password', '12345678', 'qwerty123', 'abc123!@#',
      'password1', 'password!', '123456789', 'qwertyui'
    ];
    
    if (weakPasswords.contains(lowercaseValue)) {
      return 'Please choose a more secure password';
    }
    
    return null;
  }
  
  /// Confirm password validation
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }
  
  /// Full name validation
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (value.trim().length > 50) {
      return 'Name must be less than 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-'\.]+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
  
  /// Age validation
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your age';
    }
    
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 13 || age > 120) {
      return 'Age must be between 13 and 120 years';
    }
    
    return null;
  }
  
  /// Height validation (metric/imperial)
  static String? validateHeight(String? value, bool isMetric) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your height';
    }
    
    final height = double.tryParse(value.trim());
    if (height == null) {
      return 'Please enter a valid height';
    }
    
    if (isMetric) {
      // Metric: centimeters
      if (height < 100 || height > 250) {
        return 'Height must be between 100-250 cm';
      }
    } else {
      // Imperial: inches
      if (height < 39 || height > 98) {
        return 'Height must be between 39-98 inches';
      }
    }
    
    return null;
  }
  
  /// Weight validation (metric/imperial)
  static String? validateWeight(String? value, bool isMetric, {bool isGoal = false}) {
    if (value == null || value.trim().isEmpty) {
      return isGoal ? 'Please enter your goal weight' : 'Please enter your weight';
    }
    
    final weight = double.tryParse(value.trim());
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    
    if (isMetric) {
      // Metric: kilograms
      if (weight < 30 || weight > 300) {
        return 'Weight must be between 30-300 kg';
      }
    } else {
      // Imperial: pounds
      if (weight < 66 || weight > 660) {
        return 'Weight must be between 66-660 lbs';
      }
    }
    
    return null;
  }
  
  /// Sanitize input to prevent XSS and injection attacks
  static String sanitizeInput(String input) {
    String result = input;
    // Remove HTML tags
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove dangerous characters
    result = result.replaceAll('<', '')
                 .replaceAll('>', '')
                 .replaceAll('&', '')
                 .replaceAll('"', '')
                 .replaceAll('\'', '')
                 .replaceAll('`', '');
    return result.trim();
  }
  
  /// Validate and sanitize display name
  static String? validateAndSanitizeDisplayName(String? value) {
    final validation = validateFullName(value);
    if (validation != null) return validation;
    
    // Additional sanitization for display name
    final sanitized = sanitizeInput(value!);
    if (sanitized != value) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }
  
  /// Password strength indicator
  static PasswordStrength getPasswordStrength(String password) {
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    return PasswordStrength.strong;
  }
  
  /// Get password strength color
  static Color getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }
  
  /// Get password strength text
  static String getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }
}

/// Password strength enumeration
enum PasswordStrength { weak, medium, strong }
