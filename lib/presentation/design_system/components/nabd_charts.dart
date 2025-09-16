import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/app_theme.dart';

/// 📊 Beautiful chart components matching the reference design
class NabdCharts {
  
  /// 📊 Mental health bar chart (matching reference design)
  static Widget buildMoodChart({
    required BuildContext context,
    required List<double> weekData, // 7 days of mood values (1-5)
    String title = 'Average mood',
    List<String> dayLabels = const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: AppTheme.elevationMd,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Chart
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < dayLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              dayLabels[value.toInt()],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSizeSm,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: weekData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  final color = _getMoodColor(value);
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: color,
                        width: 24,
                        borderRadius: BorderRadius.circular(4),
                        gradient: LinearGradient(
                          colors: [
                            color,
                            color.withOpacity(0.7),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Period selector (Day/Week/Month/Year)
          _buildPeriodSelector(),
        ],
      ),
    );
  }
  
  /// 🛌 Sleep analysis chart (like the reference)
  static Widget buildSleepAnalysisChart({
    required BuildContext context,
    required List<double> sleepData, // Hours of sleep per day
    String title = 'Sleep analysis',
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: AppTheme.elevationMd,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with assessment score
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Sleep score
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMd,
                  vertical: AppTheme.spaceSm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.nabdGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Text(
                  '93',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.nabdGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: AppTheme.fontSizeXxxl,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSm),
          
          Text(
            'Your sleep is better than 95% of users',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Sleep duration chart
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: 24,
                minY: 0,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const hours = ['11:55 pm', '', '', '', '', '', '07:40 am'];
                        if (value.toInt() >= 0 && value.toInt() < hours.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              hours[value.toInt()],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: sleepData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final value = entry.value;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: _getSleepColor(index), // Different colors for different sleep phases
                        width: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Sleep duration breakdown
          Text(
            'The total duration of sleep is 7h 45m',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          
          // Sleep phases
          Row(
            children: [
              _buildSleepPhase('6h 17m', 'Light sleep', AppTheme.chartBlue),
              const SizedBox(width: AppTheme.spaceXl),
              _buildSleepPhase('1h 28m', 'Deep sleep', AppTheme.nabdPurple),
              const SizedBox(width: AppTheme.spaceXl),
              _buildSleepPhase('5m', 'Awakening', AppTheme.nabdYellow),
            ],
          ),
        ],
      ),
    );
  }
  
  /// 📈 Nutrition progress line chart
  static Widget buildNutritionProgressChart({
    required BuildContext context,
    required List<FlSpot> caloriesData,
    required List<FlSpot> proteinData,
    required List<FlSpot> carbsData,
    String title = 'Nutrition Progress',
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceXl),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.borderColor, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor,
            blurRadius: AppTheme.elevationMd,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
          const SizedBox(height: AppTheme.spaceXl),
          
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              days[value.toInt()],
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: AppTheme.fontSizeSm,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Calories line
                  LineChartBarData(
                    spots: caloriesData,
                    color: AppTheme.nabdGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.nabdGreen,
                          strokeWidth: 2,
                          strokeColor: AppTheme.cardBackground,
                        ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.nabdGreen.withOpacity(0.1),
                          AppTheme.nabdGreen.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceXl),
          
          // Legend
          Row(
            children: [
              _buildLegendItem('Calories', AppTheme.nabdGreen),
              const SizedBox(width: AppTheme.spaceXl),
              _buildLegendItem('Protein', AppTheme.nabdBlue),
              const SizedBox(width: AppTheme.spaceXl),
              _buildLegendItem('Carbs', AppTheme.nabdOrange),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Helper: Get mood color based on value
  static Color _getMoodColor(double mood) {
    if (mood <= 1) return AppTheme.moodTerrible;
    if (mood <= 2) return AppTheme.moodBad;
    if (mood <= 3) return AppTheme.moodNeutral;
    if (mood <= 4) return AppTheme.moodGood;
    return AppTheme.moodAwesome;
  }
  
  /// Helper: Get sleep color based on phase
  static Color _getSleepColor(int index) {
    switch (index % 3) {
      case 0: return AppTheme.chartBlue;     // Light sleep
      case 1: return AppTheme.nabdPurple;    // Deep sleep
      case 2: return AppTheme.nabdYellow;    // Awakening
      default: return AppTheme.chartBlue;
    }
  }
  
  /// Helper: Period selector widget
  static Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Day', true),
        const SizedBox(width: AppTheme.spaceSm),
        _buildPeriodButton('Week', false),
        const SizedBox(width: AppTheme.spaceSm),
        _buildPeriodButton('Month', false),
        const SizedBox(width: AppTheme.spaceSm),
        _buildPeriodButton('Year', false),
      ],
    );
  }
  
  /// Helper: Period button
  static Widget _buildPeriodButton(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
        vertical: AppTheme.spaceSm,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.nabdBlue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.nabdBlue : AppTheme.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: AppTheme.fontSizeSm,
        ),
      ),
    );
  }
  
  /// Helper: Sleep phase indicator
  static Widget _buildSleepPhase(String duration, String label, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Text(
              duration,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: AppTheme.fontSizeMd,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: AppTheme.fontSizeSm,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Helper: Legend item
  static Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.fontSizeSm,
          ),
        ),
      ],
    );
  }
}
