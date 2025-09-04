import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:intl/intl.dart';

import '../../food_logging/screens/food_logging_screen_with_provider.dart';
import '../providers/home_provider.dart';
import '../models/home_state_model.dart';
import '../widgets/home_shimmer_widgets.dart';

import '../../../presentation/widgets/custom_appbar.dart';
import '../../../core/app_theme.dart';
import '../../../models/recommendation_model.dart';
import '../../../models/food_model.dart';

// Import screens for navigation
import '../../activity/screens/activity_screen_with_provider.dart';

class HomeScreenWithProvider extends StatefulWidget {
  const HomeScreenWithProvider({super.key});

  @override
  State<HomeScreenWithProvider> createState() => _HomeScreenWithProviderState();
}

class _HomeScreenWithProviderState extends State<HomeScreenWithProvider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showNotificationSettings(HomeProvider homeProvider) {
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
              value: homeProvider.notificationsEnabled,
              onChanged: (value) {
                homeProvider.updateNotificationSettings(value);
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
              value: homeProvider.notificationsEnabled,
              onChanged: (value) {
                homeProvider.updateNotificationSettings(value);
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
              value: homeProvider.notificationsEnabled,
              onChanged: (value) {
                homeProvider.updateNotificationSettings(value);
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
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, child) {
        // Show error state if user not authenticated
        if (!homeProvider.homeState.hasUserProfile && homeProvider.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please log in to continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => homeProvider.resetHomeData(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => homeProvider.refreshData(),
            color: AppTheme.primaryGreen,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Custom app bar
                  CustomAppBar(
                    title: 'Nabd Al-Hayah',
                    actions: [
                      IconButton(
                        icon: Icon(
                          homeProvider.notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_outlined,
                          color: homeProvider.notificationsEnabled
                              ? AppTheme.primaryGreen
                              : Colors.white,
                        ),
                        onPressed: () => _showNotificationSettings(homeProvider),
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
                          _buildWelcomeSection(homeProvider),
                          const SizedBox(height: 20),

                          // Today's Overview Cards
                          _buildTodayOverviewSection(homeProvider),
                          const SizedBox(height: 20),

                          // Quick Actions
                          _buildQuickActionsSection(homeProvider),
                          const SizedBox(height: 20),

                          // AI Recommendations
                          _buildAIRecommendationsSection(homeProvider),
                          const SizedBox(height: 20),

                          // Today's Meals
                          _buildTodaysMealsSection(homeProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection(HomeProvider homeProvider) {
    if (homeProvider.isSectionLoading(HomeSection.userProfile)) {
      return HomeShimmerWidgets.welcomeCardShimmer();
    }

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
                      homeProvider.greetingMessage,
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

  Widget _buildTodayOverviewSection(HomeProvider homeProvider) {
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
        
        // Steps and Water cards
        Row(
          children: [
            // Steps Card
            Expanded(
              child: homeProvider.isSectionLoading(HomeSection.activityData)
                  ? HomeShimmerWidgets.overviewCardShimmer()
                  : _buildOverviewCard(
                      'Steps',
                      '${homeProvider.currentSteps}',
                      'of ${homeProvider.stepsGoal}',
                      homeProvider.stepsProgress,
                      Icons.directions_walk,
                      AppTheme.primaryGreen,
                    ),
            ),
            const SizedBox(width: 12),
            
            // Water Card
            Expanded(
              child: homeProvider.isSectionLoading(HomeSection.hydrationData)
                  ? HomeShimmerWidgets.overviewCardShimmer()
                  : _buildOverviewCard(
                      'Water',
                      '${homeProvider.currentWaterIntake.toStringAsFixed(1)}L',
                      'of ${homeProvider.waterGoal.toStringAsFixed(1)}L',
                      homeProvider.waterProgress,
                      Icons.water_drop,
                      AppTheme.waterBlue,
                    ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Calories Card
        homeProvider.isSectionLoading(HomeSection.foodLogData)
            ? HomeShimmerWidgets.fullWidthCardShimmer()
            : _buildFullWidthCard(
                'Calories',
                '${homeProvider.currentCalories.toInt()}',
                'of ${homeProvider.calorieGoal.toInt()} kcal',
                homeProvider.caloriesProgress,
                Icons.local_fire_department,
                AppTheme.stepsOrange,
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

  Widget _buildQuickActionsSection(HomeProvider homeProvider) {
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
        
        homeProvider.isLoading 
            ? HomeShimmerWidgets.quickActionsShimmer()
            : Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Track Activity',
                      Icons.directions_run,
                      AppTheme.primaryGreen,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ActivityScreenWithProvider())),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Log Food',
                      Icons.restaurant_menu,
                      Colors.orange,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLoggingScreenWithProvider())),
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

  Widget _buildAIRecommendationsSection(HomeProvider homeProvider) {
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
        
        if (homeProvider.isSectionLoading(HomeSection.recommendations))
          HomeShimmerWidgets.aiRecommendationsShimmer()
        else if (homeProvider.recommendations.isEmpty)
          _buildEmptyRecommendations()
        else
          Column(
            children: homeProvider.recommendations
                .take(3)
                .map((rec) => _buildRecommendationCard(rec, homeProvider))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyRecommendations() {
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

/* <<<<<<<<<<<<<<  ✨ Windsurf Command 🌟 >>>>>>>>>>>>>>>> */
  /// Builds a recommendation card based on the given [recommendation] and [homeProvider].
  Widget _buildRecommendationCard(RecommendationModel recommendation, HomeProvider homeProvider) {
    /// Gets the color for the given [type].
    Color getTypeColor(RecommendationType type) {
      // Switch on the type to get the corresponding color.
      switch (type) {
        case RecommendationType.nutrition:
          return AppTheme.stepsOrange;
        case RecommendationType.hydration:
          return AppTheme.waterBlue;
        case RecommendationType.activity:
          return AppTheme.primaryGreen;
        case RecommendationType.weight:
          return AppTheme.secondaryGreen;
        case RecommendationType.sleep:
          return AppTheme.waterBlue;
        default:
          // Default to text secondary color if type is not recognized.
          return AppTheme.textSecondary;
      }
    }

    /// Gets the icon for the given [type].
    IconData getTypeIcon(RecommendationType type) {
      // Switch on the type to get the corresponding icon.
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
          // Default to lightbulb icon if type is not recognized.
          return Icons.lightbulb;
      }
    }

    // Get the color and icon for the recommendation type.
    final color = getTypeColor(recommendation.type);
    final icon = getTypeIcon(recommendation.type);

    // Build the recommendation card.
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
              // Build the icon container.
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              // Build the title text.
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
              // If the recommendation has a high priority, add a badge.
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
          // Build the description text.
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          // If the recommendation has an action text, add a button to mark it as read.
          if (recommendation.actionText != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => homeProvider.markRecommendationAsRead(recommendation.id),
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
/* <<<<<<<<<<  be2617f3-9607-42c6-a135-56ebb30b0657  >>>>>>>>>>> */

  Widget _buildTodaysMealsSection(HomeProvider homeProvider) {
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
        
        if (homeProvider.isSectionLoading(HomeSection.foodLogData))
          HomeShimmerWidgets.todaysMealsShimmer()
        else if (homeProvider.foodLogData == null || homeProvider.foodLogData!.meals.isEmpty)
          _buildEmptyMealsState()
        else
          Column(
            children: homeProvider.foodLogData!.meals
                .take(3)
                .map((meal) => _buildMealSummaryCard(meal))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyMealsState() {
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
                MaterialPageRoute(builder: (_) => const FoodLoggingScreenWithProvider()),
              ),
              child: const Text('Log Your First Meal'),
            ),
          ],
        ),
      ),
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
