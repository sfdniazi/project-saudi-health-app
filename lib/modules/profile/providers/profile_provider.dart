import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import '../models/profile_state_model.dart';
import '../../../models/user_model.dart';
import '../../../services/firebase_service.dart';
import '../../../services/global_step_counter_provider.dart';
import '../../../core/app_theme.dart';

class ProfileProvider with ChangeNotifier {
  // Private fields
  ProfileStateModel _profileState = ProfileStateModel.initial();
  UserModel? _userModel;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Global step counter reference
  GlobalStepCounterProvider? _globalStepCounter;
  
  // Notification settings
  bool _mealRemindersEnabled = true;
  bool _waterRemindersEnabled = true;
  bool _goalAchievementsEnabled = false;
  
  // Privacy settings
  bool _biometricLoginEnabled = false;

  // Getters
  ProfileStateModel get profileState => _profileState;
  UserModel? get userModel => _userModel;
  bool get isLoading => _profileState.isLoading;
  bool get isBusy => _profileState.isBusy;
  bool get hasError => _profileState.hasError;
  String? get errorMessage => _profileState.errorMessage;
  String? get successMessage => _profileState.successMessage;
  User? get currentUser => _auth.currentUser;
  
  // Notification settings getters
  bool get mealRemindersEnabled => _mealRemindersEnabled;
  bool get waterRemindersEnabled => _waterRemindersEnabled;
  bool get goalAchievementsEnabled => _goalAchievementsEnabled;
  
  // Privacy settings getters
  bool get biometricLoginEnabled => _biometricLoginEnabled;
  
  // Step counter getters
  int get currentSteps {
    if (_globalStepCounter != null && _globalStepCounter!.isInitialized) {
      return _globalStepCounter!.primarySteps;
    }
    return 0;
  }

  /// Gets real-time step count with Firebase fallback
  /// Returns GlobalStepCounterProvider data if available, otherwise Firebase data
  int getRealTimeStepCount({int? firebaseSteps}) {
    try {
      // Priority 1: Real-time steps from GlobalStepCounterProvider
      if (_globalStepCounter != null && 
          _globalStepCounter!.isInitialized && 
          _globalStepCounter!.isPedometerAvailable &&
          !_globalStepCounter!.hasStepCounterError) {
        
        final realTimeSteps = _globalStepCounter!.totalSteps;
        // Use real-time data if it's reasonable (greater than 0 and not absurdly high)
        if (realTimeSteps >= 0 && realTimeSteps < 100000) {
          debugPrint('ProfileProvider: Using real-time steps: $realTimeSteps');
          return realTimeSteps;
        }
      }
      
      // Priority 2: Firebase data as fallback (online connectivity)
      if (firebaseSteps != null && firebaseSteps >= 0) {
        debugPrint('ProfileProvider: Using Firebase fallback steps: $firebaseSteps');
        return firebaseSteps;
      }
      
      // Priority 3: Manual steps from GlobalStepCounterProvider (offline scenario)
      if (_globalStepCounter != null) {
        final manualSteps = _globalStepCounter!.manualSteps;
        if (manualSteps > 0) {
          debugPrint('ProfileProvider: Using manual steps as offline fallback: $manualSteps');
          return manualSteps;
        }
      }
      
      // Priority 4: Device steps even without initialization (emergency fallback)
      if (_globalStepCounter != null && _globalStepCounter!.deviceSteps > 0) {
        final deviceSteps = _globalStepCounter!.pedometerDailySteps;
        if (deviceSteps >= 0 && deviceSteps < 100000) {
          debugPrint('ProfileProvider: Using emergency device steps fallback: $deviceSteps');
          return deviceSteps;
        }
      }
      
    } catch (e) {
      debugPrint('ProfileProvider: Error in getRealTimeStepCount: $e');
    }
    
    // Final fallback - return 0 if all methods fail
    debugPrint('ProfileProvider: All step count sources failed, returning 0');
    return 0;
  }

  /// Checks if real-time step data is available
  bool get hasRealTimeStepData {
    return _globalStepCounter != null && 
           _globalStepCounter!.isInitialized && 
           _globalStepCounter!.isPedometerAvailable;
  }

  /// Initialize provider
  ProfileProvider() {
    _initializeProfile();
  }

  /// Initialize profile data
  Future<void> _initializeProfile() async {
    try {
      _setProfileState(ProfileStateModel.loading());
      
      // Load user profile if authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      }
      
      // Load settings from SharedPreferences
      await _loadSettings();
      
      _setProfileState(ProfileStateModel.loaded());
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to initialize profile: ${e.toString()}'));
    }
  }

  /// Set profile state and notify listeners
  void _setProfileState(ProfileStateModel state) {
    _profileState = state;
    notifyListeners();
  }

