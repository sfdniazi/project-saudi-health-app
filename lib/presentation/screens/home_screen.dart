import 'package:flutter/material.dart';
import '../widgets/calorie_card.dart';
import '../widgets/meal_card.dart';
import '../widgets/custom_appbar.dart';
import '../../core/app_theme.dart';
import 'meal_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      {
        'title': 'Snack',
        'subtitle': 'Greek yogurt with nuts',
        'kcal': '150 kcal',
        'img': 'https://images.unsplash.com/photo-1488477181946-6428a0291777',
        'time': '3:00 PM',
      },
    ];

    return Scaffold(
      body: Column(
        children: [
          // Custom app bar
          const CustomAppBar(
            title: 'Nabd Al-Hayah',
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_outlined),
                onPressed: null,
              ),
            ],
          ),
          
          // Main content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // App logo and welcome section
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // App logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          color: Colors.white,
                          size: 40,
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
                            Icon(
                              Icons.emoji_waving_hand,
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
                
                // Calorie card
                const CalorieCard(current: 1300, goal: 2000),
                
                // Section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
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
