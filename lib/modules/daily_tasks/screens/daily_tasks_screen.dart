import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_theme.dart';
import '../../../presentation/design_system/components/nabd_card.dart';
import '../../../presentation/design_system/components/mood_picker.dart';
import '../providers/daily_tasks_provider.dart';

/// 📋 Beautiful daily tasks screen matching reference design
class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DailyTasksProvider(),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Daily Tasks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<DailyTasksProvider>(
          builder: (context, provider, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily task header
                    _buildTaskHeader(provider),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Task completion progress
                    _buildProgressCard(provider),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Daily tasks grid (2x2)
                    _buildTasksGrid(provider),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Achievement cards
                    _buildAchievementCards(provider),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Additional tasks
                    _buildAdditionalTasks(provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 📋 Task header section
  Widget _buildTaskHeader(DailyTasksProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your daily task',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text(
          '${provider.completedTasksCount}/${provider.totalTasksCount} completed',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// 📊 Progress card
  Widget _buildProgressCard(DailyTasksProvider provider) {
    final progress = provider.completionProgress;
    final percentage = (progress * 100).round();
    
    return NabdCard.section(
      child: Column(
        children: [
          Text(
            'Daily Progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Circular progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppTheme.nabdGreen : AppTheme.nabdBlue,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Complete',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          Text(
            provider.motivationMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📝 Tasks grid (2x2 matching reference)
  Widget _buildTasksGrid(DailyTasksProvider provider) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppTheme.spaceMd,
        mainAxisSpacing: AppTheme.spaceMd,
        childAspectRatio: 1.0,
      ),
      itemCount: provider.mainTasks.length,
      itemBuilder: (context, index) {
        final task = provider.mainTasks[index];
        return _buildTaskCard(task, provider);
      },
    );
  }

  /// ✅ Individual task card
  Widget _buildTaskCard(DailyTask task, DailyTasksProvider provider) {
    return NabdCard(
      padding: const EdgeInsets.all(AppTheme.spaceLg),
      onTap: () => provider.toggleTask(task.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and completion status
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: task.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  task.icon,
                  color: task.color,
                  size: 18,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: task.isCompleted ? AppTheme.nabdGreen : AppTheme.borderColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: task.isCompleted
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
          
          // Task details
          Text(
            task.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          Text(
            task.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 🏆 Achievement cards
  Widget _buildAchievementCards(DailyTasksProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Achievements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Row(
          children: [
            // Nutrition achievement
            Expanded(
              child: _buildAchievementCard(
                icon: Icons.restaurant,
                title: 'Great Nutrition',
                description: 'Balanced meals today',
                color: AppTheme.nabdGreen,
                isAchieved: provider.nutritionAchievement,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMd),
            
            // Hydration achievement
            Expanded(
              child: _buildAchievementCard(
                icon: Icons.water_drop,
                title: 'Stay Hydrated',
                description: 'Goal reached',
                color: AppTheme.nabdBlue,
                isAchieved: provider.hydrationAchievement,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🏅 Achievement card
  Widget _buildAchievementCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isAchieved,
  }) {
    return NabdCard.compact(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAchieved ? color.withOpacity(0.2) : AppTheme.borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isAchieved ? color : AppTheme.textTertiary,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: isAchieved ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceSm),
          
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📋 Additional tasks
  Widget _buildAdditionalTasks(DailyTasksProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Tasks',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        ...provider.additionalTasks.map((task) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
          child: _buildListTaskCard(task, provider),
        )),
      ],
    );
  }

  /// 📝 List task card
  Widget _buildListTaskCard(DailyTask task, DailyTasksProvider provider) {
    return NabdCard.compact(
      onTap: () => provider.toggleTask(task.id),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: task.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              task.icon,
              color: task.color,
              size: 14,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: task.isCompleted ? AppTheme.nabdGreen : AppTheme.borderColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: task.isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
