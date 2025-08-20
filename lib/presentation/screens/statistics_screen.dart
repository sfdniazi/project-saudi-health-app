import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsScreen extends StatefulWidget {
  final int age;
  final double height; // in cm
  final double idealWeight; // in kg

  const StatisticsScreen({
    super.key,
    required this.age,
    required this.height,
    required this.idealWeight,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // === Default calorie target logic ===
  int getWeeklyTargetCalories() {
    if (widget.age < 18) return 1500;
    if (widget.age < 30) return 2000;
    if (widget.age < 50) return 1800;
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
      return const Scaffold(
        body: Center(child: Text("⚠️ Please log in to view statistics")),
      );
    }

    final weeklyCalories = getWeeklyTargetCalories();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Statistics"),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<double?>(
          stream: _getLatestWeight(),
          builder: (context, latestWeightSnapshot) {
            final latestWeight = latestWeightSnapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Current Weight Display ===
                  if (latestWeight != null)
                    Center(
                      child: Text(
                        "Current Weight: ${latestWeight.toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        "No weight recorded yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // === Weekly Activity Chart ===
                  const Text(
                    'Weekly Activity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                            (weeklyCalories / 7) +
                                (i % 2 == 0 ? 100 : -50), // Fake variance
                          );
                        }),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, meta) {
                                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                                return Text(
                                  labels[v.toInt() % labels.length],
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === Weight Progress Chart ===
                  const Text(
                    'Weight Progress',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No weight history yet"));
                        }

                        final docs = snapshot.data!.docs;
                        final weightHistory = docs
                            .map((d) => (d["weight"] as num).toDouble())
                            .toList();

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, meta) =>
                                      Text("W${v.toInt() + 1}"),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: true),
                              ),
                            ),
                            lineBarsData: [
                              // Weight progress line
                              LineChartBarData(
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 4,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.green.withOpacity(0.2),
                                ),
                                spots: List.generate(
                                  weightHistory.length,
                                      (i) => FlSpot(i.toDouble(), weightHistory[i]),
                                ),
                              ),
                              // Goal line
                              LineChartBarData(
                                isCurved: false,
                                color: Colors.red,
                                barWidth: 2,
                                dashArray: [6, 6],
                                spots: List.generate(
                                  weightHistory.length,
                                      (i) =>
                                      FlSpot(i.toDouble(), widget.idealWeight),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // === Add Weight Button ===
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final controller = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
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
                                  final value =
                                  double.tryParse(controller.text.trim());
                                  if (value != null) {
                                    await _addWeeklyWeight(value);
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text("Save"),
                              ),
                            ],
                          ),
                        );
                      },
                      label: const Text("Add Weekly Weight"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// === Helper Widget for Card Styling ===
  Widget _buildCard({required double height, required Widget child}) {
    return SizedBox(
      height: height,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(padding: const EdgeInsets.all(14.0), child: child),
      ),
    );
  }

  /// === Bar Chart Helper ===
  static BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 18,
          color: Colors.green,
          borderRadius: BorderRadius.circular(6),
        )
      ],
    );
  }
}
