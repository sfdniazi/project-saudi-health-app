import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationModel {
  final String id;
  final String userId;
  final RecommendationType type;
  final String title;
  final String description;
  final String? actionText;
  final String? actionRoute;
  final int priority; // 1 = high, 2 = medium, 3 = low
  final bool isRead;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  RecommendationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.actionText,
    this.actionRoute,
    this.priority = 2,
    this.isRead = false,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'actionText': actionText,
      'actionRoute': actionRoute,
      'priority': priority,
      'isRead': isRead,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
  }

  factory RecommendationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RecommendationModel(
      id: documentId,
      userId: map['userId'] ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RecommendationType.general,
      ),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      actionText: map['actionText'],
      actionRoute: map['actionRoute'],
      priority: map['priority']?.toInt() ?? 2,
      isRead: map['isRead'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory RecommendationModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return RecommendationModel.fromMap(data, snapshot.id);
  }

  RecommendationModel copyWith({
    String? id,
    String? userId,
    RecommendationType? type,
    String? title,
    String? description,
    String? actionText,
    String? actionRoute,
    int? priority,
    bool? isRead,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return RecommendationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      actionText: actionText ?? this.actionText,
      actionRoute: actionRoute ?? this.actionRoute,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  String get priorityText {
    switch (priority) {
      case 1:
        return 'High';
      case 2:
        return 'Medium';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case RecommendationType.nutrition:
        return 'Nutrition';
      case RecommendationType.hydration:
        return 'Hydration';
      case RecommendationType.activity:
        return 'Activity';
      case RecommendationType.sleep:
        return 'Sleep';
      case RecommendationType.weight:
        return 'Weight';
      case RecommendationType.general:
        return 'General';
    }
  }
}

enum RecommendationType {
  nutrition,
  hydration,
  activity,
  sleep,
  weight,
  general,
}

class RecommendationGenerator {
  static List<RecommendationModel> generateRecommendations({
    required String userId,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? nutritionData,
    Map<String, dynamic>? hydrationData,
  }) {
    final List<RecommendationModel> recommendations = [];
    final now = DateTime.now();

    // Extract user data
    final weight = userData['weight']?.toDouble() ?? 70.0;
    final height = userData['height']?.toDouble() ?? 170.0;
    // final age = userData['age']?.toInt() ?? 25; // Not used currently, but could be used for age-specific recommendations
    final dailyGoal = userData['dailyGoal']?.toInt() ?? 2000;

    // Calculate BMI
    final bmi = weight / ((height / 100) * (height / 100));

    // BMI-based recommendations
    if (bmi < 18.5) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Consider Increasing Calorie Intake',
        description: 'Your BMI suggests you might be underweight. Consider adding healthy, calorie-dense foods to your meals.',
        actionText: 'View Nutrition Tips',
        priority: 1,
        createdAt: now,
      ));
    } else if (bmi > 25) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Focus on Balanced Nutrition',
        description: 'Your BMI suggests maintaining a balanced diet with proper portion control could be beneficial.',
        actionText: 'Create Meal Plan',
        priority: 1,
        createdAt: now,
      ));
    }

    // Activity-based recommendations
    if (activityData != null) {
      final steps = activityData['steps']?.toInt() ?? 0;
      if (steps < 8000) {
        recommendations.add(RecommendationModel(
          id: '',
          userId: userId,
          type: RecommendationType.activity,
          title: 'Increase Daily Steps',
          description: 'Try to reach 8,000-10,000 steps daily for better health. Consider taking walks or using stairs.',
          actionText: 'Track Activity',
          priority: 2,
          createdAt: now,
        ));
      }
    }

    // Hydration-based recommendations
    if (hydrationData != null) {
      final waterIntake = hydrationData['waterIntake']?.toDouble() ?? 0.0;
      if (waterIntake < 2.0) {
        recommendations.add(RecommendationModel(
          id: '',
          userId: userId,
          type: RecommendationType.hydration,
          title: 'Stay Hydrated',
          description: 'Aim to drink at least 2.5L of water daily. Proper hydration supports metabolism and overall health.',
          actionText: 'Log Water Intake',
          priority: 2,
          createdAt: now,
        ));
      }
    }

    // Nutrition-based recommendations
    if (nutritionData != null) {
      final totalCalories = nutritionData['totalCalories']?.toDouble() ?? 0.0;
      if (totalCalories < dailyGoal * 0.8) {
        recommendations.add(RecommendationModel(
          id: '',
          userId: userId,
          type: RecommendationType.nutrition,
          title: 'Meet Your Calorie Goals',
          description: 'You\'re consuming fewer calories than your daily goal. Make sure you\'re eating enough to fuel your body.',
          actionText: 'Log More Food',
          priority: 2,
          createdAt: now,
        ));
      } else if (totalCalories > dailyGoal * 1.2) {
        recommendations.add(RecommendationModel(
          id: '',
          userId: userId,
          type: RecommendationType.nutrition,
          title: 'Monitor Portion Sizes',
          description: 'You\'re consuming more calories than your daily goal. Consider monitoring portion sizes.',
          actionText: 'Review Food Log',
          priority: 2,
          createdAt: now,
        ));
      }
    }

    // General health recommendations
    recommendations.add(RecommendationModel(
      id: '',
      userId: userId,
      type: RecommendationType.general,
      title: 'Complete Your Health Profile',
      description: 'Make sure all your health information is up to date for better personalized recommendations.',
      actionText: 'Update Profile',
      priority: 3,
      createdAt: now,
    ));

    return recommendations;
  }
}
