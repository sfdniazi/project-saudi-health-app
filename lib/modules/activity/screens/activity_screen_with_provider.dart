import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/app_theme.dart';
import '../../../presentation/widgets/custom_appbar.dart';
import '../providers/activity_provider.dart';
import '../models/activity_state_model.dart';
import '../widgets/activity_shimmer_widgets.dart';

class ActivityScreenWithProvider extends StatefulWidget {
  const ActivityScreenWithProvider({super.key});

  @override
  State<ActivityScreenWithProvider> createState() => _ActivityScreenWithProviderState();
}

class _ActivityScreenWithProviderState extends State<ActivityScreenWithProvider>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Initialize the activity provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Activity Tracking',
        showProfile: false, // Don't show profile section for cleaner look
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await context.read<ActivityProvider>().refreshData();
          },
          child: Consumer<ActivityProvider>(
            builder: (context, activityProvider, child) {
              // Show error state if there's an error
              if (activityProvider.hasError) {
                return _buildErrorState(activityProvider);
              }

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        MediaQuery.of(context).padding.bottom + 16.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Activity Summary Card
                          _buildActivitySummarySection(activityProvider),
                          const SizedBox(height: 16),
                          
                          // Step Counter Section
                          _buildStepCounterSection(activityProvider),
                          const SizedBox(height: 16),
                          
                          // Water Intake Section
                          _buildWaterIntakeSection(activityProvider),
                          const SizedBox(height: 16),
                          
                          // Quick Actions
                          _buildQuickActionsSection(activityProvider),
                          
                          // Show success/error messages
                          if (activityProvider.activityState.messages.isNotEmpty) 
                            ..._buildMessageWidgets(activityProvider),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ActivityProvider activityProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              activityProvider.errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                activityProvider.clearError();
                activityProvider.initialize();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummarySection(ActivityProvider activityProvider) {
    if (activityProvider.isSectionLoading(ActivitySection.activityData)) {
      return ActivityShimmerWidgets.activitySummaryCardShimmer();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Today\'s Activity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildActivityMetric(
                    'Steps',
                    '${activityProvider.currentSteps}',
                    Icons.directions_walk,
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildActivityMetric(
                    'Distance',
                    '${activityProvider.currentDistance.toStringAsFixed(1)} km',
                    Icons.straighten,
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildActivityMetric(
                    'Calories',
                    '${activityProvider.currentCalories.toInt()}',
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
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

  Widget _buildStepCounterSection(ActivityProvider activityProvider) {
    if (activityProvider.isSectionLoading(ActivitySection.activityData)) {
      return ActivityShimmerWidgets.stepCounterShimmer();
    }

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
          Column(
            children: [
              CircularPercentIndicator(
                radius: 80,
                lineWidth: 12,
                percent: activityProvider.stepsProgress,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${activityProvider.currentSteps}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'of ${activityProvider.stepGoal}',
                      style: const TextStyle(
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
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _incrementSteps(activityProvider, 100),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add 100 Steps', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _incrementSteps(activityProvider, 1000),
                        icon: const Icon(Icons.directions_run, size: 18),
                        label: const Text('Add 1000', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterIntakeSection(ActivityProvider activityProvider) {
    if (activityProvider.isSectionLoading(ActivitySection.hydrationData)) {
      return ActivityShimmerWidgets.waterIntakeShimmer();
    }

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
              const Icon(
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
          Column(
            children: [
              CircularPercentIndicator(
                radius: 80,
                lineWidth: 12,
                percent: activityProvider.waterProgress,
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${activityProvider.currentWaterIntake.toStringAsFixed(1)}L',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'of ${activityProvider.waterGoal.toStringAsFixed(1)}L',
                      style: const TextStyle(
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
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addWater(activityProvider, 0.25),
                        icon: const Icon(Icons.local_drink, size: 18),
                        label: const Text('250ml', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _addWater(activityProvider, 0.5),
                        icon: const Icon(Icons.sports_bar, size: 18),
                        label: const Text('500ml', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(ActivityProvider activityProvider) {
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
                  () => _showGoalSetting(activityProvider),
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

  List<Widget> _buildMessageWidgets(ActivityProvider activityProvider) {
    return activityProvider.activityState.messages.map((message) {
      final isError = message.toLowerCase().contains('error') || 
                     message.toLowerCase().contains('failed');
      
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.green.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isError ? Colors.red.shade200 : Colors.green.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError ? Colors.red.shade700 : Colors.green.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => activityProvider.clearMessage(message),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: isError ? Colors.red.shade400 : Colors.green.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> _incrementSteps(ActivityProvider activityProvider, int additionalSteps) async {
    await activityProvider.incrementSteps(additionalSteps);
  }

  Future<void> _addWater(ActivityProvider activityProvider, double amount) async {
    await activityProvider.addWaterIntake(amount);
  }

  void _showHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Activity history feature coming soon!'),
      ),
    );
  }

  void _showGoalSetting(ActivityProvider activityProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int newStepGoal = activityProvider.stepGoal;
        double newWaterGoal = activityProvider.waterGoal;
        
        return AlertDialog(
          title: const Text('Set Your Goals'),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6, // Limit dialog height
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Step Goal',
                    suffixText: 'steps',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: newStepGoal.toString()),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      newStepGoal = parsed;
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Water Goal',
                    suffixText: 'liters',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: TextEditingController(text: newWaterGoal.toString()),
                  onChanged: (value) {
                    final parsed = double.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      newWaterGoal = parsed;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                activityProvider.updateStepGoal(newStepGoal);
                activityProvider.updateWaterGoal(newWaterGoal);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
