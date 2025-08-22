import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../widgets/custom_appbar.dart';
import '../../core/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/activity_model.dart';
import '../../models/hydration_model.dart';
import '../../models/food_model.dart';
import '../../models/recommendation_model.dart';
import 'activity_screen.dart';
import 'food_logging_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _notificationsEnabled = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final user = FirebaseAuth.instance.currentUser;
  UserModel? userProfile;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadUserProfile();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserProfile() async {
    if (user != null) {
      try {
        final profile = await FirebaseService.getUserProfile(user!.uid);
        if (mounted) {
          setState(() {
            userProfile = profile;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
      }
    }
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Meal Reminders'),
              subtitle: const Text('Get notified about meal times'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Meal reminders enabled' : 'Meal reminders disabled',
                    ),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Water Reminders'),
              subtitle: const Text('Stay hydrated throughout the day'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Water reminders enabled' : 'Water reminders disabled',
                    ),
                    backgroundColor: AppTheme.accentBlue,
                  ),
                );
              },
            ),
            SwitchListTile(
              title: const Text('Goal Achievements'),
              subtitle: const Text('Celebrate your milestones'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Goal notifications enabled' : 'Goal notifications disabled',
                    ),
                    backgroundColor: AppTheme.accentBlack,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Custom app bar
            CustomAppBar(
              title: 'Nabd Al-Hayah',
              actions: [
                IconButton(
                  icon: Icon(
                    _notificationsEnabled 
                      ? Icons.notifications_active 
                      : Icons.notifications_outlined,
                    color: _notificationsEnabled ? AppTheme.primaryGreen : Colors.white,
                  ),
                  onPressed: _showNotificationSettings,
                ),
              ],
            ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    
                    // Today's Overview Cards
                    _buildTodayOverviewCards(),
                    const SizedBox(height: 20),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    
                    // AI Recommendations
                    _buildAIRecommendations(),
                    const SizedBox(height: 20),
                    
                    // Today's Meals
                    _buildTodaysMeals(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello ${userProfile?.displayName ?? 'there'}!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ready for a healthy day?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayOverviewCards() {
    final today = DateTime.now();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Steps Card
            Expanded(
              child: StreamBuilder<ActivityModel?>(
                stream: FirebaseService.streamActivityData(user!.uid, today),
                builder: (context, snapshot) {
                  final activity = snapshot.data;
                  final steps = activity?.steps ?? 0;
                  const goal = 10000;
                  final progress = (steps / goal).clamp(0.0, 1.0);
                  
                  return _buildOverviewCard(
                    'Steps',
                    '$steps',
                    'of $goal',
                    progress,
                    Icons.directions_walk,
                    AppTheme.primaryGreen,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Water Card
            Expanded(
              child: StreamBuilder<HydrationModel?>(
                stream: FirebaseService.streamHydrationData(user!.uid, today),
                builder: (context, snapshot) {
                  final hydration = snapshot.data;
                  final intake = hydration?.waterIntake ?? 0.0;
                  final goal = hydration?.goalAmount ?? 2.5;
                  final progress = (intake / goal).clamp(0.0, 1.0);
                  
                  return _buildOverviewCard(
                    'Water',
                    '${intake.toStringAsFixed(1)}L',
                    'of ${goal.toStringAsFixed(1)}L',
                    progress,
                    Icons.water_drop,
                    Colors.blue,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Calories Card
        StreamBuilder<FoodLogModel?>(
          stream: FirebaseService.streamFoodLogData(user!.uid, today),
          builder: (context, snapshot) {
            final foodLog = snapshot.data;
            final calories = foodLog?.totalCalories ?? 0.0;
            final goal = (userProfile?.calculatedDailyGoal ?? 2000).toDouble(); // 🎯 Use dynamic goal
            final progress = (calories / goal).clamp(0.0, 1.0);
            
            return _buildFullWidthCard(
              'Calories',
              '${calories.toInt()}',
              'of ${goal.toInt()} kcal',
              progress,
              Icons.local_fire_department,
              Colors.orange,
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    String subtitle,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 4,
            percent: progress,
            backgroundColor: color.withOpacity(0.1),
            progressColor: color,
            barRadius: const Radius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthCard(
    String title,
    String value,
    String subtitle,
    double progress,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 6,
            percent: progress,
            backgroundColor: color.withOpacity(0.1),
            progressColor: color,
            barRadius: const Radius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Track Activity',
                Icons.directions_run,
                AppTheme.primaryGreen,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Log Food',
                Icons.restaurant_menu,
                Colors.orange,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLoggingScreen())),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'AI Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<RecommendationModel>>(
          stream: FirebaseService.streamRecommendations(user!.uid),
          builder: (context, snapshot) {
            final recommendations = snapshot.data ?? [];
            
            if (recommendations.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textLight.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.textLight,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Start logging your activities to get personalized recommendations!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return Column(
              children: recommendations.take(3).map((rec) => _buildRecommendationCard(rec)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(RecommendationModel recommendation) {
    Color getTypeColor(RecommendationType type) {
      switch (type) {
        case RecommendationType.nutrition:
          return Colors.orange;
        case RecommendationType.hydration:
          return Colors.blue;
        case RecommendationType.activity:
          return AppTheme.primaryGreen;
        case RecommendationType.weight:
          return Colors.purple;
        case RecommendationType.sleep:
          return Colors.indigo;
        default:
          return AppTheme.textSecondary;
      }
    }
    
    IconData getTypeIcon(RecommendationType type) {
      switch (type) {
        case RecommendationType.nutrition:
          return Icons.restaurant_menu;
        case RecommendationType.hydration:
          return Icons.water_drop;
        case RecommendationType.activity:
          return Icons.directions_run;
        case RecommendationType.weight:
          return Icons.monitor_weight;
        case RecommendationType.sleep:
          return Icons.bedtime;
        default:
          return Icons.lightbulb;
      }
    }
    
    final color = getTypeColor(recommendation.type);
    final icon = getTypeIcon(recommendation.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (recommendation.priority == 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'High',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (recommendation.actionText != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  FirebaseService.markRecommendationAsRead(user!.uid, recommendation.id);
                },
                child: Text(
                  recommendation.actionText!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodaysMeals() {
    final today = DateTime.now();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Meals',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<FoodLogModel?>(
          stream: FirebaseService.streamFoodLogData(user!.uid, today),
          builder: (context, snapshot) {
            final foodLog = snapshot.data;
            
            if (foodLog == null || foodLog.meals.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.textLight.withOpacity(0.1),
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: 48,
                        color: AppTheme.textLight.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No meals logged today',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const FoodLoggingScreen()),
                        ),
                        child: const Text('Log Your First Meal'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return Column(
              children: foodLog.meals.take(3).map((meal) => _buildMealSummaryCard(meal)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMealSummaryCard(FoodEntry meal) {
    Icon getMealIcon(String mealType) {
      switch (mealType.toLowerCase()) {
        case 'breakfast':
          return Icon(Icons.free_breakfast, color: Colors.orange, size: 24);
        case 'lunch':
          return Icon(Icons.lunch_dining, color: Colors.green, size: 24);
        case 'dinner':
          return Icon(Icons.dinner_dining, color: Colors.red, size: 24);
        case 'snack':
          return Icon(Icons.bakery_dining, color: Colors.purple, size: 24);
        default:
          return Icon(Icons.restaurant_menu, color: AppTheme.primaryGreen, size: 24);
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textLight.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          getMealIcon(meal.mealType),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal.mealType.substring(0, 1).toUpperCase() + meal.mealType.substring(1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '${meal.items.length} item${meal.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${meal.totalCalories.toInt()} kcal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
