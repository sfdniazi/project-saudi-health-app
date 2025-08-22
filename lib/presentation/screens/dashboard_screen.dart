import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_appbar.dart';
import '../widgets/calorie_card.dart';
import '../widgets/nutrient_card.dart';
import '../widgets/meal_card.dart';
import '../../core/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/food_model.dart';
import '../../services/firebase_service.dart';
import 'meal_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _notificationsEnabled = true;

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
    final meals = [
      {
        'title': 'Breakfast',
        'subtitle': 'Oatmeal with fresh berries and honey',
        'kcal': '320 kcal',
        'img': 'https://images.unsplash.com/photo-1546069901-eacef0df6022',
        'time': '8:00 AM',
      },
      {
        'title': 'Lunch',
        'subtitle': 'Grilled chicken salad with quinoa',
        'kcal': '450 kcal',
        'img': 'https://images.unsplash.com/photo-1604908177092-d9d9487f00f6',
        'time': '12:30 PM',
      },
      {
        'title': 'Dinner',
        'subtitle': 'Salmon bowl with vegetables',
        'kcal': '380 kcal',
        'img': 'https://images.unsplash.com/photo-1542444459-db18b9d6b6af',
        'time': '7:00 PM',
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Custom app bar
          CustomAppBar(
            title: 'Overview',
            showProfile: false,
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 🎨 Enhanced welcome section with animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🎨 Enhanced app logo with animation
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // App name with heart
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Nabd',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Al-Hayah',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        'Your Personal Nutrition Companion',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Welcome message
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.waving_hand,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Welcome back! Ready to track your nutrition today?',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 🎯 Dynamic calorie card from user profile and food log
                StreamBuilder<UserModel?>(
                  stream: FirebaseService.streamCurrentUserProfile(),
                  builder: (context, userSnapshot) {
                    final userProfile = userSnapshot.data;
                    final goalCalories = userProfile?.calculatedDailyGoal ?? 2000; // 🎯 Use dynamic goal
                    
                    return StreamBuilder<FoodLogModel?>(
                      stream: FirebaseService.streamFoodLogData(
                        FirebaseAuth.instance.currentUser?.uid ?? '',
                        DateTime.now(),
                      ),
                      builder: (context, foodSnapshot) {
                        final currentCalories = foodSnapshot.data?.totalCalories ?? 0.0;
                        
                        return CalorieCard(
                          current: currentCalories.toInt(),
                          goal: goalCalories,
                        );
                      },
                    );
                  },
                ),
                
                // Nutrient cards section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Text(
                    'Macro Nutrients',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                
                // Nutrient cards grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: NutrientCard(
                              title: 'Protein',
                              subtitle: 'Muscle building',
                              value: '75',
                              unit: 'g',
                              color: AppTheme.accentBlack,
                              icon: Icons.fitness_center,
                              progress: 0.75,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Protein tracking details'),
                                    backgroundColor: AppTheme.accentBlack,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: NutrientCard(
                              title: 'Carbs',
                              subtitle: 'Energy source',
                              value: '210',
                              unit: 'g',
                              color: AppTheme.accentBlue,
                              icon: Icons.grain,
                              progress: 0.84,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Carbohydrate tracking details'),
                                    backgroundColor: AppTheme.accentBlue,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: NutrientCard(
                              title: 'Fat',
                              subtitle: 'Essential fats',
                              value: '60',
                              unit: 'g',
                              color: AppTheme.accentOrange,
                              icon: Icons.water_drop,
                              progress: 0.60,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fat tracking details'),
                                    backgroundColor: AppTheme.accentOrange,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: NutrientCard(
                              title: 'Fiber',
                              subtitle: 'Digestive health',
                              value: '28',
                              unit: 'g',
                              color: AppTheme.primaryGreen,
                              icon: Icons.eco,
                              progress: 0.70,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fiber tracking details'),
                                    backgroundColor: AppTheme.primaryGreen,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Meals section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Today\'s Meals',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${meals.length} meals',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Meals list
                ...meals.map((m) => MealCard(
                  title: m['title']!,
                  subtitle: m['subtitle']!,
                  kcal: m['kcal']!,
                  imageUrl: m['img']!,
                  time: m['time']!,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MealDetailScreen(
                          title: m['title']!,
                          subtitle: m['subtitle']!,
                          kcal: m['kcal']!,
                          imageUrl: m['img']!,
                        ),
                      ),
                    );
                  },
                )),
                
                // Bottom spacing
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
