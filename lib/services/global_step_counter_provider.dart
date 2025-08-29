import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'step_counter_service.dart';
import 'daily_step_service.dart';
import 'step_counter_error_handler.dart';
import '../models/activity_model.dart';

/// Global Step Counter Provider that can be used across all screens
/// Manages real-time step counting and syncs with Firebase
/// Provides step data to Home, Dashboard, Profile, and Activity screens
class GlobalStepCounterProvider with ChangeNotifier {
  static final GlobalStepCounterProvider _instance = GlobalStepCounterProvider._internal();
  factory GlobalStepCounterProvider() => _instance;
  GlobalStepCounterProvider._internal();

  // Services
  final StepCounterService _stepCounterService = StepCounterService();
  final DailyStepService _dailyStepService = DailyStepService();
  final StepCounterErrorHandler _errorHandler = StepCounterErrorHandler();

  // Stream subscriptions
  StreamSubscription<StepCounterEvent>? _stepCounterEventSubscription;
  StreamSubscription<StepCounterError>? _errorSubscription;

  // State variables
  bool _isInitialized = false;
  bool _isPedometerAvailable = false;
  bool _isStepCounterListening = false;
  bool _isStepCounterActive = false;
  int _deviceSteps = 0;
  int _dailyStepBaseline = 0;
  int _manualSteps = 0;
  String? _stepCounterError;
  DateTime? _lastSyncTime;
  User? _currentUser;

  // Public getters
  bool get isInitialized => _isInitialized;
  bool get isPedometerAvailable => _isPedometerAvailable;
  bool get isStepCounterListening => _isStepCounterListening;
  bool get isStepCounterActive => _isStepCounterActive;
  int get deviceSteps => _deviceSteps;
  int get pedometerDailySteps => (_deviceSteps - _dailyStepBaseline).clamp(0, _deviceSteps);
  int get manualSteps => _manualSteps;
  
  /// Gets the total effective steps (pedometer + manual)
  int get totalSteps {
    if (_isPedometerAvailable && _isStepCounterListening) {
      return pedometerDailySteps + _manualSteps;
    }
    return _manualSteps;
  }

  /// Gets the primary step count for display (prioritizes pedometer)
  int get primarySteps {
    if (_isPedometerAvailable && _isStepCounterListening) {
      return pedometerDailySteps;
    }
    return _manualSteps;
  }

  String get stepCounterStatus {
    if (!_isPedometerAvailable) return 'Pedometer not available';
    if (_stepCounterError != null) return 'Error: $_stepCounterError';
    if (_isStepCounterListening) return 'Active';
    return 'Inactive';
  }

