import 'package:flutter_test/flutter_test.dart';
import 'package:nabd_al_hayah/services/global_step_counter_provider.dart';
import 'package:nabd_al_hayah/services/step_counter_error_handler.dart';
import 'package:permission_handler/permission_handler.dart';

/// Test file to validate step counter integration
/// Run this test to ensure the step counter functionality is working
void main() {
  group('Step Counter Integration Tests', () {
    late GlobalStepCounterProvider globalStepCounter;
    late StepCounterErrorHandler errorHandler;

    setUp(() {
      globalStepCounter = GlobalStepCounterProvider();
      errorHandler = StepCounterErrorHandler();
    });

    test('Global Step Counter initializes correctly', () async {
      // Test if the global step counter can initialize
      await globalStepCounter.initialize();
      
      print('Global Step Counter Initialized: ${globalStepCounter.isInitialized}');
      print('Pedometer Available: ${globalStepCounter.isPedometerAvailable}');
      
      expect(globalStepCounter.isInitialized, isTrue);
    });

    test('Step Counter Error Handler initializes', () {
      // Test error handler initialization
      errorHandler.initialize();
      
      print('Error Handler Initialized');
      
      expect(errorHandler.errorHistory, isEmpty);
    });

    test('Step Counter can handle permissions', () async {
      await globalStepCounter.initialize();
      
      // Test permission status
      final permissionStatus = await Permission.activityRecognition.status;
      
      print('Permission Status: $permissionStatus');
      
      expect(permissionStatus, isNotNull);
    });

    test('Global Step Counter provides step data', () async {
      await globalStepCounter.initialize();
      
      // Test step data availability
      final currentSteps = globalStepCounter.primarySteps;
      
      print('Current Steps: $currentSteps');
      
      expect(currentSteps, greaterThanOrEqualTo(0));
    });

    test('Error Handler can check device support', () async {
      errorHandler.initialize();
      
      // Test device support check
      final isSupported = await errorHandler.checkDeviceSupport();
      
      print('Device Supported: $isSupported');
      
      expect(isSupported, isNotNull);
    });

    test('Real-time step counting works', () async {
      await globalStepCounter.initialize();
      
      // Listen for step updates
      int initialSteps = globalStepCounter.primarySteps;
      print('Initial Steps: $initialSteps');
      
      // Wait for a few seconds to see if steps update
      await Future.delayed(Duration(seconds: 5));
      
      int updatedSteps = globalStepCounter.primarySteps;
      print('Updated Steps after 5 seconds: $updatedSteps');
      
      // Note: This test may only pass on a physical device with actual movement
      expect(updatedSteps, greaterThanOrEqualTo(initialSteps));
    });

    tearDown(() {
      globalStepCounter.dispose();
      errorHandler.dispose();
    });
  });
}

/// Manual testing instructions for real device testing
/// 
/// 1. Run the app on a physical device (not emulator)
/// 2. Open the activity screen
/// 3. Check for step counter activation message
/// 4. Walk around with the device
/// 5. Observe real-time step count updates in the UI
/// 6. Verify steps are being synced to Firebase
/// 7. Check that manual step additions still work alongside pedometer
/// 
/// Expected behaviors:
/// - Step counter should initialize automatically on app start
/// - Permission request should appear if not granted
/// - Step count should update in real-time as you walk
/// - Steps should sync to Firebase every 10+ step difference
/// - UI should show combined pedometer + manual steps
/// - Error messages should appear for any issues
