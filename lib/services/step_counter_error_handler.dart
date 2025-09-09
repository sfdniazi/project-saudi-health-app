import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Enum for step counter error types
enum StepCounterErrorType {
  permissionDenied,
  permissionPermanentlyDenied,
  deviceNotSupported,
  serviceUnavailable,
  sensorNotAvailable,
  platformError,
  networkError,
  timeoutError,
  initializationFailed,
  streamError,
  unknownError,
}

/// Enum for error severity levels
enum ErrorSeverity {
  low,      // Warning, functionality might be limited
  medium,   // Error that can be recovered from
  high,     // Critical error, feature unavailable
  critical, // App-breaking error
}

/// Step counter error details
class StepCounterError {
  final StepCounterErrorType type;
  final ErrorSeverity severity;
  final String message;
  final String? technicalDetails;
  final String? userAction;
  final bool canRecover;
  final DateTime timestamp;

  const StepCounterError({
    required this.type,
    required this.severity,
    required this.message,
    this.technicalDetails,
    this.userAction,
    this.canRecover = true,
    required this.timestamp,
  });

  StepCounterError.withTimestamp({
    required this.type,
    required this.severity,
    required this.message,
    this.technicalDetails,
    this.userAction,
    this.canRecover = true,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory StepCounterError.permissionDenied() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.permissionDenied,
      severity: ErrorSeverity.medium,
      message: 'Activity recognition permission is required for step counting',
      userAction: 'Please grant permission in the next dialog or from app settings',
      canRecover: true,
    );
  }

  factory StepCounterError.permissionPermanentlyDenied() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.permissionPermanentlyDenied,
      severity: ErrorSeverity.high,
      message: 'Activity recognition permission has been permanently denied',
      userAction: 'Please enable permission from your device settings > Apps > Nabd Al-Hayah > Permissions',
      canRecover: false,
    );
  }

  factory StepCounterError.deviceNotSupported() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.deviceNotSupported,
      severity: ErrorSeverity.high,
      message: 'Your device does not support automatic step counting',
      userAction: 'You can still track steps manually using the add buttons',
      canRecover: false,
    );
  }

  factory StepCounterError.serviceUnavailable() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.serviceUnavailable,
      severity: ErrorSeverity.medium,
      message: 'Step counting service is temporarily unavailable',
      userAction: 'Please try again in a few moments',
      canRecover: true,
    );
  }

  factory StepCounterError.sensorNotAvailable() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.sensorNotAvailable,
      severity: ErrorSeverity.high,
      message: 'Step sensor is not available on this device',
      userAction: 'Manual step tracking is still available',
      canRecover: false,
    );
  }

  factory StepCounterError.platformError(String details) {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.platformError,
      severity: ErrorSeverity.medium,
      message: 'Platform-specific error occurred',
      technicalDetails: details,
      userAction: 'Please restart the app and try again',
      canRecover: true,
    );
  }

  factory StepCounterError.networkError() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.networkError,
      severity: ErrorSeverity.low,
      message: 'Network connection required for step data sync',
      userAction: 'Steps will be synced when connection is restored',
      canRecover: true,
    );
  }

  factory StepCounterError.timeoutError() {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.timeoutError,
      severity: ErrorSeverity.medium,
      message: 'Step counter initialization timed out',
      userAction: 'Please try again',
      canRecover: true,
    );
  }

  factory StepCounterError.initializationFailed(String reason) {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.initializationFailed,
      severity: ErrorSeverity.high,
      message: 'Failed to initialize step counter',
      technicalDetails: reason,
      userAction: 'Please restart the app and check permissions',
      canRecover: true,
    );
  }

  factory StepCounterError.streamError(String details) {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.streamError,
      severity: ErrorSeverity.medium,
      message: 'Step counter stream error',
      technicalDetails: details,
      userAction: 'Step counting will be restarted automatically',
      canRecover: true,
    );
  }

  factory StepCounterError.unknownError(String details) {
    return StepCounterError.withTimestamp(
      type: StepCounterErrorType.unknownError,
      severity: ErrorSeverity.medium,
      message: 'An unexpected error occurred',
      technicalDetails: details,
      userAction: 'Please try again or restart the app',
      canRecover: true,
    );
  }

  @override
  String toString() {
    return 'StepCounterError(type: $type, severity: $severity, message: $message)';
  }
}

/// Recovery strategy for step counter errors
class RecoveryStrategy {
  final String name;
  final Future<bool> Function() action;
  final int maxRetries;
  final Duration delay;

  const RecoveryStrategy({
    required this.name,
    required this.action,
    this.maxRetries = 3,
    this.delay = const Duration(seconds: 2),
  });
}

/// Enhanced error handler for step counter with recovery strategies
class StepCounterErrorHandler {
  static final StepCounterErrorHandler _instance = StepCounterErrorHandler._internal();
  factory StepCounterErrorHandler() => _instance;
  StepCounterErrorHandler._internal();

  final Map<StepCounterErrorType, RecoveryStrategy> _recoveryStrategies = {};
  final List<StepCounterError> _errorHistory = [];
  final StreamController<StepCounterError> _errorStream = StreamController<StepCounterError>.broadcast();

