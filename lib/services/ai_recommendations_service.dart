import 'dart:math';
import '../models/recommendation_model.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../models/hydration_model.dart';
import '../models/food_model.dart';
import 'firebase_service.dart';

class AIRecommendationsService {
  static final Random _random = Random();

  /// Generate comprehensive AI recommendations based on user data
  static Future<List<RecommendationModel>> generateSmartRecommendations({
    required String userId,
    required UserModel userProfile,
    ActivityModel? todayActivity,
    HydrationModel? todayHydration,
    FoodLogModel? todayFoodLog,
    List<ActivityModel>? weeklyActivity,
  }) async {
    final List<RecommendationModel> recommendations = [];
    final now = DateTime.now();

    try {
      // Analyze user profile and generate BMI-based recommendations
      final bmiRecommendations = _generateBMIRecommendations(userId, userProfile, now);
      recommendations.addAll(bmiRecommendations);

      // Analyze activity patterns
      if (todayActivity != null) {
        final activityRecs = _generateActivityRecommendations(userId, userProfile, todayActivity, now);
        recommendations.addAll(activityRecs);
      }

      // Analyze hydration patterns
      if (todayHydration != null) {
        final hydrationRecs = _generateHydrationRecommendations(userId, todayHydration, now);
        recommendations.addAll(hydrationRecs);
      }

      // Analyze nutrition patterns
      if (todayFoodLog != null) {
        final nutritionRecs = _generateNutritionRecommendations(userId, userProfile, todayFoodLog, now);
        recommendations.addAll(nutritionRecs);
      }

      // Generate weekly pattern recommendations
      if (weeklyActivity != null && weeklyActivity.isNotEmpty) {
        final weeklyRecs = _generateWeeklyPatternRecommendations(userId, weeklyActivity, now);
        recommendations.addAll(weeklyRecs);
      }

      // Generate motivational recommendations
      final motivationalRecs = _generateMotivationalRecommendations(userId, now);
      recommendations.addAll(motivationalRecs);

      // Sort recommendations by priority
      recommendations.sort((a, b) => a.priority.compareTo(b.priority));

      // Limit to top 10 recommendations to avoid overwhelming the user
      return recommendations.take(10).toList();
    } catch (e) {
      print('Error generating AI recommendations: $e');
      return _generateFallbackRecommendations(userId, now);
    }
  }