  bool get hasStepCounterError => _stepCounterError != null;
  String? get stepCounterError => _stepCounterError;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initializes the global step counter
  Future<bool> initialize() async {
    if (_isInitialized) return _isPedometerAvailable;

    developer.log('GlobalStepCounterProvider: Initializing...', name: 'GlobalStepCounterProvider');
    
    try {
      // Get current user
      _currentUser = FirebaseAuth.instance.currentUser;
      
      if (_currentUser == null) {
        developer.log('GlobalStepCounterProvider: No authenticated user', name: 'GlobalStepCounterProvider');
        return false;
      }

      // Initialize step counter service
      final initialized = await _stepCounterService.initialize();
      
      if (initialized) {
        _isPedometerAvailable = _stepCounterService.isPedometerAvailable;
        
        // Set up event listener
        _setupStepCounterListener();
        
        // Request permissions and start if available
        if (_isPedometerAvailable) {
          await _requestPermissionsAndStart();
        }
        
        _isInitialized = true;
        notifyListeners();
        
        developer.log('GlobalStepCounterProvider: Initialization complete', name: 'GlobalStepCounterProvider');
        return true;
      } else {
        _stepCounterError = 'Failed to initialize step counter';
        notifyListeners();
        return false;
      }
    } catch (e) {
      developer.log('GlobalStepCounterProvider: Initialization failed: $e', name: 'GlobalStepCounterProvider');
      _stepCounterError = 'Initialization error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Requests permissions and starts step counter
  Future<void> _requestPermissionsAndStart() async {
    try {
      final hasPermissions = await _stepCounterService.requestPermissions();
      
      if (hasPermissions) {
        final started = await _stepCounterService.startListening();
        _isStepCounterListening = started;
        _isStepCounterActive = started;
        _stepCounterError = null;
        
        if (started) {
          developer.log('GlobalStepCounterProvider: Step counter started successfully', name: 'GlobalStepCounterProvider');
        }
      } else {
        _stepCounterError = 'Activity recognition permission denied';
        developer.log('GlobalStepCounterProvider: Permissions denied', name: 'GlobalStepCounterProvider');
      }
      
      notifyListeners();
    } catch (e) {
      _stepCounterError = 'Failed to start step counter: $e';
      notifyListeners();
    }
  }

  /// Sets up step counter event listener
  void _setupStepCounterListener() {
    _stepCounterEventSubscription?.cancel();
    
    _stepCounterEventSubscription = _stepCounterService.eventStream.listen(
      _onStepCounterEvent,
      onError: (error) {
        developer.log('GlobalStepCounterProvider: Step counter stream error: $error', name: 'GlobalStepCounterProvider');
        _stepCounterError = 'Stream error: $error';
        notifyListeners();
      },
    );
    
    developer.log('GlobalStepCounterProvider: Step counter listener setup complete', name: 'GlobalStepCounterProvider');
  }

  /// Handles step counter events
  void _onStepCounterEvent(StepCounterEvent event) {
    developer.log('GlobalStepCounterProvider: Step counter event: ${event.type}', name: 'GlobalStepCounterProvider');
    
    switch (event.type) {
      case StepCounterEventType.initialized:
        _isPedometerAvailable = true;
        _stepCounterError = null;
        break;
        
      case StepCounterEventType.listeningStarted:
        _isStepCounterListening = true;
        _isStepCounterActive = true;
        _stepCounterError = null;
        break;
        
      case StepCounterEventType.listeningStopped:
        _isStepCounterListening = false;
        _isStepCounterActive = false;
        break;
        
      case StepCounterEventType.stepsUpdated:
        if (event.dailySteps != null && event.deviceSteps != null) {
          _deviceSteps = event.deviceSteps!;
          _dailyStepBaseline = event.deviceSteps! - event.dailySteps!;
          
          // Sync with Firebase if significant change
          _syncStepsWithFirebase(event.dailySteps!);
        }
        break;
        
      case StepCounterEventType.baselineReset:
        developer.log('GlobalStepCounterProvider: Baseline reset', name: 'GlobalStepCounterProvider');
        break;
        
      case StepCounterEventType.newDay:
        developer.log('GlobalStepCounterProvider: New day detected', name: 'GlobalStepCounterProvider');
        break;
        
      case StepCounterEventType.error:
        _stepCounterError = event.message;
        _isStepCounterActive = false;
        break;
    }
    
    notifyListeners();
  }

  /// Syncs pedometer steps with Firebase
  Future<void> _syncStepsWithFirebase(int pedometerSteps) async {
    if (_currentUser == null) return;
    
    try {
      // Only sync if significant difference or enough time has passed
      final now = DateTime.now();
      final shouldSync = _lastSyncTime == null || 
                        now.difference(_lastSyncTime!).inMinutes >= 1 ||
                        (pedometerSteps - (_manualSteps)).abs() > 10;
      
      if (shouldSync) {
        developer.log('GlobalStepCounterProvider: Syncing $pedometerSteps pedometer steps to Firebase', name: 'GlobalStepCounterProvider');
        
        final userWeight = 70.0; // Default weight - should get from user profile
        final distance = ActivityModel.estimateDistance(pedometerSteps);
        final calories = ActivityModel.estimateCalories(pedometerSteps, userWeight);
        
        // Use DailyStepService to update pedometer steps
        await _dailyStepService.updatePedometerSteps(
          _currentUser!.uid,
          now,
          pedometerSteps,
          distance,
          calories,
        );
        
        _lastSyncTime = now;
        developer.log('GlobalStepCounterProvider: Pedometer steps synced successfully', name: 'GlobalStepCounterProvider');
      }
    } catch (e) {
      developer.log('GlobalStepCounterProvider: Failed to sync pedometer steps: $e', name: 'GlobalStepCounterProvider');
      
      // Handle error through error handler
      await _errorHandler.handleError(e, context: 'global_step_sync');
    }
  }

  /// Updates manual steps count (called when user manually adds steps)
  void updateManualSteps(int steps) {
    _manualSteps = steps;
    notifyListeners();
    developer.log('GlobalStepCounterProvider: Manual steps updated to $steps', name: 'GlobalStepCounterProvider');
  }

  /// Resets the daily step baseline for testing
  Future<void> resetStepBaseline() async {
    if (_isInitialized) {
      await _stepCounterService.resetDailyBaseline();
      developer.log('GlobalStepCounterProvider: Step baseline reset', name: 'GlobalStepCounterProvider');
    }
  }

  /// Starts the step counter
  Future<bool> startStepCounter() async {
    if (!_isInitialized || !_isPedometerAvailable) return false;
    
    try {
      final success = await _stepCounterService.startListening();
      _isStepCounterListening = success;
      _isStepCounterActive = success;
      _stepCounterError = success ? null : 'Failed to start step counter';
      notifyListeners();
      return success;
    } catch (e) {
      _stepCounterError = 'Start failed: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stops the step counter
  Future<void> stopStepCounter() async {
    if (!_isInitialized) return;
    
    try {
      await _stepCounterService.stopListening();
      _isStepCounterListening = false;
      _isStepCounterActive = false;
      _stepCounterError = null;
      notifyListeners();
    } catch (e) {
      _stepCounterError = 'Stop failed: $e';
      notifyListeners();
    }
  }

  /// Gets debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isPedometerAvailable': _isPedometerAvailable,
      'isStepCounterListening': _isStepCounterListening,
      'deviceSteps': _deviceSteps,
      'pedometerDailySteps': pedometerDailySteps,
      'manualSteps': _manualSteps,
      'totalSteps': totalSteps,
      'primarySteps': primarySteps,
      'stepCounterStatus': stepCounterStatus,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'hasUser': _currentUser != null,
    };
  }

  /// Disposes of resources
  @override
  void dispose() {
    developer.log('GlobalStepCounterProvider: Disposing...', name: 'GlobalStepCounterProvider');
    
    _stepCounterEventSubscription?.cancel();
    _errorSubscription?.cancel();
    _stepCounterService.dispose();
    _errorHandler.dispose();
    
    super.dispose();
    
    developer.log('GlobalStepCounterProvider: Disposed successfully', name: 'GlobalStepCounterProvider');
  }
}
