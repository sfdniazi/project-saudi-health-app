import 'package:flutter/material.dart';
import '../screens/water_tracking_screen.dart';

/// 💧 Water tracking provider for managing water intake data
class WaterTrackingProvider extends ChangeNotifier {
  // Private variables
  int _currentIntake = 1000; // ml consumed today
  int _dailyGoal = 2400; // daily goal in ml
  bool _goalEnabled = true;
  bool _morningReminder = true;
  bool _afternoonReminder = false;
  bool _eveningReminder = true;

  // Sample history data
  final List<WaterEntry> _todayHistory = [
    WaterEntry(timestamp: DateTime.now().subtract(const Duration(hours: 2)), amount: 8),
    WaterEntry(timestamp: DateTime.now().subtract(const Duration(hours: 3)), amount: 4),
    WaterEntry(timestamp: DateTime.now().subtract(const Duration(hours: 5)), amount: 8),
    WaterEntry(timestamp: DateTime.now().subtract(const Duration(hours: 7)), amount: 8),
  ];

  // Getters
  int get currentIntake => _currentIntake;
  int get dailyGoal => _dailyGoal;
  bool get goalEnabled => _goalEnabled;
  bool get morningReminder => _morningReminder;
  bool get afternoonReminder => _afternoonReminder;
  bool get eveningReminder => _eveningReminder;
  List<WaterEntry> get todayHistory => _todayHistory;

  /// Progress as percentage (0.0 to 1.0)
  double get progressPercentage {
    return (_currentIntake / _dailyGoal).clamp(0.0, 1.0);
  }

  /// Number of glasses completed (assuming 250ml per glass)
  int get glassesCompleted {
    return (_currentIntake / 250).floor();
  }

  /// Target number of glasses
  int get targetGlasses {
    return (_dailyGoal / 250).ceil();
  }

  /// Add water intake
  void addWater(int amount) {
    _currentIntake += amount;
    
    // Add to history (convert ml to oz for display)
    final ozAmount = (amount / 29.5735).round(); // 1 oz = ~29.57 ml
    _todayHistory.add(
      WaterEntry(
        timestamp: DateTime.now(),
        amount: ozAmount,
      ),
    );
    
    // Sort history by timestamp (newest first)
    _todayHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
    
    // Show celebration if goal reached
    if (_currentIntake >= _dailyGoal && (_currentIntake - amount) < _dailyGoal) {
      _showGoalAchievedCelebration();
    }
  }

  /// Remove water intake (for corrections)
  void removeWater(int amount) {
    _currentIntake = (_currentIntake - amount).clamp(0, _dailyGoal * 2);
    notifyListeners();
  }

  /// Set daily goal
  void setDailyGoal(int goal) {
    _dailyGoal = goal;
    notifyListeners();
  }

  /// Toggle goal enabled/disabled
  void toggleGoal(bool enabled) {
    _goalEnabled = enabled;
    notifyListeners();
  }

  /// Toggle reminder settings
  void toggleMorningReminder(bool enabled) {
    _morningReminder = enabled;
    notifyListeners();
  }

  void toggleAfternoonReminder(bool enabled) {
    _afternoonReminder = enabled;
    notifyListeners();
  }

  void toggleEveningReminder(bool enabled) {
    _eveningReminder = enabled;
    notifyListeners();
  }

  /// Reset daily progress (called at midnight)
  void resetDaily() {
    _currentIntake = 0;
    _todayHistory.clear();
    notifyListeners();
  }

  /// Get water intake for specific date
  int getIntakeForDate(DateTime date) {
    // TODO: Implement database lookup for historical data
    if (date.day == DateTime.now().day) {
      return _currentIntake;
    }
    // Mock data for other dates
    return (1500 + (date.day * 100)) % _dailyGoal;
  }

  /// Get week progress data for charts
  List<double> getWeekProgress() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final intake = getIntakeForDate(date);
      return (intake / _dailyGoal).clamp(0.0, 1.0);
    });
  }

  /// Get month progress data for charts
  List<double> getMonthProgress() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    return List.generate(daysInMonth, (index) {
      final date = DateTime(now.year, now.month, index + 1);
      if (date.isAfter(now)) return 0.0;
      
      final intake = getIntakeForDate(date);
      return (intake / _dailyGoal).clamp(0.0, 1.0);
    });
  }

  /// Show goal achieved celebration
  void _showGoalAchievedCelebration() {
    // TODO: Implement celebration animation/notification
    debugPrint('🎉 Water goal achieved! Great job staying hydrated!');
  }

  /// Get motivation message based on progress
  String get motivationMessage {
    final progress = progressPercentage;
    
    if (progress >= 1.0) {
      return 'Excellent! You\'ve reached your daily water goal! 💧✨';
    } else if (progress >= 0.8) {
      return 'Almost there! Just a bit more to reach your goal! 💪';
    } else if (progress >= 0.5) {
      return 'Great progress! Keep up the good hydration! 👍';
    } else if (progress >= 0.25) {
      return 'Good start! Remember to drink water throughout the day 💧';
    } else {
      return 'Time to hydrate! Your body needs water to function properly 💙';
    }
  }

  /// Check if user is behind schedule
  bool get isBehindSchedule {
    final now = DateTime.now();
    final expectedProgress = (now.hour * 60 + now.minute) / (24 * 60); // Progress through day
    return progressPercentage < (expectedProgress * 0.8); // Should be at least 80% of expected
  }

  /// Get next reminder time
  DateTime? get nextReminderTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final reminderTimes = <DateTime>[];
    
    if (_morningReminder) {
      reminderTimes.add(today.add(const Duration(hours: 9))); // 9 AM
    }
    if (_afternoonReminder) {
      reminderTimes.add(today.add(const Duration(hours: 14))); // 2 PM
    }
    if (_eveningReminder) {
      reminderTimes.add(today.add(const Duration(hours: 18))); // 6 PM
    }
    
    // Find next reminder after current time
    for (final reminderTime in reminderTimes) {
      if (reminderTime.isAfter(now)) {
        return reminderTime;
      }
    }
    
    // If no reminders today, check tomorrow
    final tomorrow = today.add(const Duration(days: 1));
    if (_morningReminder) {
      return tomorrow.add(const Duration(hours: 9));
    }
    
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