  /// Generate BMI-based health recommendations
  static List<RecommendationModel> _generateBMIRecommendations(
    String userId,
    UserModel userProfile,
    DateTime now,
  ) {
    final recommendations = <RecommendationModel>[];
    final bmi = userProfile.bmi;

    if (bmi < 18.5) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Focus on Healthy Weight Gain',
        description: 'Your BMI (${bmi.toStringAsFixed(1)}) suggests you might benefit from gaining weight. Consider adding nutrient-dense, calorie-rich foods to your meals.',
        actionText: 'View Nutrition Tips',
        priority: 1,
        createdAt: now,
        metadata: {'bmi': bmi, 'category': 'underweight'},
      ));

      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Add Healthy Fats to Your Diet',
        description: 'Include nuts, avocados, olive oil, and fatty fish in your meals to increase healthy calorie intake.',
        actionText: 'Log More Food',
        priority: 2,
        createdAt: now,
      ));
    } else if (bmi > 25 && bmi <= 30) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Consider Portion Control',
        description: 'Your BMI (${bmi.toStringAsFixed(1)}) suggests you might benefit from watching portion sizes and choosing nutrient-dense foods.',
        actionText: 'Plan Meals',
        priority: 1,
        createdAt: now,
        metadata: {'bmi': bmi, 'category': 'overweight'},
      ));

      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Increase Physical Activity',
        description: 'Adding 30 minutes of moderate exercise daily can help with weight management and overall health.',
        actionText: 'Track Activity',
        priority: 2,
        createdAt: now,
      ));
    } else if (bmi > 30) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.weight,
        title: 'Consider Professional Guidance',
        description: 'Your BMI (${bmi.toStringAsFixed(1)}) suggests consulting with a healthcare provider for personalized weight management advice.',
        actionText: 'Learn More',
        priority: 1,
        createdAt: now,
        metadata: {'bmi': bmi, 'category': 'obese'},
      ));
    }

    return recommendations;
  }

  /// Generate activity-based recommendations
  static List<RecommendationModel> _generateActivityRecommendations(
    String userId,
    UserModel userProfile,
    ActivityModel todayActivity,
    DateTime now,
  ) {
    final recommendations = <RecommendationModel>[];
    final steps = todayActivity.steps;
    const targetSteps = 10000;

    if (steps < 5000) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Time to Get Moving!',
        description: 'You\'ve taken ${steps} steps today. Try to reach at least 8,000 steps for better health benefits.',
        actionText: 'Start Walking',
        priority: 1,
        createdAt: now,
      ));
    } else if (steps < 8000) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'You\'re Making Progress!',
        description: 'Great job on ${steps} steps! Just ${8000 - steps} more steps to reach a healthy daily goal.',
        actionText: 'Keep Going',
        priority: 2,
        createdAt: now,
      ));
    } else if (steps >= targetSteps) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Excellent Activity Level!',
        description: 'Amazing! You\'ve reached ${steps} steps today. You\'re maintaining excellent activity levels.',
        actionText: 'View Progress',
        priority: 3,
        createdAt: now,
      ));
    }

    // Calorie burn recommendations
    if (todayActivity.calories < 200) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Boost Your Calorie Burn',
        description: 'Consider adding some cardio exercises or increasing the intensity of your activities to burn more calories.',
        actionText: 'See Exercises',
        priority: 2,
        createdAt: now,
      ));
    }

    return recommendations;
  }

  /// Generate hydration recommendations
  static List<RecommendationModel> _generateHydrationRecommendations(
    String userId,
    HydrationModel todayHydration,
    DateTime now,
  ) {
    final recommendations = <RecommendationModel>[];
    final intake = todayHydration.waterIntake;
    final goal = todayHydration.goalAmount;
    final progress = todayHydration.progressPercentage;

    if (progress < 30) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.hydration,
        title: 'Drink More Water!',
        description: 'You\'ve only had ${intake.toStringAsFixed(1)}L of water today. Aim for ${goal.toStringAsFixed(1)}L to stay properly hydrated.',
        actionText: 'Log Water',
        priority: 1,
        createdAt: now,
      ));
    } else if (progress < 70) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.hydration,
        title: 'Keep Up the Hydration',
        description: 'You\'re ${progress.toInt()}% towards your hydration goal. Keep sipping throughout the day!',
        actionText: 'Add Water',
        priority: 2,
        createdAt: now,
      ));
    } else if (progress >= 100) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.hydration,
        title: 'Hydration Goal Achieved!',
        description: 'Excellent! You\'ve met your daily hydration goal. Your body will thank you for it.',
        actionText: 'Celebrate',
        priority: 3,
        createdAt: now,
      ));
    }

    // Time-based hydration reminders
    final hour = now.hour;
    if (hour >= 14 && hour <= 16 && progress < 50) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.hydration,
        title: 'Afternoon Hydration Boost',
        description: 'It\'s afternoon and you\'re behind on your water intake. This is a great time to catch up!',
        actionText: 'Drink Water',
        priority: 1,
        createdAt: now,
      ));
    }

    return recommendations;
  }

  /// Generate nutrition recommendations
  static List<RecommendationModel> _generateNutritionRecommendations(
    String userId,
    UserModel userProfile,
    FoodLogModel todayFoodLog,
    DateTime now,
  ) {
    final recommendations = <RecommendationModel>[];
    final calories = todayFoodLog.totalCalories;
    final protein = todayFoodLog.totalProtein;
    final dailyGoal = userProfile.dailyGoal;

    // Calorie recommendations
    if (calories < dailyGoal * 0.6) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Fuel Your Body',
        description: 'You\'ve only consumed ${calories.toInt()} calories today. Make sure to eat enough to meet your daily needs.',
        actionText: 'Add Meal',
        priority: 1,
        createdAt: now,
      ));
    } else if (calories > dailyGoal * 1.3) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Monitor Your Intake',
        description: 'You\'ve consumed ${calories.toInt()} calories today, which is above your goal. Consider lighter options for remaining meals.',
        actionText: 'Review Meals',
        priority: 2,
        createdAt: now,
      ));
    }

    // Protein recommendations
    final recommendedProtein = userProfile.weight * 0.8; // 0.8g per kg body weight
    if (protein < recommendedProtein * 0.7) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Add More Protein',
        description: 'You\'ve had ${protein.toInt()}g of protein today. Try to include more protein-rich foods in your meals.',
        actionText: 'Find Protein Foods',
        priority: 2,
        createdAt: now,
      ));
    }

    // Meal balance recommendations
    final mealCount = todayFoodLog.meals.length;
    if (mealCount < 3) {
      recommendations.add(RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Don\'t Skip Meals',
        description: 'You\'ve only logged ${mealCount} meal${mealCount == 1 ? '' : 's'} today. Regular meals help maintain energy and metabolism.',
        actionText: 'Plan Meals',
        priority: 2,
        createdAt: now,
      ));
    }

    return recommendations;
  }

  /// Generate weekly pattern recommendations
  static List<RecommendationModel> _generateWeeklyPatternRecommendations(
    String userId,
    List<ActivityModel> weeklyActivity,
    DateTime now,
  ) {
    final recommendations = <RecommendationModel>[];
    
    if (weeklyActivity.length >= 3) {
      final avgSteps = weeklyActivity.map((a) => a.steps).reduce((a, b) => a + b) / weeklyActivity.length;
      
      if (avgSteps < 6000) {
        recommendations.add(RecommendationModel(
          id: '',
          userId: userId,
          type: RecommendationType.activity,
          title: 'Weekly Activity Review',
          description: 'Your average daily steps this week is ${avgSteps.toInt()}. Let\'s aim for gradual improvement!',
          actionText: 'Set Weekly Goals',
          priority: 2,
          createdAt: now,
        ));
      }
    }

    return recommendations;
  }

  /// Generate motivational recommendations
  static List<RecommendationModel> _generateMotivationalRecommendations(
    String userId,
    DateTime now,
  ) {
    final motivationalMessages = [
      {
        'title': 'Stay Consistent',
        'description': 'Small, consistent actions lead to big results. Keep tracking your health journey!',
      },
      {
        'title': 'Celebrate Small Wins',
        'description': 'Every healthy choice you make today is an investment in your future well-being.',
      },
      {
        'title': 'Listen to Your Body',
        'description': 'Pay attention to how different foods and activities make you feel. Your body knows best!',
      },
      {
        'title': 'Stay Hydrated',
        'description': 'Remember, even mild dehydration can affect your energy and mood. Keep that water bottle close!',
      },
      {
        'title': 'Quality Sleep Matters',
        'description': 'Good nutrition and exercise are important, but don\'t forget the power of quality sleep for recovery.',
      },
    ];

    final selectedMessage = motivationalMessages[_random.nextInt(motivationalMessages.length)];

    return [
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.general,
        title: selectedMessage['title']!,
        description: selectedMessage['description']!,
        priority: 3,
        createdAt: now,
      ),
    ];
  }

  /// Generate fallback recommendations when data analysis fails
  static List<RecommendationModel> _generateFallbackRecommendations(
    String userId,
    DateTime now,
  ) {
    return [
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.general,
        title: 'Start Your Health Journey',
        description: 'Begin by tracking your daily activities, water intake, and meals to get personalized recommendations.',
        actionText: 'Get Started',
        priority: 2,
        createdAt: now,
      ),
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Move More Today',
        description: 'Try to take at least 8,000 steps today. Every step counts towards better health!',
        actionText: 'Track Steps',
        priority: 2,
        createdAt: now,
      ),
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.hydration,
        title: 'Stay Hydrated',
        description: 'Aim to drink at least 2.5L of water throughout the day for optimal hydration.',
        actionText: 'Log Water',
        priority: 2,
        createdAt: now,
      ),
    ];
  }

  /// Update existing recommendations based on new data
  static Future<void> updateRecommendationsForUser(String userId) async {
    try {
      // Get user data
      final userProfile = await FirebaseService.getUserProfile(userId);
      if (userProfile == null) return;

      final today = DateTime.now();
      final weekAgo = today.subtract(const Duration(days: 7));

      // Get activity data
      final todayActivity = await FirebaseService.getActivityData(userId, today);
      final weeklyActivity = await FirebaseService.getActivityRange(userId, weekAgo, today);
      
      // Get hydration data
      final todayHydration = await FirebaseService.getHydrationData(userId, today);
      
      // Get food log data
      final todayFoodLog = await FirebaseService.getFoodLogData(userId, today);

      // Generate new recommendations
      final newRecommendations = await generateSmartRecommendations(
        userId: userId,
        userProfile: userProfile,
        todayActivity: todayActivity,
        todayHydration: todayHydration,
        todayFoodLog: todayFoodLog,
        weeklyActivity: weeklyActivity,
      );

      // Save new recommendations
      for (final recommendation in newRecommendations) {
        await FirebaseService.saveRecommendation(recommendation);
      }
    } catch (e) {
      print('Error updating recommendations: $e');
    }
  }

  /// Generate recommendations based on specific goals
  static List<RecommendationModel> generateGoalBasedRecommendations({
    required String userId,
    required String goal, // 'weight_loss', 'muscle_gain', 'maintenance', 'health_improvement'
    required UserModel userProfile,
    required DateTime now,
  }) {
    final recommendations = <RecommendationModel>[];

    switch (goal.toLowerCase()) {
      case 'weight_loss':
        recommendations.addAll(_generateWeightLossRecommendations(userId, userProfile, now));
        break;
      case 'muscle_gain':
        recommendations.addAll(_generateMuscleGainRecommendations(userId, userProfile, now));
        break;
      case 'health_improvement':
        recommendations.addAll(_generateHealthImprovementRecommendations(userId, userProfile, now));
        break;
      default:
        recommendations.addAll(_generateMaintenanceRecommendations(userId, userProfile, now));
    }

    return recommendations;
  }

  static List<RecommendationModel> _generateWeightLossRecommendations(
    String userId,
    UserModel userProfile,
    DateTime now,
  ) {
    return [
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Create a Caloric Deficit',
        description: 'Aim to consume 300-500 calories less than your daily goal while maintaining proper nutrition.',
        actionText: 'Adjust Goal',
        priority: 1,
        createdAt: now,
      ),
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Increase Cardio Activity',
        description: 'Add 30 minutes of moderate cardio exercise to your routine most days of the week.',
        actionText: 'Plan Workouts',
        priority: 1,
        createdAt: now,
      ),
    ];
  }

  static List<RecommendationModel> _generateMuscleGainRecommendations(
    String userId,
    UserModel userProfile,
    DateTime now,
  ) {
    return [
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Increase Protein Intake',
        description: 'Aim for ${(userProfile.weight * 1.6).toInt()}g of protein daily to support muscle growth.',
        actionText: 'Track Protein',
        priority: 1,
        createdAt: now,
      ),
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Focus on Strength Training',
        description: 'Include resistance training exercises at least 3-4 times per week.',
        actionText: 'Plan Strength Workouts',
        priority: 1,
        createdAt: now,
      ),
    ];
  }

  static List<RecommendationModel> _generateHealthImprovementRecommendations(
    String userId,
    UserModel userProfile,
    DateTime now,
  ) {
    return [
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.nutrition,
        title: 'Eat More Whole Foods',
        description: 'Focus on fruits, vegetables, whole grains, and lean proteins for optimal nutrition.',
        actionText: 'Plan Healthy Meals',
        priority: 1,
        createdAt: now,
      ),
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.activity,
        title: 'Mix Up Your Activities',
        description: 'Combine cardio, strength training, and flexibility exercises for well-rounded fitness.',
        actionText: 'Explore Activities',
        priority: 2,
        createdAt: now,
      ),
    ];
  }

  static List<RecommendationModel> _generateMaintenanceRecommendations(
    String userId,
    UserModel userProfile,
    DateTime now,
  ) {
    return [
      RecommendationModel(
        id: '',
        userId: userId,
        type: RecommendationType.general,
        title: 'Maintain Your Progress',
        description: 'Keep up your current healthy habits and make small adjustments as needed.',
        actionText: 'Review Progress',
        priority: 2,
        createdAt: now,
      ),
    ];
  }
}
