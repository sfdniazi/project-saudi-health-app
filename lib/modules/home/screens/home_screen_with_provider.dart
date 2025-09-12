import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';

import '../../food_logging/screens/food_logging_screen_with_provider.dart';
import '../providers/home_provider.dart';
import '../models/home_state_model.dart';
import '../widgets/home_shimmer_widgets.dart';

import '../../../core/app_theme.dart';
import '../../../presentation/design_system/components/nabd_card.dart';
import '../../../presentation/design_system/components/progress_ring.dart';
import '../../../presentation/design_system/components/mood_picker.dart';
import '../../water_tracking/screens/water_tracking_screen.dart';
import '../../../models/recommendation_model.dart';
import '../../../models/food_model.dart';

// Import screens for navigation
import '../../activity/screens/activity_screen_with_provider.dart';
import '../../ai_recommendations/screens/ai_recommendations_screen_with_provider.dart';
import '../../daily_tasks/screens/daily_tasks_screen.dart';

class HomeScreenWithProvider extends StatefulWidget {
  const HomeScreenWithProvider({super.key});

  @override
  State<HomeScreenWithProvider> createState() => _HomeScreenWithProviderState();
}

class _HomeScreenWithProviderState extends State<HomeScreenWithProvider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime _calendarFocusDate = DateTime.now();

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
                  // Header row (avatar, greeting, actions) - replaces gradient app bar
                  SafeArea(bottom: false, child: _buildGreetingHeaderRow(homeProvider)),

                  // Main content - Beautiful new design
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.spaceLg),
                          
                          // Mood tracking section
                          _buildMoodSection(homeProvider),
                          const SizedBox(height: AppTheme.spaceXl),
                          
                          // Insight banner (like "daily tip")
                          _buildInsightBanner(),
                          const SizedBox(height: AppTheme.spaceXl),
                          
                          // Today's status section
                          _buildTodaysStatus(homeProvider),
                          const SizedBox(height: AppTheme.spaceXl),
                          
                          // Activity overview (matching sleep analysis card)
                          _buildActivityOverview(homeProvider),
                          const SizedBox(height: AppTheme.spaceXl),
                          
                          // Daily tasks section
                          _buildDailyTasks(homeProvider),
                          const SizedBox(height: AppTheme.spaceXl),
                          
                          // AI Recommendations section
                          _buildAIRecommendationsPreview(homeProvider),
                          const SizedBox(height: 100), // Extra padding for bottom nav
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

  /// 🎨 Beautiful header matching the reference design
  Widget _buildGreetingHeaderRow(HomeProvider homeProvider) {
    final displayName = (homeProvider.userProfile?.displayName ?? 'User').trim();
    final firstName = displayName.split(' ').first;
    
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spaceLg, 
        AppTheme.spaceLg, 
        AppTheme.spaceLg, 
        AppTheme.spaceSm
      ),
      child: Row(
        children: [
          // Beautiful circular avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.nabdBlue, AppTheme.nabdPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.nabdBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.person, 
              color: Colors.white, 
              size: 24
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          
          // Welcome text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSizeMd,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  firstName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontSizeXxl,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Notification bell
          _buildNotificationButton(homeProvider),
        ],
      ),
    );
  }
  
  /// 🔔 Notification bell button
  Widget _buildNotificationButton(HomeProvider homeProvider) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.borderColor,
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showNotificationSettings(homeProvider),
          child: Icon(
            homeProvider.notificationsEnabled
                ? Icons.notifications
                : Icons.notifications_none,
            color: AppTheme.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton(IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Icon(icon, color: AppTheme.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard(HomeProvider homeProvider) {
    final avgProgress = ((homeProvider.stepsProgress + homeProvider.waterProgress + homeProvider.caloriesProgress) / 3.0)
        .clamp(0.0, 1.0);
    final days = (avgProgress * 7).round().clamp(0, 7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.highlightBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Small label
                Row(
                  children: [
                    Icon(Icons.bolt_outlined, size: 16, color: AppTheme.textSecondary),
                    SizedBox(width: 6),
                    Text('Daily intake', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Your Weekly\nProgress',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                CircularPercentIndicator(
                  radius: 48,
                  lineWidth: 10,
                  percent: avgProgress,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.white.withOpacity(0.7),
                  progressColor: AppTheme.primaryGreen,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$days', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                      const Text('days', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoStatTiles(HomeProvider homeProvider) {
    return Row(
      children: [
        Expanded(
          child: homeProvider.isSectionLoading(HomeSection.activityData)
              ? HomeShimmerWidgets.overviewCardShimmer()
              : _buildOverviewCard(
                  'Step to\nwalk',
                  '${homeProvider.currentSteps}',
                  'steps',
                  homeProvider.stepsProgress,
                  Icons.directions_walk,
                  AppTheme.primaryGreen,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: homeProvider.isSectionLoading(HomeSection.hydrationData)
              ? HomeShimmerWidgets.overviewCardShimmer()
              : _buildOverviewCard(
                  'Drink\nWater',
                  '${homeProvider.currentWaterIntake.toStringAsFixed(0)}',
                  'glass',
                  homeProvider.waterProgress,
                  Icons.water_drop,
                  AppTheme.waterBlue,
                ),
        ),
      ],
    );
  }

  Widget _buildCalendarStrip() {
    String monthLabel(DateTime d) => DateFormat('MMMM yyyy').format(d);
    final now = DateTime.now();
    final int weekday = _calendarFocusDate.weekday % 7; // Sunday=0
    final start = _calendarFocusDate.subtract(Duration(days: weekday));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.textLight.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(monthLabel(_calendarFocusDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const Spacer(),
              _buildRoundIconButton(Icons.chevron_left, onTap: () => setState(() => _calendarFocusDate = _calendarFocusDate.subtract(const Duration(days: 7)))),
              const SizedBox(width: 8),
              _buildRoundIconButton(Icons.chevron_right, onTap: () => setState(() => _calendarFocusDate = _calendarFocusDate.add(const Duration(days: 7)))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((d) {
              final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
              final label = DateFormat('E').format(d).substring(0, 1); // first letter
              return Column(
                children: [
                  Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.primaryGreen.withOpacity(0.3) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${d.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsShortList(HomeProvider homeProvider) {
    Widget mealRow(String title, int kcal, {VoidCallback? onAdd}) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.textLight.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.stepsOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department, color: AppTheme.stepsOrange, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('$kcal kcal', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            _buildRoundIconButton(Icons.add, onTap: onAdd),
          ],
        ),
      );
    }

    int caloriesFor(String mealType) {
      final meals = homeProvider.foodLogData?.meals ?? [];
      final found = meals.where((m) => m.mealType.toLowerCase() == mealType).toList();
      if (found.isEmpty) return 0;
      return found.first.totalCalories.toInt();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mealRow('Breakfast', caloriesFor('breakfast'), onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLoggingScreenWithProvider()))),
        mealRow('Lunch time', caloriesFor('lunch'), onAdd: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodLoggingScreenWithProvider()))),
      ],
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
                      AppTheme.stepsOrange,
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AIRecommendationsScreenWithProvider(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Get AI-Powered Recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap here for personalized food and exercise suggestions',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(RecommendationModel recommendation, HomeProvider homeProvider) {
    Color getTypeColor(RecommendationType type) {
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
          return Icon(Icons.free_breakfast, color: AppTheme.stepsOrange, size: 24);
        case 'lunch':
          return Icon(Icons.lunch_dining, color: Colors.green, size: 24);
        case 'dinner':
          return Icon(Icons.dinner_dining, color: Colors.red, size: 24);
        case 'snack':
          return Icon(Icons.bakery_dining, color: AppTheme.secondaryGreen, size: 24);
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
  
  /// 😊 Beautiful mood tracking section
  Widget _buildMoodSection(HomeProvider homeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: NabdCard.section(
        child: MoodPicker(
          title: 'How are you feeling about your health today?',
          selectedMood: null, // TODO: Connect to mood state
          onMoodSelected: (mood) {
            // TODO: Handle mood selection
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Feeling ${mood.label.toLowerCase()}'),
                backgroundColor: mood.color,
              ),
            );
          },
        ),
      ),
    );
  }
  
  /// 💡 Insight banner (daily tip)
  Widget _buildInsightBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: NabdCard(
        backgroundColor: AppTheme.nabdYellow.withOpacity(0.1),
        hasBorder: true,
        padding: const EdgeInsets.all(AppTheme.spaceXl),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.nabdYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lightbulb_outline,
                color: AppTheme.nabdYellow.withOpacity(0.8),
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insight',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    'Stay hydrated! Drinking water before meals can help with portion control.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.close,
                color: AppTheme.textTertiary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 📊 Today's status section (Food & Water)
  Widget _buildTodaysStatus(HomeProvider homeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            'Today\'s status',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: AppTheme.fontSizeXl,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Row(
          children: [
            // Food card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spaceLg, right: AppTheme.spaceSm),
                child: _buildStatusCard(
                  title: 'Food',
                  value: '1185 of 2400 cals consumed',
                  progress: homeProvider.caloriesProgress,
                  color: AppTheme.nabdGreen,
                  icon: Icons.restaurant,
                ),
              ),
            ),
            
            // Water card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spaceSm, right: AppTheme.spaceLg),
                child: _buildStatusCard(
                  title: 'Water',
                  value: 'You drank 4 out of 6 glasses of water',
                  progress: homeProvider.waterProgress,
                  color: AppTheme.nabdBlue,
                  icon: Icons.water_drop,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WaterTrackingScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// 📊 Status card helper
  Widget _buildStatusCard({
    required String title,
    required String value,
    required double progress,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final percentage = (progress * 100).round();
    
    return NabdCard.stat(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 14,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Progress ring
          Center(
            child: ProgressRing.goal(
              progress: progress,
              title: '$percentage%',
              color: color,
              onTap: () {
                // TODO: Navigate to detailed view
              },
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          
          // Description text
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSizeSm,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// 📈 Activity overview card (like sleep analysis)
  Widget _buildActivityOverview(HomeProvider homeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: NabdCard.section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.nabdPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.assessment_outlined,
                    color: AppTheme.nabdPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition Assessment',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Your nutrition is on track for today',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXl),
            
            // Assessment score (like sleep score)
            Center(
              child: ProgressRing.assessment(
                score: 85,
                maxScore: 100,
                subtitle: 'Nutrition Score',
                color: AppTheme.nabdGreen,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            
            Text(
              'You\'re doing great! Keep up the balanced nutrition.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  /// ✅ Daily tasks section
  Widget _buildDailyTasks(HomeProvider homeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spaceLg),
              child: Text(
                'Your daily task',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: AppTheme.fontSizeXl,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spaceLg),
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyTasksScreen()),
                ),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.nabdBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppTheme.nabdBlue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        // Task completion text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            '3/4 completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        // Tasks grid (2x2)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.spaceMd,
            mainAxisSpacing: AppTheme.spaceMd,
            childAspectRatio: 1.0,
            children: [
              _buildTaskCard(
                title: 'Water intake',
                subtitle: 'Drink 8 glasses',
                isCompleted: true,
                icon: Icons.water_drop,
                color: AppTheme.nabdBlue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WaterTrackingScreen()),
                ),
              ),
              _buildTaskCard(
                title: 'Meal logging',
                subtitle: 'Log 3 meals',
                isCompleted: true,
                icon: Icons.restaurant,
                color: AppTheme.nabdGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FoodLoggingScreenWithProvider()),
                ),
              ),
              _buildTaskCard(
                title: 'Exercise',
                subtitle: '30 min workout',
                isCompleted: true,
                icon: Icons.fitness_center,
                color: AppTheme.nabdOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityScreenWithProvider()),
                ),
              ),
              _buildTaskCard(
                title: 'Daily Tasks',
                subtitle: 'Track your progress',
                isCompleted: false,
                icon: Icons.checklist,
                color: AppTheme.nabdPurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyTasksScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// ✅ Task card widget
  Widget _buildTaskCard({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return NabdCard(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and completion status
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
              ),
              const Spacer(),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.nabdGreen : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isCompleted
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
            ],
          ),
          const Spacer(),
          
          // Task info
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 🤖 AI Recommendations preview section
  Widget _buildAIRecommendationsPreview(HomeProvider homeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'AI Recommendations',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: AppTheme.fontSizeXl,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spaceMd,
                      vertical: AppTheme.spaceXs,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.nabdBlue, AppTheme.nabdPurple],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      'AI',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: AppTheme.fontSizeXs,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIRecommendationsScreenWithProvider()),
                ),
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.nabdBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppTheme.nabdBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        // AI Preview cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Column(
            children: [
              _buildAIPreviewCard(
                icon: Icons.restaurant_outlined,
                title: 'Nutrition Tip',
                content: 'Try adding more protein to your breakfast for sustained energy.',
                color: AppTheme.nabdGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIRecommendationsScreenWithProvider()),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              _buildAIPreviewCard(
                icon: Icons.fitness_center_outlined,
                title: 'Activity Suggestion',
                content: 'A 10-minute walk after lunch can improve digestion.',
                color: AppTheme.nabdOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIRecommendationsScreenWithProvider()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 💡 AI preview card
  Widget _buildAIPreviewCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    required VoidCallback onTap,
  }) {
    return NabdCard.compact(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceXs),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          const Icon(
            Icons.arrow_forward_ios,
            color: AppTheme.textTertiary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
