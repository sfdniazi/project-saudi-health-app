import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        const SizedBox(height: 12),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Text('Weekly Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: [
                      _makeBar(0, 120),
                      _makeBar(1, 180),
                      _makeBar(2, 140),
                      _makeBar(3, 210),
                      _makeBar(4, 170),
                      _makeBar(5, 90),
                      _makeBar(6, 200),
                    ],
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,                       getTitlesWidget: (v, meta) {
                        const labels = ['M','T','W','T','F','S','S'];
                        return Text(labels[v.toInt() % labels.length]);
                      })),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ]),
    );
  }

  static BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(x: x, barRods: [BarChartRodData(toY: y, width: 18, color: Colors.green, borderRadius: BorderRadius.circular(6))]);
  }
}
