import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/app_theme.dart';
import '../../../presentation/design_system/components/nabd_card.dart';
import '../providers/statistics_provider.dart';

/// 📊 Optimized Statistics Screen with clean design
class StatisticsScreenOptimized extends StatefulWidget {
  const StatisticsScreenOptimized({super.key});

  @override
  State<StatisticsScreenOptimized> createState() => _StatisticsScreenOptimizedState();
}

class _StatisticsScreenOptimizedState extends State<StatisticsScreenOptimized>
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern app bar
            _buildSliverAppBar(),
            
            // Statistics content
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Overview stats
                  _buildOverviewStats(),
                  const SizedBox(height: AppTheme.spaceXl),
                  
                  // Weekly progress chart
                  _buildWeeklyChart(),
                  const SizedBox(height: AppTheme.spaceXl),
                  
                  // Health metrics
                  _buildHealthMetrics(),
                  const SizedBox(height: AppTheme.spaceXl),
                  
                  // Trends insights
                  _buildTrendsInsights(),
                  const SizedBox(height: AppTheme.spaceXxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 Clean sliver app bar
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Statistics',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  /// 📈 Overview statistics cards
  Widget _buildOverviewStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: Row(
        children: [
          // Total calories
          Expanded(
            child: _buildStatCard(
              title: 'Total Calories',
              value: '14,250',
              subtitle: 'This week',
              icon: Icons.local_fire_department,
              color: AppTheme.nabdOrange,
              trend: '+12%',
              isPositive: true,
            ),
          ),
          const SizedBox(width: AppTheme.spaceMd),
          
          // Average steps
          Expanded(
            child: _buildStatCard(
              title: 'Avg Steps',
              value: '8,432',
              subtitle: 'Per day',
              icon: Icons.directions_walk,
              color: AppTheme.nabdBlue,
              trend: '+5%',
              isPositive: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Individual stat card
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String trend,
    required bool isPositive,
  }) {
    return NabdCard.stat(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceSm,
                  vertical: AppTheme.spaceXs,
                ),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  trend,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isPositive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: AppTheme.fontSizeXs,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),
          
          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppTheme.spaceXs),
          
          // Title and subtitle
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
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

  /// 📈 Clean weekly progress chart
  Widget _buildWeeklyChart() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
      child: NabdCard.section(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Progress',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // TODO: Add chart settings
                  },
                  icon: const Icon(
                    Icons.more_horiz,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceXl),
            
            // Clean bar chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 3000,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                          );
                          Widget text;
                          switch (value.toInt()) {
                            case 0:
                              text = const Text('Mon', style: style);
                              break;
                            case 1:
                              text = const Text('Tue', style: style);
                              break;
                            case 2:
                              text = const Text('Wed', style: style);
                              break;
                            case 3:
                              text = const Text('Thu', style: style);
                              break;
                            case 4:
                              text = const Text('Fri', style: style);
                              break;
                            case 5:
                              text = const Text('Sat', style: style);
                              break;
                            case 6:
                              text = const Text('Sun', style: style);
                              break;
                            default:
                              text = const Text('', style: style);
                              break;
                          }
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8,
                            child: text,
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _buildBarGroups(),
                ),
              ),
            ),
            
            // Legend
            const SizedBox(height: AppTheme.spaceLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Calories', AppTheme.nabdBlue),
                const SizedBox(width: AppTheme.spaceLg),
                _buildLegendItem('Goal', AppTheme.nabdGreen.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 Build bar chart data
  List<BarChartGroupData> _buildBarGroups() {
    final data = [2100, 1800, 2300, 2000, 1900, 2200, 2400]; // Sample data
    const goal = 2000.0;
    
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].toDouble(),
            color: AppTheme.nabdBlue,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: goal,
              color: AppTheme.nabdGreen.withOpacity(0.1),
            ),
          ),
        ],
      );
    });
  }

  /// 🎨 Legend item
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: AppTheme.spaceSm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// ❤️ Health metrics section
  Widget _buildHealthMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            'Health Metrics',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Row(
          children: [
            // Water intake
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spaceLg, right: AppTheme.spaceSm),
                child: _buildMetricCard(
                  title: 'Water',
                  value: '2.3L',
                  subtitle: 'Today',
                  progress: 0.85,
                  color: AppTheme.nabdBlue,
                ),
              ),
            ),
            
            // Sleep
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppTheme.spaceSm, right: AppTheme.spaceLg),
                child: _buildMetricCard(
                  title: 'Sleep',
                  value: '7.5h',
                  subtitle: 'Last night',
                  progress: 0.94,
                  color: AppTheme.nabdPurple,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Metric card with progress
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required double progress,
    required Color color,
  }) {
    return NabdCard.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSm),
          
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
          
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  /// 📈 Trends and insights
  Widget _buildTrendsInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Text(
            'Insights',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceLg),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLg),
          child: Column(
            children: [
              _buildInsightCard(
                icon: Icons.trending_up,
                title: 'Great Progress!',
                description: 'You\'ve increased your daily steps by 15% this week.',
                color: AppTheme.nabdGreen,
              ),
              const SizedBox(height: AppTheme.spaceMd),
              _buildInsightCard(
                icon: Icons.water_drop,
                title: 'Stay Hydrated',
                description: 'Try to drink more water in the afternoons.',
                color: AppTheme.nabdBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 💡 Insight card
  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return NabdCard.compact(
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
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
