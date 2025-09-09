import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

/// Service that handles step counting functionality using device pedometer
/// Manages baseline tracking, daily resets, and data persistence
class StepCounterService {
  static final StepCounterService _instance = StepCounterService._internal();
  factory StepCounterService() => _instance;
  StepCounterService._internal();

  // Stream controllers
  StreamSubscription<StepCount>? _stepCountStream;
  final StreamController<StepCounterEvent> _eventController = 
      StreamController<StepCounterEvent>.broadcast();

  // Internal state
  bool _isListening = false;
  bool _isPedometerAvailable = false;
  int _deviceSteps = 0;
  int _dailyStepBaseline = 0;
  String _currentDate = '';
  SharedPreferences? _prefs;

  // Constants
  static const String _keyStepBaseline = 'step_baseline';
  static const String _keyBaselineDate = 'baseline_date';
  static const String _keyLastKnownSteps = 'last_known_steps';

  // Public getters
  bool get isListening => _isListening;
  bool get isPedometerAvailable => _isPedometerAvailable;
  int get deviceSteps => _deviceSteps;
  int get dailySteps => (_deviceSteps - _dailyStepBaseline).clamp(0, _deviceSteps);
  Stream<StepCounterEvent> get eventStream => _eventController.stream;

  /// Initializes the step counter service
  Future<bool> initialize() async {
    developer.log('StepCounterService: Initializing...', name: 'StepCounterService');
    
    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // Check pedometer availability
      _isPedometerAvailable = await _checkPedometerAvailability();
      
      if (!_isPedometerAvailable) {
        developer.log('StepCounterService: Pedometer not available', name: 'StepCounterService');
        _emitEvent(StepCounterEvent.error('Pedometer not available on this device'));
        return false;
      }

      // Load saved data
      await _loadSavedData();
      
      // Check if we need to reset baseline (new day)
      await _checkAndResetDailyBaseline();
      
      developer.log('StepCounterService: Initialization complete', name: 'StepCounterService');
      _emitEvent(StepCounterEvent.initialized());
      return true;
    } catch (e) {
      developer.log('StepCounterService: Initialization failed: $e', name: 'StepCounterService');
      _emitEvent(StepCounterEvent.error('Failed to initialize step counter: $e'));
      return false;
    }
  }

  /// Requests necessary permissions for step counting
  Future<bool> requestPermissions() async {
    developer.log('StepCounterService: Requesting permissions...', name: 'StepCounterService');
    
    try {
      final status = await Permission.activityRecognition.request();
      final granted = status == PermissionStatus.granted;
      
      developer.log('StepCounterService: Permission granted: $granted', name: 'StepCounterService');
      
      if (!granted) {
        _emitEvent(StepCounterEvent.error('Activity recognition permission denied'));
      }
      
      return granted;
    } catch (e) {
      developer.log('StepCounterService: Permission request failed: $e', name: 'StepCounterService');
      _emitEvent(StepCounterEvent.error('Failed to request permissions: $e'));
      return false;
    }
  }

  /// Starts listening to step count events
  Future<bool> startListening() async {
    if (_isListening) {
      developer.log('StepCounterService: Already listening', name: 'StepCounterService');
      return true;
    }

    if (!_isPedometerAvailable) {
      developer.log('StepCounterService: Cannot start - pedometer not available', name: 'StepCounterService');
      return false;
    }

    developer.log('StepCounterService: Starting step counter...', name: 'StepCounterService');
    
    try {
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );
      
      _isListening = true;
      developer.log('StepCounterService: Step counter started', name: 'StepCounterService');
      _emitEvent(StepCounterEvent.listeningStarted());
      return true;
    } catch (e) {
      developer.log('StepCounterService: Failed to start listening: $e', name: 'StepCounterService');
      _emitEvent(StepCounterEvent.error('Failed to start step counter: $e'));
      return false;
    }
  }

  /// Stops listening to step count events
  Future<void> stopListening() async {
    if (!_isListening) return;

    developer.log('StepCounterService: Stopping step counter...', name: 'StepCounterService');
    
    await _stepCountStream?.cancel();
    _stepCountStream = null;
    _isListening = false;
    
    developer.log('StepCounterService: Step counter stopped', name: 'StepCounterService');
    _emitEvent(StepCounterEvent.listeningStopped());
  }

  /// Manually resets the daily step baseline for testing
  Future<void> resetDailyBaseline() async {
    developer.log('StepCounterService: Manual baseline reset requested', name: 'StepCounterService');
    
    _dailyStepBaseline = _deviceSteps;
    _currentDate = _getCurrentDateString();
    
    await _saveData();
    
    developer.log('StepCounterService: Baseline reset to $_dailyStepBaseline', name: 'StepCounterService');
    _emitEvent(StepCounterEvent.baselineReset(dailySteps));
  }

  /// Checks pedometer availability
  Future<bool> _checkPedometerAvailability() async {
    try {
      // Try to get permission status first
      final permission = await Permission.activityRecognition.status;
      if (permission == PermissionStatus.permanentlyDenied) {
        return false;
      }
      
      // Test if pedometer stream is available by subscribing briefly
      final completer = Completer<bool>();
      StreamSubscription? testSub;
      Timer? timeoutTimer;
      
      timeoutTimer = Timer(const Duration(seconds: 3), () {
        testSub?.cancel();
        if (!completer.isCompleted) completer.complete(false);
      });
      
      testSub = Pedometer.stepCountStream.listen(
        (steps) {
          timeoutTimer?.cancel();
          testSub?.cancel();
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (error) {
          timeoutTimer?.cancel();
          testSub?.cancel();
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      
      return await completer.future;
    } catch (e) {
      developer.log('StepCounterService: Pedometer availability check failed: $e', name: 'StepCounterService');
      return false;
    }
  }

  /// Handles step count events from the pedometer
  void _onStepCount(StepCount event) {
    _deviceSteps = event.steps;
    final currentDailySteps = dailySteps;
    
    developer.log(
      'StepCounterService: Step count update - Device: $_deviceSteps, Daily: $currentDailySteps', 
      name: 'StepCounterService'
    );
    
    // Save the latest step count
    _saveLastKnownSteps();
    
    _emitEvent(StepCounterEvent.stepsUpdated(currentDailySteps, _deviceSteps));
  }

  /// Handles step count errors
  void _onStepCountError(error) {
    developer.log('StepCounterService: Step count error: $error', name: 'StepCounterService');
    _emitEvent(StepCounterEvent.error('Step counter error: $error'));
  }

  /// Loads saved data from SharedPreferences
  Future<void> _loadSavedData() async {
    if (_prefs == null) return;
    
    _dailyStepBaseline = _prefs!.getInt(_keyStepBaseline) ?? 0;
    _currentDate = _prefs!.getString(_keyBaselineDate) ?? _getCurrentDateString();
    _deviceSteps = _prefs!.getInt(_keyLastKnownSteps) ?? 0;
    
    developer.log(
      'StepCounterService: Loaded data - Baseline: $_dailyStepBaseline, Date: $_currentDate, Device: $_deviceSteps', 
      name: 'StepCounterService'
    );
  }

  /// Saves current data to SharedPreferences
  Future<void> _saveData() async {
    if (_prefs == null) return;
    
    await _prefs!.setInt(_keyStepBaseline, _dailyStepBaseline);
    await _prefs!.setString(_keyBaselineDate, _currentDate);
    await _prefs!.setInt(_keyLastKnownSteps, _deviceSteps);
  }

  /// Saves only the last known steps count
  Future<void> _saveLastKnownSteps() async {
    if (_prefs == null) return;
    await _prefs!.setInt(_keyLastKnownSteps, _deviceSteps);
  }

  /// Checks if we need to reset baseline for a new day
  Future<void> _checkAndResetDailyBaseline() async {
    final currentDate = _getCurrentDateString();
    
    if (_currentDate != currentDate) {
      developer.log(
        'StepCounterService: New day detected ($_currentDate -> $currentDate), resetting baseline', 
        name: 'StepCounterService'
      );
      
      // Reset baseline to current device steps for new day
      _dailyStepBaseline = _deviceSteps;
      _currentDate = currentDate;
      
      await _saveData();
      _emitEvent(StepCounterEvent.newDay(currentDate));
    }
  }

  /// Gets current date string in YYYY-MM-dd format
  String _getCurrentDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  /// Emits an event to listeners
  void _emitEvent(StepCounterEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Disposes of resources
  Future<void> dispose() async {
    developer.log('StepCounterService: Disposing...', name: 'StepCounterService');
    
    await stopListening();
    await _eventController.close();
    
    developer.log('StepCounterService: Disposed', name: 'StepCounterService');
  }
}

/// Event types for step counter service
enum StepCounterEventType {
  initialized,
  listeningStarted,
  listeningStopped,
  stepsUpdated,
  baselineReset,
  newDay,
  error,
}

/// Step counter event data
class StepCounterEvent {
  final StepCounterEventType type;
  final int? dailySteps;
  final int? deviceSteps;
  final String? message;
  final DateTime timestamp;

  StepCounterEvent._({
    required this.type,
    this.dailySteps,
    this.deviceSteps,
    this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory StepCounterEvent.initialized() => StepCounterEvent._(
    type: StepCounterEventType.initialized,
  );

  factory StepCounterEvent.listeningStarted() => StepCounterEvent._(
    type: StepCounterEventType.listeningStarted,
  );

  factory StepCounterEvent.listeningStopped() => StepCounterEvent._(
    type: StepCounterEventType.listeningStopped,
  );

  factory StepCounterEvent.stepsUpdated(int dailySteps, int deviceSteps) => StepCounterEvent._(
    type: StepCounterEventType.stepsUpdated,
    dailySteps: dailySteps,
    deviceSteps: deviceSteps,
  );

  factory StepCounterEvent.baselineReset(int dailySteps) => StepCounterEvent._(
    type: StepCounterEventType.baselineReset,
    dailySteps: dailySteps,
  );

  factory StepCounterEvent.newDay(String date) => StepCounterEvent._(
    type: StepCounterEventType.newDay,
    message: date,
  );

  factory StepCounterEvent.error(String error) => StepCounterEvent._(
    type: StepCounterEventType.error,
    message: error,
  );

  @override
  String toString() {
    return 'StepCounterEvent(type: $type, dailySteps: $dailySteps, deviceSteps: $deviceSteps, message: $message)';
  }
}
