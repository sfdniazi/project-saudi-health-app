import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// 📋 Daily task data model
class DailyTask {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  bool isCompleted;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isCompleted = false,
  });

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    bool? isCompleted,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 📋 Daily tasks provider managing tasks state and completion
class DailyTasksProvider extends ChangeNotifier {
  // Main tasks (2x2 grid)
  List<DailyTask> _mainTasks = [
    DailyTask(
      id: 'water',
      title: 'Drink Water',
      description: 'Stay hydrated throughout the day',
      icon: Icons.water_drop,
      color: AppTheme.nabdBlue,
    ),
    DailyTask(
      id: 'exercise',
      title: 'Exercise',
      description: 'Get your body moving',
      icon: Icons.fitness_center,
      color: AppTheme.nabdOrange,
    ),
    DailyTask(
      id: 'nutrition',
      title: 'Balanced Meals',
      description: 'Eat healthy and nutritious food',
      icon: Icons.restaurant,
      color: AppTheme.nabdGreen,
    ),
    DailyTask(
      id: 'sleep',
      title: 'Quality Sleep',
      description: 'Get enough rest tonight',
      icon: Icons.bed,
      color: AppTheme.nabdPurple,
    ),
  ];

  // Additional tasks (list format)
  List<DailyTask> _additionalTasks = [
    DailyTask(
      id: 'meditation',
      title: 'Meditation',
      description: '10 minutes of mindfulness',
      icon: Icons.self_improvement,
      color: AppTheme.nabdPurple,
    ),
    DailyTask(
      id: 'vitamins',
      title: 'Take Vitamins',
      description: 'Daily supplement routine',
      icon: Icons.medical_services,
      color: AppTheme.nabdGreen,
    ),
    DailyTask(
      id: 'walk',
      title: 'Walk Outside',
      description: 'Fresh air and sunlight',
      icon: Icons.directions_walk,
      color: AppTheme.nabdOrange,
    ),
    DailyTask(
      id: 'journal',
      title: 'Journal Writing',
      description: 'Reflect on your day',
      icon: Icons.edit,
      color: AppTheme.nabdBlue,
    ),
  ];

  // Getters
  List<DailyTask> get mainTasks => List.unmodifiable(_mainTasks);
  List<DailyTask> get additionalTasks => List.unmodifiable(_additionalTasks);
  
  List<DailyTask> get allTasks => [..._mainTasks, ..._additionalTasks];
  
  int get totalTasksCount => allTasks.length;
  int get completedTasksCount => allTasks.where((task) => task.isCompleted).length;
  
  double get completionProgress {
    if (totalTasksCount == 0) return 0.0;
    return completedTasksCount / totalTasksCount;
  }

  /// 🏆 Achievements based on task completion
  bool get nutritionAchievement {
    return _mainTasks.firstWhere((task) => task.id == 'nutrition').isCompleted &&
           _additionalTasks.firstWhere((task) => task.id == 'vitamins').isCompleted;
  }

  bool get hydrationAchievement {
    return _mainTasks.firstWhere((task) => task.id == 'water').isCompleted;
  }

  /// 💬 Motivational messages based on progress
  String get motivationMessage {
    final progress = completionProgress;
    
    if (progress >= 1.0) {
      return '🎉 Awesome! You\'ve completed all your daily tasks!';
    } else if (progress >= 0.7) {
      return '💪 Great job! You\'re almost there!';
    } else if (progress >= 0.5) {
      return '🚀 You\'re doing well! Keep it up!';
    } else if (progress >= 0.3) {
      return '👍 Good start! Stay consistent!';
    } else {
      return '✨ Take it one step at a time!';
    }
  }

  /// ✅ Toggle task completion status
  void toggleTask(String taskId) {
    // Find in main tasks
    final mainTaskIndex = _mainTasks.indexWhere((task) => task.id == taskId);
    if (mainTaskIndex != -1) {
      _mainTasks[mainTaskIndex].isCompleted = !_mainTasks[mainTaskIndex].isCompleted;
      notifyListeners();
      return;
    }

    // Find in additional tasks
    final additionalTaskIndex = _additionalTasks.indexWhere((task) => task.id == taskId);
    if (additionalTaskIndex != -1) {
      _additionalTasks[additionalTaskIndex].isCompleted = !_additionalTasks[additionalTaskIndex].isCompleted;
      notifyListeners();
      return;
    }
  }

  /// ✅ Mark task as completed
  void completeTask(String taskId) {
    _setTaskCompletion(taskId, true);
  }

  /// ❌ Mark task as incomplete
  void incompleteTask(String taskId) {
    _setTaskCompletion(taskId, false);
  }

  /// 🔄 Reset all tasks (for testing or new day)
  void resetAllTasks() {
    for (var task in _mainTasks) {
      task.isCompleted = false;
    }
    for (var task in _additionalTasks) {
      task.isCompleted = false;
    }
    notifyListeners();
  }

  /// ✅ Complete all tasks (for testing)
  void completeAllTasks() {
    for (var task in _mainTasks) {
      task.isCompleted = true;
    }
    for (var task in _additionalTasks) {
      task.isCompleted = true;
    }
    notifyListeners();
  }

  /// 🎯 Set specific task completion state
  void _setTaskCompletion(String taskId, bool completed) {
    // Find in main tasks
    final mainTaskIndex = _mainTasks.indexWhere((task) => task.id == taskId);
    if (mainTaskIndex != -1) {
      _mainTasks[mainTaskIndex].isCompleted = completed;
      notifyListeners();
      return;
    }

    // Find in additional tasks
    final additionalTaskIndex = _additionalTasks.indexWhere((task) => task.id == taskId);
    if (additionalTaskIndex != -1) {
      _additionalTasks[additionalTaskIndex].isCompleted = completed;
      notifyListeners();
      return;
    }
  }

  /// 📊 Get completion stats
  Map<String, dynamic> getCompletionStats() {
    return {
      'total': totalTasksCount,
      'completed': completedTasksCount,
      'remaining': totalTasksCount - completedTasksCount,
      'progress': completionProgress,
      'percentage': (completionProgress * 100).round(),
    };
  }

  /// 🏆 Get achievements summary
  Map<String, bool> getAchievements() {
    return {
      'nutrition': nutritionAchievement,
      'hydration': hydrationAchievement,
      'exercise': _mainTasks.firstWhere((task) => task.id == 'exercise').isCompleted,
      'sleep': _mainTasks.firstWhere((task) => task.id == 'sleep').isCompleted,
      'mindfulness': _additionalTasks.firstWhere((task) => task.id == 'meditation').isCompleted,
    };
  }
}