  Stream<StepCounterError> get errorStream => _errorStream.stream;
  List<StepCounterError> get errorHistory => List.unmodifiable(_errorHistory);

  /// Initializes error handler with recovery strategies
  void initialize() {
    _setupRecoveryStrategies();
    developer.log('StepCounterErrorHandler: Initialized with recovery strategies', name: 'StepCounterErrorHandler');
  }

  /// Sets up recovery strategies for different error types
  void _setupRecoveryStrategies() {
    _recoveryStrategies[StepCounterErrorType.permissionDenied] = RecoveryStrategy(
      name: 'Request Permission',
      action: _requestPermission,
      maxRetries: 1,
    );

    _recoveryStrategies[StepCounterErrorType.serviceUnavailable] = RecoveryStrategy(
      name: 'Retry Service Connection',
      action: _retryServiceConnection,
      maxRetries: 3,
      delay: const Duration(seconds: 5),
    );

    _recoveryStrategies[StepCounterErrorType.streamError] = RecoveryStrategy(
      name: 'Restart Stream',
      action: _restartStream,
      maxRetries: 5,
      delay: const Duration(seconds: 1),
    );

    _recoveryStrategies[StepCounterErrorType.initializationFailed] = RecoveryStrategy(
      name: 'Retry Initialization',
      action: _retryInitialization,
      maxRetries: 2,
      delay: const Duration(seconds: 3),
    );

    _recoveryStrategies[StepCounterErrorType.timeoutError] = RecoveryStrategy(
      name: 'Retry with Timeout',
      action: _retryWithTimeout,
      maxRetries: 2,
      delay: const Duration(seconds: 2),
    );
  }

  /// Handles an error with automatic recovery
  Future<bool> handleError(dynamic error, {String? context}) async {
    final stepCounterError = _parseError(error, context);
    _logError(stepCounterError);
    _addToHistory(stepCounterError);
    _notifyListeners(stepCounterError);

    // Attempt recovery if possible
    if (stepCounterError.canRecover) {
      return await _attemptRecovery(stepCounterError);
    }

    return false;
  }

  /// Parses raw error into StepCounterError
  StepCounterError _parseError(dynamic error, String? context) {
    developer.log('StepCounterErrorHandler: Parsing error: $error', name: 'StepCounterErrorHandler');

    if (error is PlatformException) {
      return _parsePlatformException(error);
    }

    if (error is TimeoutException) {
      return StepCounterError.timeoutError();
    }

    if (error is String) {
      if (error.toLowerCase().contains('permission')) {
        return StepCounterError.permissionDenied();
      }
      if (error.toLowerCase().contains('not available') || error.toLowerCase().contains('not supported')) {
        return StepCounterError.deviceNotSupported();
      }
      if (error.toLowerCase().contains('network') || error.toLowerCase().contains('connection')) {
        return StepCounterError.networkError();
      }
      if (error.toLowerCase().contains('stream')) {
        return StepCounterError.streamError(error);
      }
      if (error.toLowerCase().contains('initialization') || error.toLowerCase().contains('initialize')) {
        return StepCounterError.initializationFailed(error);
      }
    }

    return StepCounterError.unknownError(error.toString());
  }

  /// Parses platform-specific exceptions
  StepCounterError _parsePlatformException(PlatformException error) {
    switch (error.code) {
      case 'PERMISSION_DENIED':
        return StepCounterError.permissionDenied();
      case 'PERMISSION_DENIED_NEVER_ASK':
        return StepCounterError.permissionPermanentlyDenied();
      case 'SERVICE_NOT_AVAILABLE':
        return StepCounterError.serviceUnavailable();
      case 'SENSOR_NOT_AVAILABLE':
        return StepCounterError.sensorNotAvailable();
      case 'NOT_SUPPORTED':
        return StepCounterError.deviceNotSupported();
      default:
        return StepCounterError.platformError('${error.code}: ${error.message}');
    }
  }

  /// Attempts recovery using appropriate strategy
  Future<bool> _attemptRecovery(StepCounterError error) async {
    final strategy = _recoveryStrategies[error.type];
    if (strategy == null) {
      developer.log('StepCounterErrorHandler: No recovery strategy for ${error.type}', name: 'StepCounterErrorHandler');
      return false;
    }

    developer.log('StepCounterErrorHandler: Attempting recovery with ${strategy.name}', name: 'StepCounterErrorHandler');

    for (int attempt = 1; attempt <= strategy.maxRetries; attempt++) {
      try {
        if (attempt > 1) {
          await Future.delayed(strategy.delay);
        }

        final success = await strategy.action();
        if (success) {
          developer.log('StepCounterErrorHandler: Recovery successful on attempt $attempt', name: 'StepCounterErrorHandler');
          return true;
        }
      } catch (e) {
        developer.log('StepCounterErrorHandler: Recovery attempt $attempt failed: $e', name: 'StepCounterErrorHandler');
      }
    }

    developer.log('StepCounterErrorHandler: Recovery failed after ${strategy.maxRetries} attempts', name: 'StepCounterErrorHandler');
    return false;
  }

