import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/app_theme.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../models/food_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // === Default calorie target logic ===
  int getWeeklyTargetCalories(int age) {
    if (age < 18) return 1500;
    if (age < 30) return 2000;
    if (age < 50) return 1800;
    return 1600;
  }

  // === Save weight to Firestore ===
  Future<void> _addWeeklyWeight(double weight) async {
    if (currentUser == null) return;
    await _firestore
        .collection("users")
        .doc(currentUser!.uid)
        .collection("weightHistory")
        .add({
      "weight": weight,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  // === Get most recent weight ===
  Stream<double?> _getLatestWeight() {
    if (currentUser == null) return const Stream.empty();
    return _firestore
        .collection("users")
        .doc(currentUser!.uid)
        .collection("weightHistory")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isNotEmpty && snap.docs.first.data().containsKey("weight")) {
        return (snap.docs.first["weight"] as num).toDouble();
      }
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
          child: const Center(
            child: Text(
              "⚠️ Please log in to view statistics",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: StreamBuilder<UserModel?>(
        stream: FirebaseService.streamCurrentUserProfile(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(gradient: AppTheme.getHeaderGradient(context)), // 🎨 Theme-aware
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
          }

          final userProfile = userSnapshot.data;
          if (userProfile == null) {
            return Container(
              decoration: BoxDecoration(gradient: AppTheme.getHeaderGradient(context)), // 🎨 Theme-aware
              child: const Center(
                child: Text(
                  "Profile not found",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }

          final weeklyCalories = getWeeklyTargetCalories(userProfile.age);
          final displayName = userProfile.displayName.isNotEmpty
              ? userProfile.displayName
              : (currentUser?.email?.split('@').first ?? 'User');

          return Column(
            children: [
              // Custom app bar with theme
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: BoxDecoration(
                  gradient: AppTheme.getHeaderGradient(context), // 🎨 Theme-aware header gradient
                ),
                child: Row(
                  children: [
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: Container(
                  color: AppTheme.getBackgroundColor(context), // 🎨 Theme-aware background
                  child: StreamBuilder<double?>(
                    stream: _getLatestWeight(),
                    builder: (context, latestWeightSnapshot) {
                      final latestWeight = latestWeightSnapshot.data;

                      return StreamBuilder<FoodLogModel?>(
                        stream: FirebaseService.streamFoodLogData(
                          currentUser!.uid,
                          DateTime.now(),
                        ),
                        builder: (context, foodSnapshot) {
                          final todayCalories = foodSnapshot.data?.totalCalories ?? 0.0;
                          
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Latest metrics cards
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildLatestCard(
                                        'Latest Weight',
                                        latestWeight != null
                                            ? '${latestWeight.toStringAsFixed(1)} kg'
                                            : 'No data',
                                        Icons.monitor_weight,
                                        AppTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildLatestCard(
                                        'Latest Calories',
                                        '${todayCalories.toInt()} kcal',
                                        Icons.local_fire_department,
                                        Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Weekly Activity Chart
                                Text(
                                  'Weekly Activity',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildCard(
                                  height: 250,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      barGroups: List.generate(7, (i) {
                                        return _makeBar(
                                          i,
                                          (weeklyCalories / 7) + (i % 2 == 0 ? 100 : -50),
                                        );
                                      }),
                                      borderData: FlBorderData(show: false),
                                      gridData: const FlGridData(show: false),
                                      titlesData: FlTitlesData(
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (v, meta) {
                                              const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                              return Text(
                                                labels[v.toInt() % labels.length],
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(showTitles: false),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Weight Progress Chart
                                Text(
                                  'Weight Progress',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildCard(
                                  height: 300,
                                  child: StreamBuilder<QuerySnapshot>(
                                    stream: _firestore
                                        .collection("users")
                                        .doc(currentUser!.uid)
                                        .collection("weightHistory")
                                        .orderBy("timestamp", descending: false)
                                        .snapshots(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                                        );
                                      }

                                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                        return Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.monitor_weight_outlined,
                                                size: 48,
                                                color: AppTheme.textLight,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "No weight history yet",
                                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }

                                      final docs = snapshot.data!.docs;
                                      final weightHistory = docs
                                          .map((d) => (d["weight"] as num).toDouble())
                                          .toList();

                                      return LineChart(
                                        LineChartData(
                                          gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false,
                                            getDrawingHorizontalLine: (value) {
                                              return FlLine(
                                                color: AppTheme.textLight.withValues(alpha: 0.1),
                                                strokeWidth: 1,
                                              );
                                            },
                                          ),
                                          titlesData: FlTitlesData(
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (v, meta) => Text(
                                                  "W${v.toInt() + 1}",
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (v, meta) => Text(
                                                  "${v.toInt()}kg",
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            topTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                            rightTitles: const AxisTitles(
                                              sideTitles: SideTitles(showTitles: false),
                                            ),
                                          ),
                                          lineBarsData: [
                                            // Weight progress line
                                            LineChartBarData(
                                              isCurved: true,
                                              color: AppTheme.primaryGreen,
                                              barWidth: 3,
                                              dotData: const FlDotData(show: true),
                                              belowBarData: BarAreaData(
                                                show: true,
                                                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                              ),
                                              spots: List.generate(
                                                weightHistory.length,
                                                (i) => FlSpot(i.toDouble(), weightHistory[i]),
                                              ),
                                            ),
                                            // Goal line
                                            if (userProfile.idealWeight > 0)
                                              LineChartBarData(
                                                isCurved: false,
                                                color: AppTheme.accentOrange,
                                                barWidth: 2,
                                                dashArray: [6, 6],
                                                dotData: const FlDotData(show: false),
                                                spots: List.generate(
                                                  weightHistory.length,
                                                  (i) => FlSpot(i.toDouble(), userProfile.idealWeight),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Add Weight Button
                                Center(
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                                      onPressed: () async {
                                        final controller = TextEditingController();
                                        await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            title: const Text("Add Weekly Weight"),
                                            content: TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                hintText: "Enter weight (kg)",
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Cancel"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final value = double.tryParse(controller.text.trim());
                                                  if (value != null) {
                                                    await _addWeeklyWeight(value);
                                                  }
                                                  if (context.mounted) {
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: const Text("Save"),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      label: const Text(
                                        "Add Weekly Weight",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Helper Widget for Card Styling
  Widget _buildCard({required double height, required Widget child}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: child,
      ),
    );
  }

  /// Helper Widget for Latest Cards
  Widget _buildLatestCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
          const SizedBox(height: 8),
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
            ),
          ),
        ],
      ),
    );
  }

  /// Bar Chart Helper
  static BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 18,
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryGreen, AppTheme.secondaryGreen],
          ),
        )
      ],
    );
  }
}
