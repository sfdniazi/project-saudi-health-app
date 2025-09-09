import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/app_theme.dart';
import '../models/statistics_state_model.dart';
import '../utils/responsive_layout_utils.dart';
import 'adaptive_ui_components.dart';

/// Chart widgets for statistics screen
class StatisticsChartWidgets {
  
  /// Build improved weekly activity bar chart with responsive design and collapsible sections
  static Widget buildWeeklyActivityChart({
    required BuildContext context,
    required List<WeeklyActivityData> weeklyData,
    required double weeklyTarget,
    required bool isCollapsed,
    required VoidCallback onToggle,
    ViewMode viewMode = ViewMode.detailed,
    ChartDisplayMode chartDisplayMode = ChartDisplayMode.full,
    bool showControls = true,
  }) {
    // Calculate responsive height
    final responsiveHeight = ResponsiveLayoutUtils.calculateChartHeight(
      context: context,
      dataCount: weeklyData.length,
      baseHeight: chartDisplayMode == ChartDisplayMode.compressed ? 200 : 280,
    );

    return CollapsibleSection(
      title: 'Weekly Activity',
      subtitle: viewMode == ViewMode.minimal ? null : 'Daily calorie consumption',
      isCollapsed: isCollapsed,
      onToggle: onToggle,
      leadingIcon: Icons.bar_chart,
      trailing: showControls ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (context.isTabletOrLarger)
            ChartDisplayModeSelector(
              currentMode: chartDisplayMode,
              onModeChanged: (mode) {
                // This would be handled by the parent widget
              },
            ),
        ],
      ) : null,
      child: Container(
        height: responsiveHeight,
        padding: context.responsivePadding(const EdgeInsets.all(20)),
        child: weeklyData.isEmpty
            ? _buildEmptyChartState(context, 'No activity data available')
            : LayoutBuilder(
                builder: (context, constraints) {
                  return _buildResponsiveBarChart(
                    context: context,
                    constraints: constraints,
                    weeklyData: weeklyData,
                    weeklyTarget: weeklyTarget,
                    viewMode: viewMode,
                    chartDisplayMode: chartDisplayMode,
                  );
                },
              ),
      ),
    );
  }

  /// Build weight progress line chart with responsive design
  static Widget buildWeightProgressChart({
    required BuildContext context,
    required List<WeightHistoryEntry> weightHistory,
    required double idealWeight,
    required bool isCollapsed,
    required VoidCallback onToggle,
    ViewMode viewMode = ViewMode.detailed,
    ChartDisplayMode chartDisplayMode = ChartDisplayMode.full,
    bool showControls = true,
    Function(String)? onDeleteEntry,
    Set<String> deletingEntries = const {},
  }) {
    // Calculate responsive height
    final responsiveHeight = ResponsiveLayoutUtils.calculateChartHeight(
      context: context,
      dataCount: weightHistory.length,
      baseHeight: chartDisplayMode == ChartDisplayMode.compressed ? 240 : 320,
    );

    return CollapsibleSection(
      title: 'Weight Progress',
      subtitle: viewMode == ViewMode.minimal 
        ? null 
        : 'Last ${weightHistory.length} entries',
      isCollapsed: isCollapsed,
      onToggle: onToggle,
      leadingIcon: Icons.timeline,
      trailing: showControls ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (idealWeight > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 2,
                    color: AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Goal: ${idealWeight.toStringAsFixed(1)}kg',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: context.responsiveFontSize(10),
                    ),
                  ),
                ],
              ),
            ),
          if (context.isTabletOrLarger) ...[
            const SizedBox(width: 8),
            ChartDisplayModeSelector(
              currentMode: chartDisplayMode,
              onModeChanged: (mode) {
                // This would be handled by the parent widget
              },
            ),
          ],
        ],
      ) : null,
      child: Container(
        padding: context.responsivePadding(const EdgeInsets.all(20)),
        child: weightHistory.isEmpty
            ? SizedBox(
                height: responsiveHeight,
                child: _buildEmptyChartState(context, 'No weight history available'),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chart section with fixed height
                  SizedBox(
                    height: chartDisplayMode == ChartDisplayMode.compressed ? 200 : 280,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return LineChart(
                          _buildResponsiveLineChartData(
                            weightHistory,
                            idealWeight,
                            context,
                            chartDisplayMode,
                          ),
                        );
                      },
                    ),
                  ),
                  // Recent entries section
                  if (onDeleteEntry != null && viewMode != ViewMode.minimal) ...[
                    const SizedBox(height: 16),
                    _buildWeightHistoryList(
                      context: context,
                      weightHistory: weightHistory.take(3).toList(),
                      onDelete: onDeleteEntry,
                      deletingEntries: deletingEntries,
                      isCompactMode: chartDisplayMode == ChartDisplayMode.compressed,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  /// Build enhanced weekly summary table with delete functionality and responsive design
  static Widget buildWeeklyTable({
    required BuildContext context,
    required List<WeeklyActivityData> weeklyData,
    required double weeklyTarget,
    required bool isCollapsed,
    required VoidCallback onToggle,
    ViewMode viewMode = ViewMode.detailed,
    bool showDeleteButtons = false,
    Function(int)? onDeleteEntry,
    Set<int> deletingEntries = const {},
    int currentPage = 0,
    int totalPages = 1,
    Function(int)? onPageChanged,
    bool showControls = true,
  }) {
    return CollapsibleSection(
      title: 'Weekly Summary',
      subtitle: viewMode == ViewMode.minimal 
        ? null 
        : 'Daily targets vs actual consumption',
      isCollapsed: isCollapsed,
      onToggle: onToggle,
      leadingIcon: Icons.table_chart,
      trailing: showControls ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (context.isTabletOrLarger)
            IconButton(
              icon: Icon(
                showDeleteButtons ? Icons.edit_off : Icons.edit,
                color: AppTheme.primaryGreen,
                size: context.responsiveFontSize(18),
              ),
              onPressed: () {
                // This would be handled by the parent widget to toggle delete mode
              },
              tooltip: showDeleteButtons ? 'Exit Edit Mode' : 'Edit Mode',
            ),
        ],
      ) : null,
      child: Container(
        padding: context.responsivePadding(const EdgeInsets.all(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive table implementation
            if (context.isMobile && viewMode == ViewMode.compact)
              _buildMobileWeeklyTable(
                context: context,
                weeklyData: weeklyData,
                weeklyTarget: weeklyTarget,
                showDeleteButtons: showDeleteButtons,
                onDeleteEntry: onDeleteEntry,
                deletingEntries: deletingEntries,
              )
            else
              _buildDesktopWeeklyTable(
                context: context,
                weeklyData: weeklyData,
                weeklyTarget: weeklyTarget,
                showDeleteButtons: showDeleteButtons,
                onDeleteEntry: onDeleteEntry,
                deletingEntries: deletingEntries,
                viewMode: viewMode,
              ),
            
            // Pagination controls if needed
            if (totalPages > 1 && onPageChanged != null)
              PaginationControls(
                currentPage: currentPage,
                totalPages: totalPages,
                onPageChanged: onPageChanged,
                hasMoreData: currentPage < totalPages - 1,
                itemsPerPage: weeklyData.length,
                totalItems: weeklyData.length * totalPages,
              ),
            
            // Summary row
            if (weeklyData.isNotEmpty && viewMode != ViewMode.minimal) ...[
              const SizedBox(height: 16),
              _buildWeeklySummaryRow(
                context: context,
                weeklyData: weeklyData,
                weeklyTarget: weeklyTarget,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Private helper methods

  /// Calculate maximum Y value for bar chart
  static double _calculateMaxY(List<WeeklyActivityData> weeklyData, double weeklyTarget) {
    final maxCalories = weeklyData.isEmpty 
        ? weeklyTarget
        : weeklyData.map((e) => e.calories).reduce((a, b) => a > b ? a : b);
    final dailyTarget = weeklyTarget / 7;
    return [maxCalories, dailyTarget].reduce((a, b) => a > b ? a : b) * 1.2;
  }

  /// Build bar chart groups from weekly data
  static List<BarChartGroupData> _buildBarGroups(List<WeeklyActivityData> weeklyData) {
    return weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final isToday = _isToday(data.date);
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.calories,
            width: 16,
            color: isToday ? AppTheme.accentOrange : AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isToday
                  ? [AppTheme.accentOrange, AppTheme.accentOrange.withOpacity(0.7)]
                  : [AppTheme.primaryGreen, AppTheme.secondaryGreen],
            ),
          ),
        ],
      );
    }).toList();
  }


  /// Build empty state for charts
  static Widget _buildEmptyChartState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart,
            size: 48,
            color: AppTheme.textLight,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build responsive bar chart with adaptations based on constraints and mode
  static Widget _buildResponsiveBarChart({
    required BuildContext context,
    required BoxConstraints constraints,
    required List<WeeklyActivityData> weeklyData,
    required double weeklyTarget,
    required ViewMode viewMode,
    required ChartDisplayMode chartDisplayMode,
  }) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(weeklyData, weeklyTarget),
        minY: 0,
        barGroups: _buildBarGroups(weeklyData),
        borderData: FlBorderData(show: false),
        gridData: _buildResponsiveGridData(context, weeklyTarget, chartDisplayMode),
        titlesData: _buildResponsiveBarTitlesData(context, weeklyData, chartDisplayMode),
        barTouchData: _buildBarTouchData(weeklyData),
      ),
    );
  }

  /// Build responsive line chart data
  static LineChartData _buildResponsiveLineChartData(
    List<WeightHistoryEntry> weightHistory,
    double idealWeight,
    BuildContext context,
    ChartDisplayMode chartDisplayMode,
  ) {
    final weights = weightHistory.map((e) => e.weight).toList();
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final weightRange = maxWeight - minWeight;
    
    // Adjust Y-axis range
    final minY = (minWeight - weightRange * 0.1).clamp(0, double.infinity);
    final maxY = maxWeight + weightRange * 0.1;
    
    // Calculate responsive interval
    final interval = ResponsiveLayoutUtils.getChartInterval(
      context: context,
      dataCount: weightHistory.length,
      dataRange: weightRange,
    );
    
    return LineChartData(
      minY: minY.toDouble(),
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: AppTheme.textLight.withOpacity(0.1),
            strokeWidth: chartDisplayMode == ChartDisplayMode.compressed ? 0.5 : 1,
          );
        },
      ),
      titlesData: _buildResponsiveLineTitlesData(
        context,
        weightHistory,
        interval,
        chartDisplayMode,
      ),
      lineBarsData: [
        // Weight progress line
        LineChartBarData(
          isCurved: true,
          color: AppTheme.primaryGreen,
          barWidth: chartDisplayMode == ChartDisplayMode.compressed ? 2 : 3,
          dotData: FlDotData(
            show: chartDisplayMode != ChartDisplayMode.compressed,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: chartDisplayMode == ChartDisplayMode.compressed ? 2 : 4,
                color: AppTheme.primaryGreen,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: chartDisplayMode == ChartDisplayMode.full,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.2),
                AppTheme.primaryGreen.withOpacity(0.05),
              ],
            ),
          ),
          spots: weightHistory.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.weight);
          }).toList(),
        ),
        
        // Goal line (if ideal weight is set)
        if (idealWeight > 0 && idealWeight >= minY && idealWeight <= maxY)
          LineChartBarData(
            isCurved: false,
            color: AppTheme.accentOrange,
            barWidth: chartDisplayMode == ChartDisplayMode.compressed ? 1.5 : 2,
            dashArray: [6, 6],
            dotData: const FlDotData(show: false),
            spots: [
              FlSpot(0, idealWeight),
              FlSpot(weightHistory.length - 1.0, idealWeight),
            ],
          ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: AppTheme.primaryGreen.withOpacity(0.9),
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final entry = weightHistory[spot.x.toInt()];
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)} kg\n',
                TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: context.responsiveFontSize(12),
                ),
                children: [
                  TextSpan(
                    text: '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: context.responsiveFontSize(10),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Build responsive grid data for bar charts
  static FlGridData _buildResponsiveGridData(
    BuildContext context,
    double weeklyTarget,
    ChartDisplayMode chartDisplayMode,
  ) {
    return FlGridData(
      show: chartDisplayMode != ChartDisplayMode.overview,
      drawVerticalLine: false,
      horizontalInterval: chartDisplayMode == ChartDisplayMode.compressed 
        ? weeklyTarget / 2 
        : weeklyTarget / 4,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: AppTheme.textLight.withOpacity(0.1),
          strokeWidth: chartDisplayMode == ChartDisplayMode.compressed ? 0.5 : 1,
        );
      },
    );
  }

  /// Build responsive titles data for bar charts
  static FlTitlesData _buildResponsiveBarTitlesData(
    BuildContext context,
    List<WeeklyActivityData> weeklyData,
    ChartDisplayMode chartDisplayMode,
  ) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: chartDisplayMode == ChartDisplayMode.compressed ? 24 : 32,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < weeklyData.length) {
              final dayLabel = chartDisplayMode == ChartDisplayMode.compressed
                ? weeklyData[index].dayOfWeek.substring(0, 1)
                : weeklyData[index].dayOfWeek;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                child: Text(
                  dayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    fontSize: context.responsiveFontSize(
                      chartDisplayMode == ChartDisplayMode.compressed ? 9 : 11,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: chartDisplayMode != ChartDisplayMode.overview,
          reservedSize: chartDisplayMode == ChartDisplayMode.compressed ? 36 : 48,
          interval: chartDisplayMode == ChartDisplayMode.compressed 
            ? 500.0 
            : 250.0,
          getTitlesWidget: (value, meta) {
            return Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(right: 8),
              child: Text(
                chartDisplayMode == ChartDisplayMode.compressed
                  ? '${(value / 1000).toStringAsFixed(1)}k'
                  : '${value.toInt()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: context.responsiveFontSize(
                    chartDisplayMode == ChartDisplayMode.compressed ? 8 : 10,
                  ),
                ),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }

  /// Build responsive titles data for line charts
  static FlTitlesData _buildResponsiveLineTitlesData(
    BuildContext context,
    List<WeightHistoryEntry> weightHistory,
    double interval,
    ChartDisplayMode chartDisplayMode,
  ) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: chartDisplayMode == ChartDisplayMode.compressed ? 24 : 32,
          interval: (weightHistory.length / (context.isMobile ? 3 : 5)).ceil().toDouble(),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < weightHistory.length) {
              final entry = weightHistory[index];
              return Container(
                margin: const EdgeInsets.only(top: 8),
                child: Text(
                  chartDisplayMode == ChartDisplayMode.compressed
                    ? '${entry.timestamp.day}'
                    : '${entry.timestamp.day}/${entry.timestamp.month}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: context.responsiveFontSize(
                      chartDisplayMode == ChartDisplayMode.compressed ? 8 : 10,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: chartDisplayMode != ChartDisplayMode.overview,
          reservedSize: chartDisplayMode == ChartDisplayMode.compressed ? 36 : 48,
          interval: interval,
          getTitlesWidget: (value, meta) {
            return Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.only(right: 8),
              child: Text(
                '${value.toStringAsFixed(0)}kg',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: context.responsiveFontSize(
                    chartDisplayMode == ChartDisplayMode.compressed ? 8 : 10,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  /// Build bar touch data
  static BarTouchData _buildBarTouchData(List<WeeklyActivityData> weeklyData) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        tooltipBgColor: AppTheme.primaryGreen.withOpacity(0.9),
        tooltipRoundedRadius: 8,
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            '${rod.toY.toInt()} kcal\n',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            children: [
              TextSpan(
                text: weeklyData[group.x.toInt()].dayOfWeek,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Build weight history list for quick delete access
  static Widget _buildWeightHistoryList({
    required BuildContext context,
    required List<WeightHistoryEntry> weightHistory,
    required Function(String) onDelete,
    required Set<String> deletingEntries,
    required bool isCompactMode,
  }) {
    return Container(
      padding: context.responsivePadding(const EdgeInsets.all(12)),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Entries',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: context.responsiveFontSize(12),
            ),
          ),
          const SizedBox(height: 8),
          ...weightHistory.asMap().entries.map((entry) {
            final weightEntry = entry.value;
            final entryId = '${weightEntry.timestamp.millisecondsSinceEpoch}';
            final isDeleting = deletingEntries.contains(entryId);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weightEntry.weight.toStringAsFixed(1)} kg',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: context.responsiveFontSize(13),
                          ),
                        ),
                        Text(
                          '${weightEntry.timestamp.day}/${weightEntry.timestamp.month}/${weightEntry.timestamp.year}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: context.responsiveFontSize(11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDeleting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade400,
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: context.responsiveFontSize(16),
                      ),
                      onPressed: () => onDelete(entryId),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build desktop/tablet weekly table
  static Widget _buildDesktopWeeklyTable({
    required BuildContext context,
    required List<WeeklyActivityData> weeklyData,
    required double weeklyTarget,
    required bool showDeleteButtons,
    required Function(int)? onDeleteEntry,
    required Set<int> deletingEntries,
    required ViewMode viewMode,
  }) {
    if (weeklyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 48,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 12),
              Text(
                'No weekly data available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width - 40,
        ),
        child: IntrinsicWidth(
          child: Column(
            children: [
              // Table header
              Container(
                padding: context.responsivePadding(const EdgeInsets.all(12)),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: context.isMobile ? 80 : 120,
                      child: Text(
                        'Day',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: context.responsiveFontSize(14),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: context.isMobile ? 70 : 90,
                      child: Text(
                        'Target',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: context.responsiveFontSize(14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: context.isMobile ? 70 : 90,
                      child: Text(
                        'Actual',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: context.responsiveFontSize(14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: context.isMobile ? 60 : 80,
                      child: Text(
                        'Status',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: context.responsiveFontSize(14),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (showDeleteButtons && onDeleteEntry != null)
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Action',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: context.responsiveFontSize(14),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Table rows
              ...weeklyData.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final dailyTarget = weeklyTarget / 7;
                final isAchieved = data.calories >= dailyTarget * 0.8;
                final isToday = _isToday(data.date);
                final isDeleting = deletingEntries.contains(index);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: context.responsivePadding(const EdgeInsets.all(12)),
                  decoration: BoxDecoration(
                    color: isToday 
                        ? AppTheme.primaryGreen.withOpacity(0.05)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.2))
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: context.isMobile ? 80 : 120,
                        child: Row(
                          children: [
                            Text(
                              data.dayOfWeek,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isToday ? AppTheme.primaryGreen : AppTheme.textPrimary,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                fontSize: context.responsiveFontSize(14),
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(
                        width: context.isMobile ? 70 : 90,
                        child: Text(
                          '${dailyTarget.toInt()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: context.responsiveFontSize(13),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: context.isMobile ? 70 : 90,
                        child: Text(
                          '${data.calories.toInt()}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: context.responsiveFontSize(13),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: context.isMobile ? 60 : 80,
                        child: Container(
                          alignment: Alignment.center,
                          child: Icon(
                            isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: context.responsiveFontSize(18),
                            color: isAchieved 
                                ? AppTheme.primaryGreen 
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                      if (showDeleteButtons && onDeleteEntry != null)
                        SizedBox(
                          width: 60,
                          child: Center(
                            child: isDeleting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red.shade400,
                                  ),
                                )
                              : IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade400,
                                    size: context.responsiveFontSize(18),
                                  ),
                                  onPressed: () => onDeleteEntry(index),
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build mobile weekly table with card layout
  static Widget _buildMobileWeeklyTable({
    required BuildContext context,
    required List<WeeklyActivityData> weeklyData,
    required double weeklyTarget,
    required bool showDeleteButtons,
    required Function(int)? onDeleteEntry,
    required Set<int> deletingEntries,
  }) {
    if (weeklyData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.table_chart_outlined,
                size: 48,
                color: AppTheme.textLight,
              ),
              const SizedBox(height: 12),
              Text(
                'No weekly data available',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: weeklyData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final dailyTarget = weeklyTarget / 7;
        final isAchieved = data.calories >= dailyTarget * 0.8;
        final isToday = _isToday(data.date);
        final isDeleting = deletingEntries.contains(index);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isToday 
                ? AppTheme.primaryGreen.withOpacity(0.05)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday 
                  ? AppTheme.primaryGreen.withOpacity(0.2)
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          data.dayOfWeek,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isToday ? AppTheme.primaryGreen : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: isAchieved 
                        ? AppTheme.primaryGreen 
                        : AppTheme.textLight,
                  ),
                  if (showDeleteButtons && onDeleteEntry != null) ...[
                    const SizedBox(width: 8),
                    isDeleting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.red.shade400,
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                          onPressed: () => onDeleteEntry(index),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              // Data rows
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dailyTarget.toInt()} kcal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actual',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${data.calories.toInt()} kcal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
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
      }).toList(),
    );
  }

  /// Build weekly summary row
  static Widget _buildWeeklySummaryRow({
    required BuildContext context,
    required List<WeeklyActivityData> weeklyData,
    required double weeklyTarget,
  }) {
    final totalCalories = weeklyData.fold(0.0, (sum, data) => sum + data.calories);
    final progressPercentage = (totalCalories / weeklyTarget).clamp(0.0, 1.0);
    
    return Container(
      padding: context.responsivePadding(const EdgeInsets.all(16)),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.accentOrange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: context.responsiveFontSize(16),
                ),
              ),
              Text(
                '${(progressPercentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.accentOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: context.responsiveFontSize(16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Progress bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: progressPercentage,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Summary stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: context.responsiveFontSize(12),
                    ),
                  ),
                  Text(
                    '${weeklyTarget.toInt()} kcal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Achieved',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: context.responsiveFontSize(12),
                    ),
                  ),
                  Text(
                    '${totalCalories.toInt()} kcal',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.w600,
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Check if date is today
  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }
}