  /// Load user profile from Firebase
  Future<void> _loadUserProfile(String uid) async {
    try {
      final userProfile = await FirebaseService.getCurrentUserProfile();
      _userModel = userProfile;
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // Don't throw error here, just continue without profile data
    }
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    try {
      _setProfileState(ProfileStateModel.loading());
      
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      }
      
      _setProfileState(ProfileStateModel.loaded(successMessage: 'Profile refreshed'));
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to refresh profile: ${e.toString()}'));
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    double? idealWeight,
    String? units,
  }) async {
    try {
      _setProfileState(ProfileStateModel.updating(isProfileUpdating: true));

      await FirebaseService.updateUserData(
        displayName: displayName,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        idealWeight: idealWeight,
        units: units,
      );

      // Reload profile after update
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      }

      _setProfileState(ProfileStateModel.updated(
        successMessage: 'Profile updated successfully!',
      ));

      // Reset to loaded state after showing success message
      await Future.delayed(const Duration(milliseconds: 500));
      _setProfileState(ProfileStateModel.loaded());
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to update profile: ${e.toString()}'));
    }
  }

  /// Update daily goal
  Future<void> updateDailyGoal(int dailyGoal) async {
    try {
      _setProfileState(ProfileStateModel.updating());

      await FirebaseService.updateUserData(dailyGoal: dailyGoal);

      // Reload profile after update
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      }

      _setProfileState(ProfileStateModel.updated(
        successMessage: 'Daily goal updated successfully!',
      ));

      // Reset to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      _setProfileState(ProfileStateModel.loaded());
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to update daily goal: ${e.toString()}'));
    }
  }

  /// Update units preference
  Future<void> updateUnits(String units) async {
    try {
      _setProfileState(ProfileStateModel.updating());

      await FirebaseService.updateUserData(units: units);

      // Reload profile after update
      final user = _auth.currentUser;
      if (user != null) {
        await _loadUserProfile(user.uid);
      }

      _setProfileState(ProfileStateModel.updated(
        successMessage: 'Units updated successfully!',
      ));

      // Reset to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      _setProfileState(ProfileStateModel.loaded());
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to update units: ${e.toString()}'));
    }
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mealRemindersEnabled = prefs.getBool('meal_reminders') ?? true;
      _waterRemindersEnabled = prefs.getBool('water_reminders') ?? true;
      _goalAchievementsEnabled = prefs.getBool('goal_achievements') ?? false;
      _biometricLoginEnabled = prefs.getBool('biometric_login') ?? false;
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('meal_reminders', _mealRemindersEnabled);
      await prefs.setBool('water_reminders', _waterRemindersEnabled);
      await prefs.setBool('goal_achievements', _goalAchievementsEnabled);
      await prefs.setBool('biometric_login', _biometricLoginEnabled);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// Update notification setting
  Future<void> updateNotificationSetting(String type, bool enabled) async {
    try {
      _setProfileState(ProfileStateModel.updating());

      switch (type) {
        case 'meal_reminders':
          _mealRemindersEnabled = enabled;
          break;
        case 'water_reminders':
          _waterRemindersEnabled = enabled;
          break;
        case 'goal_achievements':
          _goalAchievementsEnabled = enabled;
          break;
      }

      await _saveSettings();

      _setProfileState(ProfileStateModel.updated(
        successMessage: 'Notification settings updated',
      ));

      // Reset to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      _setProfileState(ProfileStateModel.loaded());
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to update notification settings: ${e.toString()}'));
    }
  }

  /// Toggle biometric login
  Future<void> toggleBiometricLogin(bool enabled) async {
    try {
      _setProfileState(ProfileStateModel.updating());

      if (enabled) {
        // Check if biometric authentication is available
        final isAvailable = await _localAuth.canCheckBiometrics;
        if (!isAvailable) {
          _setProfileState(ProfileStateModel.error('Biometric authentication is not available on this device'));
          return;
        }

        // Get available biometric types
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        if (availableBiometrics.isEmpty) {
          _setProfileState(ProfileStateModel.error('No biometric authentication methods are set up'));
          return;
        }

        // Test biometric authentication
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please verify your identity to enable biometric login',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (!didAuthenticate) {
          _setProfileState(ProfileStateModel.error('Biometric authentication failed'));
          return;
        }
      }

      _biometricLoginEnabled = enabled;
      await _saveSettings();

      _setProfileState(ProfileStateModel.updated(
        successMessage: enabled
            ? 'Biometric login enabled successfully'
            : 'Biometric login disabled',
      ));

      // Reset to loaded state
      await Future.delayed(const Duration(milliseconds: 500));
      _setProfileState(ProfileStateModel.loaded());
    } catch (e) {
      _setProfileState(ProfileStateModel.error('Failed to update biometric login: ${e.toString()}'));
    }
  }

  /// ✅ Logout functionality with proper navigation
  Future<void> logout(BuildContext context) async {
    try {
      _setProfileState(ProfileStateModel.loggingOut());

      // Sign out from Firebase Auth directly
      await _auth.signOut();

      // Clear local profile state
      _userModel = null;
      _setProfileState(ProfileStateModel.initial());

      // Navigate to login screen
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      // Even if there's an error, proceed with navigation
      debugPrint('Logout error (non-critical): $e');
      
      // Clear local state anyway
      _userModel = null;
      _setProfileState(ProfileStateModel.initial());
      
      // Navigate to login screen
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    if (_profileState.hasError || _profileState.successMessage != null) {
      _setProfileState(_profileState.copyWith(
        errorMessage: null,
        successMessage: null,
      ));
    }
  }


  /// Get BMI status color based on BMI value
  Color getBMIStatusColor() {
    if (_userModel == null || _userModel!.bmi <= 0) {
      return AppTheme.textSecondary;
    }

    final bmi = _userModel!.bmi;
    if (bmi < 18.5) {
      return AppTheme.accentBlue; // Underweight
    } else if (bmi < 25) {
      return AppTheme.primaryGreen; // Normal
    } else if (bmi < 30) {
      return AppTheme.accentOrange; // Overweight
    } else {
      return Colors.red; // Obese
    }
  }
  
  // =================== STEP COUNTER METHODS ===================
  
  /// Sets the global step counter reference (called from UI)
  void setGlobalStepCounter(GlobalStepCounterProvider globalStepCounter) {
    // Remove existing listener if present
    if (_globalStepCounter != null) {
      _globalStepCounter!.removeListener(_onGlobalStepCounterChanged);
      debugPrint('ProfileProvider: Removed existing GlobalStepCounterProvider listener');
    }
    
    _globalStepCounter = globalStepCounter;
    
    // Listen to step counter changes
    _globalStepCounter!.addListener(_onGlobalStepCounterChanged);
    
    debugPrint('ProfileProvider: Connected to GlobalStepCounterProvider (isInitialized: ${_globalStepCounter!.isInitialized}, isPedometer: ${_globalStepCounter!.isPedometerAvailable})');
    notifyListeners(); // Trigger UI update with new step data
  }
  
  /// Called when global step counter changes
  void _onGlobalStepCounterChanged() {
    debugPrint('ProfileProvider: Global step counter updated - Steps: ${_globalStepCounter?.totalSteps ?? 'N/A'}');
    // Trigger UI update when step count changes
    notifyListeners();
  }
  
  /// Forces a refresh of step counter connection
  void refreshStepCounterConnection() {
    if (_globalStepCounter != null && !_globalStepCounter!.isInitialized) {
      debugPrint('ProfileProvider: Attempting to reconnect to GlobalStepCounterProvider');
      notifyListeners();
    }
  }
  
  /// Get debug information for step count verification
  Map<String, dynamic> getStepCountDebugInfo({int? firebaseSteps}) {
    final debugInfo = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'hasGlobalStepCounter': _globalStepCounter != null,
      'globalStepCounterInitialized': _globalStepCounter?.isInitialized ?? false,
      'pedometerAvailable': _globalStepCounter?.isPedometerAvailable ?? false,
      'hasStepCounterError': _globalStepCounter?.hasStepCounterError ?? false,
      'stepCounterError': _globalStepCounter?.stepCounterError,
      'globalTotalSteps': _globalStepCounter?.totalSteps ?? 0,
      'globalPrimarySteps': _globalStepCounter?.primarySteps ?? 0,
      'globalManualSteps': _globalStepCounter?.manualSteps ?? 0,
      'globalDeviceSteps': _globalStepCounter?.deviceSteps ?? 0,
      'globalPedometerDailySteps': _globalStepCounter?.pedometerDailySteps ?? 0,
      'firebaseSteps': firebaseSteps ?? 0,
      'calculatedRealTimeSteps': getRealTimeStepCount(firebaseSteps: firebaseSteps),
      'hasRealTimeStepData': hasRealTimeStepData,
    };
    
    // Add global step counter debug info if available
    if (_globalStepCounter != null) {
      try {
        debugInfo['globalDebugInfo'] = _globalStepCounter!.getDebugInfo();
      } catch (e) {
        debugInfo['globalDebugInfoError'] = e.toString();
      }
    }
    
    return debugInfo;
  }
  
  /// Logs step count verification info for debugging
  void logStepCountVerification({int? firebaseSteps}) {
    final debugInfo = getStepCountDebugInfo(firebaseSteps: firebaseSteps);
    debugPrint('ProfileProvider Step Count Verification:');
    debugPrint('==========================================');
    for (final entry in debugInfo.entries) {
      debugPrint('${entry.key}: ${entry.value}');
    }
    debugPrint('==========================================');
  }
  
  @override
  void dispose() {
    // Remove listener from global step counter
    if (_globalStepCounter != null) {
      _globalStepCounter!.removeListener(_onGlobalStepCounterChanged);
    }
    
    super.dispose();
  }

}
