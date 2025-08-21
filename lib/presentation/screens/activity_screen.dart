import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/activity_model.dart';
import '../../models/hydration_model.dart';
import '../../models/user_model.dart';
import '../../presentation/widgets/custom_appbar.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final user = FirebaseAuth.instance.currentUser;
  UserModel? userProfile;
  ActivityModel? todayActivity;
  HydrationModel? todayHydration;

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
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (user == null) return;
    
    try {
      final profile = await FirebaseService.getUserProfile(user!.uid);
      setState(() {
        userProfile = profile;
      });
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to continue')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Activity Tracking',
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity Summary Card
              _buildActivitySummaryCard(),
              const SizedBox(height: 20),
              
              // Step Counter Section
              _buildStepCounterSection(),
              const SizedBox(height: 20),
              
              // Water Intake Section
              _buildWaterIntakeSection(),
              const SizedBox(height: 20),
              
              // Quick Actions
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivitySummaryCard() {
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
                  Icons.trending_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Today\'s Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<ActivityModel?>(
            stream: FirebaseService.streamActivityData(user!.uid, DateTime.now()),
            builder: (context, snapshot) {
              final activity = snapshot.data;
              return Row(
                children: [
                  Expanded(
                    child: _buildActivityMetric(
                      'Steps',
                      '${activity?.steps ?? 0}',
                      Icons.directions_walk,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildActivityMetric(
                      'Distance',
                      '${(activity?.distance ?? 0.0).toStringAsFixed(1)} km',
                      Icons.straighten,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildActivityMetric(
                      'Calories',
                      '${activity?.calories.toInt() ?? 0}',
                      Icons.local_fire_department,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCounterSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(
                Icons.directions_walk,
                color: AppTheme.primaryGreen,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Step Counter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<ActivityModel?>(
            stream: FirebaseService.streamActivityData(user!.uid, DateTime.now()),
            builder: (context, snapshot) {
              final activity = snapshot.data;
              final steps = activity?.steps ?? 0;
              const stepGoal = 10000; // Default goal
              final progress = (steps / stepGoal).clamp(0.0, 1.0);

              return Column(
                children: [
                  CircularPercentIndicator(
                    radius: 80,
                    lineWidth: 12,
                    percent: progress,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$steps',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'of $stepGoal',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    progressColor: AppTheme.primaryGreen,
                    backgroundColor: AppTheme.textLight.withOpacity(0.1),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _incrementSteps(100),
                          icon: const Icon(Icons.add),
                          label: const Text('Add 100 Steps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _incrementSteps(1000),
                          icon: const Icon(Icons.directions_run),
                          label: const Text('Add 1000'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(
                Icons.water_drop,
                color: Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Water Intake',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<HydrationModel?>(
            stream: FirebaseService.streamHydrationData(user!.uid, DateTime.now()),
            builder: (context, snapshot) {
              final hydration = snapshot.data;
              final intake = hydration?.waterIntake ?? 0.0;
              final goal = hydration?.goalAmount ?? 2.5;
              final progress = (intake / goal).clamp(0.0, 1.0);

              return Column(
                children: [
                  CircularPercentIndicator(
                    radius: 80,
                    lineWidth: 12,
                    percent: progress,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${intake.toStringAsFixed(1)}L',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'of ${goal.toStringAsFixed(1)}L',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    progressColor: Colors.blue,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addWater(0.25),
                          icon: const Icon(Icons.local_drink),
                          label: const Text('250ml'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addWater(0.5),
                          icon: const Icon(Icons.sports_bar),
                          label: const Text('500ml'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'View History',
                  Icons.history,
                  AppTheme.primaryGreen,
                  () => _showHistory(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Set Goals',
                  Icons.flag,
                  Colors.orange,
                  () => _showGoalSetting(),
                ),
              ),
            ],
          ),
        ],
      ),
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
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _incrementSteps(int additionalSteps) async {
    if (user == null) return;

    try {
      final today = DateTime.now();
      final currentActivity = await FirebaseService.getActivityData(user!.uid, today);
      final weight = userProfile?.weight ?? 70.0;

      final newSteps = (currentActivity?.steps ?? 0) + additionalSteps;
      final distance = ActivityModel.estimateDistance(newSteps);
      final calories = ActivityModel.estimateCalories(newSteps, weight);

      final updatedActivity = ActivityModel(
        id: currentActivity?.id ?? '',
        userId: user!.uid,
        date: today,
        steps: newSteps,
        distance: distance,
        calories: calories,
        activeMinutes: currentActivity?.activeMinutes ?? 0,
        createdAt: currentActivity?.createdAt ?? today,
        updatedAt: today,
      );

      await FirebaseService.saveActivityData(updatedActivity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $additionalSteps steps!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating steps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addWater(double amount) async {
    if (user == null) return;

    try {
      final today = DateTime.now();
      final entry = WaterEntry(
        amount: amount,
        timestamp: today,
      );

      await FirebaseService.addWaterEntry(user!.uid, today, entry);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${(amount * 1000).toInt()}ml of water!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding water: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHistory() {
    // Navigate to activity history screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity history feature coming soon!'),
      ),
    );
  }

  void _showGoalSetting() {
    // Show goal setting dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Goal setting feature coming soon!'),
      ),
    );
  }
}
