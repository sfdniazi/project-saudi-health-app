import 'package:flutter/material.dart';
import 'dart:ui'; // For PlatformDispatcher
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app_theme.dart';

/// ✅ Global error handler for the app with Firebase Crashlytics integration
class ErrorHandler {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize error handling
  static void initialize() {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _recordFlutterError(details);
    };

    // Handle errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _recordError(error, stack);
      return true;
    };
  }

  /// Record Flutter-specific errors
  static void _recordFlutterError(FlutterErrorDetails details) {
    _crashlytics.recordFlutterFatalError(details);
  }

  /// Record general errors
  static void _recordError(Object error, StackTrace? stackTrace) {
    _crashlytics.recordError(
      error,
      stackTrace,
      fatal: false,
    );
  }

  /// Log non-fatal errors
  static void recordError(Object error, StackTrace? stackTrace, {
    Map<String, String>? customKeys,
    String? reason,
  }) {
    // Add custom keys if provided
    if (customKeys != null) {
      for (var entry in customKeys.entries) {
        _crashlytics.setCustomKey(entry.key, entry.value);
      }
    }

    _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: false,
    );
  }

  /// Set user identifier for crash reports
  static void setUserIdentifier(String userId) {
    _crashlytics.setUserIdentifier(userId);
  }

  /// Set custom key-value pairs for crash reports
  static void setCustomKey(String key, String value) {
    _crashlytics.setCustomKey(key, value);
  }

  /// Show user-friendly error dialog
  static void showErrorDialog(
    BuildContext context, {
    String? title,
    String? message,
    bool showRetry = false,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.accentOrange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title ?? 'Something went wrong',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message ?? 'An unexpected error occurred. Please try again.',
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          if (showRetry && onRetry != null) ...[
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentOrange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Handle API errors with user-friendly messages
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Unknown error occurred';
    
    String errorString = error.toString().toLowerCase();
    
    // Network-related errors
    if (errorString.contains('network') || 
        errorString.contains('internet') ||
        errorString.contains('connection')) {
      return 'Please check your internet connection and try again.';
    }
    
    // Timeout errors
    if (errorString.contains('timeout')) {
      return 'The request timed out. Please try again.';
    }
    
    // Firebase Auth errors
    if (errorString.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorString.contains('email-already-in-use')) {
      return 'This email address is already registered.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errorString.contains('weak-password')) {
      return 'Password should be at least 6 characters long.';
    }
    if (errorString.contains('too-many-requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    
    // Firestore errors
    if (errorString.contains('permission-denied')) {
      return 'Access denied. Please check your permissions.';
    }
    if (errorString.contains('not-found')) {
      return 'The requested data was not found.';
    }
    
    // Default fallback
    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle and display errors with appropriate UI feedback
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    bool showDialog = false,
    bool recordError = true,
    VoidCallback? onRetry,
  }) {
    // Record error to Crashlytics
    if (recordError) {
      ErrorHandler.recordError(
        error,
        StackTrace.current,
        reason: customMessage ?? 'User error',
      );
    }

    String message = customMessage ?? getErrorMessage(error);

    if (showDialog) {
      showErrorDialog(
        context,
        message: message,
        showRetry: onRetry != null,
        onRetry: onRetry,
      );
    } else {
      showErrorSnackbar(context, message);
    }
  }
}

/// ✅ Extension to handle errors easily from any widget
extension ErrorHandlerExtension on BuildContext {
  void showError(dynamic error, {
    String? customMessage,
    bool showDialog = false,
    VoidCallback? onRetry,
  }) {
    ErrorHandler.handleError(
      this,
      error,
      customMessage: customMessage,
      showDialog: showDialog,
      onRetry: onRetry,
    );
  }

  void showErrorSnackbar(String message) {
    ErrorHandler.showErrorSnackbar(this, message);
  }

  void showErrorDialog(String message, {VoidCallback? onRetry}) {
    ErrorHandler.showErrorDialog(
      this,
      message: message,
      showRetry: onRetry != null,
      onRetry: onRetry,
    );
  }
}
