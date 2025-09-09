import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../providers/statistics_provider.dart';
import '../models/statistics_state_model.dart';
import '../widgets/statistics_shimmer_widgets.dart';
import '../widgets/statistics_chart_widgets.dart';
import '../widgets/adaptive_ui_components.dart';

/// Statistics screen with provider pattern and improved UI
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late StatisticsProvider _statisticsProvider;

  @override
  void initState() {
    super.initState();
    // Initialize provider
    _statisticsProvider = StatisticsProvider();
    
    // Initialize responsive preferences after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _statisticsProvider.initializeResponsivePreferences(context);
    });
  }

  @override
  void dispose() {
    _statisticsProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatisticsProvider>(
      create: (context) => _statisticsProvider,
      child: Scaffold(
        body: Consumer<StatisticsProvider>(
          builder: (context, provider, child) {
            final state = provider.state;

            // Show loading state
            if (state.isLoading && !state.isRefreshing) {
              return _buildLoadingState(context);
            }

            // Show error state
            if (state.hasError && state.weeklyActivityData.isEmpty) {
              return _buildErrorState(context, state.errorMessage, provider);
            }

            return _buildMainContent(context, state, provider);
          },
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(context, 'Loading...', false),
        Expanded(
          child: Container(
            color: AppTheme.getBackgroundColor(context),
            child: StatisticsShimmerWidgets.buildFullPageShimmer(context),
          ),
        ),
      ],
    );
  }

  /// Build error state
  Widget _buildErrorState(
    BuildContext context,
    String? errorMessage,
    StatisticsProvider provider,
  ) {
    return Column(
      children: [
        _buildAppBar(context, 'Statistics', false),
        Expanded(
          child: Container(
            color: AppTheme.getBackgroundColor(context),
            child: StatisticsShimmerWidgets.buildErrorState(
              context,
              errorMessage ?? 'Failed to load statistics',
              () => provider.refreshData(),
            ),
          ),
        ),
      ],
    );
  }

  /// Build main content
  Widget _buildMainContent(
    BuildContext context,
    StatisticsStateModel state,
    StatisticsProvider provider,
  ) {
    final displayName = state.displayName.isNotEmpty 
        ? state.displayName 
        : 'User';

    return Column(
      children: [
        // App bar without back button
        _buildAppBar(context, displayName, false),
        
        // Main content
        Expanded(
          child: Container(
            color: AppTheme.getBackgroundColor(context),
            child: RefreshIndicator(
              onRefresh: () => provider.refreshData(),
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Latest metrics cards
                    _buildLatestMetricsSection(context, state),
                    
                    const SizedBox(height: 24),
                    
                    // Weekly activity chart
                    if (state.isSectionLoading(StatisticsSection.weeklyActivity))
                      StatisticsShimmerWidgets.buildWeightChartShimmer(context)
                    else
                      StatisticsChartWidgets.buildWeeklyActivityChart(
                        context: context,
                        weeklyData: state.weeklyActivityData,
                        weeklyTarget: state.weeklyTargetCalories * 7,
                        isCollapsed: state.preferences.isChartsCollapsed,
                        onToggle: provider.toggleChartsCollapsed,
                        viewMode: state.preferences.viewMode,
                        chartDisplayMode: state.preferences.chartDisplayMode,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Weekly summary table
                    if (state.isSectionLoading(StatisticsSection.weeklyActivity))
                      StatisticsShimmerWidgets.buildWeeklyTableShimmer(context)
                    else
                      StatisticsChartWidgets.buildWeeklyTable(
                        context: context,
                        weeklyData: state.weeklyActivityData,
                        weeklyTarget: state.weeklyTargetCalories * 7,
                        isCollapsed: state.preferences.isTablesCollapsed,
                        onToggle: provider.toggleTablesCollapsed,
                        viewMode: state.preferences.viewMode,
                        showDeleteButtons: state.preferences.showDeleteButtons,
                        onDeleteEntry: (index) => _showDeleteWeeklyDataConfirmation(context, provider, index),
                        deletingEntries: state.deletionState.deletingItemIds.map((id) => int.tryParse(id) ?? -1).where((i) => i >= 0).toSet(),
                        currentPage: state.currentPage,
                        totalPages: (state.weeklyActivityData.length / state.preferences.itemsPerPage).ceil().clamp(1, double.infinity).toInt(),
                        onPageChanged: provider.changePage,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Weight progress chart
                    if (state.isSectionLoading(StatisticsSection.weightProgress))
                      StatisticsShimmerWidgets.buildWeightChartShimmer(context)
                    else
                      StatisticsChartWidgets.buildWeightProgressChart(
                        context: context,
                        weightHistory: state.weightHistory,
                        idealWeight: state.idealWeight,
                        isCollapsed: state.preferences.isChartsCollapsed,
                        onToggle: provider.toggleChartsCollapsed,
                        viewMode: state.preferences.viewMode,
                        chartDisplayMode: state.preferences.chartDisplayMode,
                        onDeleteEntry: (entryId) => _showDeleteWeightConfirmation(context, provider, entryId),
                        deletingEntries: state.deletionState.deletingItemIds,
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Add weight button
                    _buildAddWeightButton(context, provider),
                    
                    // Messages section
                    if (state.messages.isNotEmpty)
                      _buildMessagesSection(context, state, provider),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build app bar with back button
  Widget _buildAppBar(BuildContext context, String title, bool showBackButton) {
    // Get safe area padding
    final mediaQuery = MediaQuery.of(context);
    final statusBarHeight = mediaQuery.padding.top;
    final safeTopPadding = statusBarHeight + 16;
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, safeTopPadding, 20, 20),
      decoration: BoxDecoration(
        gradient: AppTheme.getHeaderGradient(context),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Back button with safe area consideration
            if (showBackButton)
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // Always show user greeting (removed showBackButton condition)
                  if (title != 'Loading...' && title != 'Statistics')
                    Text(
                      'Hello, $title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            
            // Optional statistics icon (always shown)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Can add settings or statistics functionality here
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.bar_chart,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build latest metrics section
  Widget _buildLatestMetricsSection(BuildContext context, StatisticsStateModel state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Latest weight card
          Expanded(
            child: _buildLatestCard(
              context: context,
              title: 'Latest Weight',
              value: state.latestWeight != null
                  ? '${state.latestWeight!.toStringAsFixed(1)} kg'
                  : 'No data',
              icon: Icons.monitor_weight,
              color: AppTheme.primaryGreen,
              isLoading: state.isSectionLoading(StatisticsSection.weightProgress),
            ),
          ),
          const SizedBox(width: 12),
          
          // Today's calories card
          Expanded(
            child: _buildLatestCard(
              context: context,
              title: 'Today\'s Calories',
              value: '${state.todayCalories.toInt()} kcal',
              icon: Icons.local_fire_department,
              color: Colors.orange,
              isLoading: state.isSectionLoading(StatisticsSection.weeklyActivity),
            ),
          ),
        ],
      ),
    );
  }

  /// Build latest metric card
  Widget _buildLatestCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isLoading,
  }) {
    if (isLoading) {
      return StatisticsShimmerWidgets.buildStatsCardShimmer(context);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
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
              const SizedBox(width: 8),
              Text(
                'Latest',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build add weight button
  Widget _buildAddWeightButton(BuildContext context, StatisticsProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add, color: Colors.white),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => _showAddWeightDialog(context, provider),
        label: const Text(
          'Add Weight Entry',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// Show add weight dialog
  Future<void> _showAddWeightDialog(BuildContext context, StatisticsProvider provider) async {
    final controller = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Add Weight Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter weight (kg)',
                prefixIcon: const Icon(Icons.monitor_weight),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will be added to your weight history',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0 && value < 300) {
                await provider.addWeightEntry(value);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Weight entry added successfully'),
                      backgroundColor: AppTheme.primaryGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid weight (1-300 kg)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Build messages section
  Widget _buildMessagesSection(
    BuildContext context,
    StatisticsStateModel state,
    StatisticsProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recent Updates',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: provider.clearMessages,
                icon: const Icon(Icons.clear, size: 16),
                color: AppTheme.primaryGreen,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...state.messages.map((message) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $message',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
      )),
        ],
      ),
    );
  }
  
  /// Show delete weight confirmation dialog
  Future<void> _showDeleteWeightConfirmation(
    BuildContext context, 
    StatisticsProvider provider, 
    String entryId
  ) async {
    return showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'Delete Weight Entry',
        content: 'Are you sure you want to delete this weight entry? This action cannot be undone.',
        showUndoOption: true,
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          // Find the weight entry by ID (timestamp)
          final weightEntry = provider.state.weightHistory.firstWhere(
            (entry) => '${entry.timestamp.millisecondsSinceEpoch}' == entryId,
            orElse: () => WeightHistoryEntry(weight: 0, timestamp: DateTime(2000)),
          );
          if (weightEntry.weight > 0) {
            provider.deleteWeightEntry(entryId, weightEntry);
          }
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
  
  /// Show delete weekly data confirmation dialog
  Future<void> _showDeleteWeeklyDataConfirmation(
    BuildContext context, 
    StatisticsProvider provider, 
    int index
  ) async {
    if (index < 0 || index >= provider.state.weeklyActivityData.length) {
      return;
    }
    
    final data = provider.state.weeklyActivityData[index];
    return showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        title: 'Delete Activity Data',
        content: 'Are you sure you want to delete the activity data for ${data.dayOfWeek}? This action cannot be undone.',
        showUndoOption: false,
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          // For now, just show a message since deleting weekly activity data
          // would typically require deleting food log entries which is more complex
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Weekly activity data deletion is not currently supported'),
              backgroundColor: Colors.orange,
            ),
          );
        },
        onCancel: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }
}