  /// Recovery strategy: Request permission
  Future<bool> _requestPermission() async {
    try {
      final status = await Permission.activityRecognition.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  /// Recovery strategy: Retry service connection
  Future<bool> _retryServiceConnection() async {
    // This would be implemented to retry connecting to the pedometer service
    // For now, we'll simulate a retry
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Assume success for now
  }

  /// Recovery strategy: Restart stream
  Future<bool> _restartStream() async {
    // This would be implemented to restart the step counter stream
    // For now, we'll simulate a restart
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // Assume success for now
  }

  /// Recovery strategy: Retry initialization
  Future<bool> _retryInitialization() async {
    // This would be implemented to retry step counter initialization
    // For now, we'll simulate a retry
    await Future.delayed(const Duration(seconds: 1));
    return true; // Assume success for now
  }

  /// Recovery strategy: Retry with timeout
  Future<bool> _retryWithTimeout() async {
    // This would be implemented to retry with a longer timeout
    // For now, we'll simulate a retry
    await Future.delayed(const Duration(milliseconds: 800));
    return true; // Assume success for now
  }

  /// Logs error details
  void _logError(StepCounterError error) {
    final severity = error.severity.name.toUpperCase();
    developer.log(
      'StepCounterErrorHandler: [$severity] ${error.message}',
      name: 'StepCounterErrorHandler',
      error: error.technicalDetails,
    );
  }

  /// Adds error to history
  void _addToHistory(StepCounterError error) {
    _errorHistory.add(error);
    
    // Keep only last 50 errors to prevent memory issues
    if (_errorHistory.length > 50) {
      _errorHistory.removeRange(0, _errorHistory.length - 50);
    }
  }

  /// Notifies listeners of error
  void _notifyListeners(StepCounterError error) {
    if (!_errorStream.isClosed) {
      _errorStream.add(error);
    }
  }

  /// Gets user-friendly error message
  String getUserMessage(StepCounterError error) {
    switch (error.severity) {
      case ErrorSeverity.low:
        return error.message;
      case ErrorSeverity.medium:
        return '${error.message}${error.userAction != null ? '\n\n${error.userAction}' : ''}';
      case ErrorSeverity.high:
        return '${error.message}${error.userAction != null ? '\n\n${error.userAction}' : ''}';
      case ErrorSeverity.critical:
        return 'Critical Error: ${error.message}${error.userAction != null ? '\n\n${error.userAction}' : ''}';
    }
  }

  /// Gets error statistics
  Map<String, dynamic> getErrorStatistics() {
    if (_errorHistory.isEmpty) {
      return {
        'totalErrors': 0,
        'errorsByType': {},
        'errorsBySeverity': {},
        'lastError': null,
      };
    }

    final errorsByType = <String, int>{};
    final errorsBySeverity = <String, int>{};

    for (final error in _errorHistory) {
      final type = error.type.name;
      final severity = error.severity.name;

      errorsByType[type] = (errorsByType[type] ?? 0) + 1;
      errorsBySeverity[severity] = (errorsBySeverity[severity] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'errorsByType': errorsByType,
      'errorsBySeverity': errorsBySeverity,
      'lastError': _errorHistory.last.toString(),
    };
  }

  /// Clears error history
  void clearHistory() {
    _errorHistory.clear();
    developer.log('StepCounterErrorHandler: Error history cleared', name: 'StepCounterErrorHandler');
  }

  /// Checks if device supports step counting
  Future<bool> checkDeviceSupport() async {
    try {
      // Check if activity recognition permission is available
      final permissionStatus = await Permission.activityRecognition.status;
      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        return false;
      }

      // Additional device support checks can be added here
      return true;
    } catch (e) {
      developer.log('StepCounterErrorHandler: Device support check failed: $e', name: 'StepCounterErrorHandler');
      return false;
    }
  }

  /// Gets recommended actions for current error state
  List<String> getRecommendedActions() {
    if (_errorHistory.isEmpty) return [];

    final recentErrors = _errorHistory.where(
      (error) => DateTime.now().difference(error.timestamp).inMinutes < 10,
    ).toList();

    if (recentErrors.isEmpty) return [];

    final actions = <String>[];
    final errorTypes = recentErrors.map((e) => e.type).toSet();

    if (errorTypes.contains(StepCounterErrorType.permissionDenied)) {
      actions.add('Grant activity recognition permission');
    }

    if (errorTypes.contains(StepCounterErrorType.serviceUnavailable)) {
      actions.add('Check device sensors and restart the app');
    }

    if (errorTypes.contains(StepCounterErrorType.networkError)) {
      actions.add('Check internet connection for data sync');
    }

    if (errorTypes.contains(StepCounterErrorType.deviceNotSupported)) {
      actions.add('Use manual step tracking instead');
    }

    return actions;
  }

  /// Disposes error handler
  void dispose() {
    _errorStream.close();
    _errorHistory.clear();
    _recoveryStrategies.clear();
    developer.log('StepCounterErrorHandler: Disposed', name: 'StepCounterErrorHandler');
  }
}
