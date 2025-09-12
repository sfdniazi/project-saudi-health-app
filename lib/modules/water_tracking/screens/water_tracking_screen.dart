import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/app_theme.dart';
import '../../../presentation/design_system/components/nabd_card.dart';
import '../../../presentation/design_system/components/progress_ring.dart';
import '../providers/water_tracking_provider.dart';

/// 💧 Beautiful water tracking screen matching reference design
class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WaterTrackingProvider(),
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
            'Water level',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<WaterTrackingProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceLg),
                child: Column(
                  children: [
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Main progress ring with add button
                    _buildMainProgressSection(provider),
                    const SizedBox(height: AppTheme.spaceXxxl),
                    
                    // Time period tabs
                    _buildTimePeriodTabs(),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // History section
                    _buildHistorySection(provider),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Goal settings card
                    _buildGoalCard(provider),
                    const SizedBox(height: AppTheme.spaceXl),
                    
                    // Reminder card
                    _buildReminderCard(provider),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 💧 Main progress section with large circular indicator
  Widget _buildMainProgressSection(WaterTrackingProvider provider) {
    return Column(
      children: [
        // Large progress ring with add button
        ProgressRingWithButton(
          progress: provider.progressPercentage,
          centerText: '${provider.currentIntake}/${provider.dailyGoal}ml',
          centerSubtext: '${(provider.progressPercentage * 100).round()}%',
          progressColor: AppTheme.nabdBlue,
          onAddPressed: () => provider.addWater(250), // Add 1 glass
          onRingTapped: () {
            _showAddWaterDialog(context, provider);
          },
        ),
        const SizedBox(height: AppTheme.spaceXl),
        
        // Glasses indicator
        Text(
          'You drank ${provider.glassesCompleted} out of ${provider.targetGlasses} glasses of water',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 📊 Time period tabs (Day/Week/Month/Year)
  Widget _buildTimePeriodTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.nabdBlue,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: AppTheme.nabdBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Day'),
          Tab(text: 'Week'),
          Tab(text: 'Month'),
          Tab(text: 'Year'),
        ],
      ),
    );
  }

  /// 📜 History section
  Widget _buildHistorySection(WaterTrackingProvider provider) {
    return NabdCard.section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Text(
                'History of drinking water',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // History entries
          ...provider.todayHistory.map((entry) => _buildHistoryEntry(entry)),
        ],
      ),
    );
  }

  /// 📝 History entry widget
  Widget _buildHistoryEntry(WaterEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('HH:mm').format(entry.timestamp),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            '${entry.amount} oz',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Goal settings card
  Widget _buildGoalCard(WaterTrackingProvider provider) {
    return NabdCard.section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag_outlined,
                color: AppTheme.nabdBlue,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Text(
                'Goal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Goal selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${provider.targetGlasses} glass per day',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: provider.goalEnabled,
                onChanged: provider.toggleGoal,
                activeColor: AppTheme.nabdBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ⏰ Reminder settings card
  Widget _buildReminderCard(WaterTrackingProvider provider) {
    return NabdCard.section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppTheme.nabdOrange,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Text(
                'Reminder',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Time slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeSlot('Morning', provider.morningReminder),
              _buildTimeSlot('Afternoon', provider.afternoonReminder),
              _buildTimeSlot('Evening', provider.eveningReminder),
            ],
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          Text(
            'Any time of the day',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// ⏰ Time slot widget
  Widget _buildTimeSlot(String label, bool enabled) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 40,
          decoration: BoxDecoration(
            color: enabled ? AppTheme.nabdBlue.withOpacity(0.1) : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: enabled ? AppTheme.nabdBlue : AppTheme.borderColor,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: enabled ? AppTheme.nabdBlue : AppTheme.textSecondary,
                fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 💧 Show add water dialog
  void _showAddWaterDialog(BuildContext context, WaterTrackingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Water'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How much water did you drink?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAddButton('1 Glass\n250ml', () {
                  provider.addWater(250);
                  Navigator.pop(context);
                }),
                _buildQuickAddButton('1 Bottle\n500ml', () {
                  provider.addWater(500);
                  Navigator.pop(context);
                }),
                _buildQuickAddButton('1 Liter\n1000ml', () {
                  provider.addWater(1000);
                  Navigator.pop(context);
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// 🚀 Quick add button
  Widget _buildQuickAddButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.nabdBlue.withOpacity(0.1),
        foregroundColor: AppTheme.nabdBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

/// 💧 Water entry model
class WaterEntry {
  final DateTime timestamp;
  final int amount; // in ml
  final String unit;

  WaterEntry({
    required this.timestamp,
    required this.amount,
    this.unit = 'oz',
  });
}
