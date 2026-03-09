import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FocusChart extends StatelessWidget {
  final Map<DateTime, int> data;

  const FocusChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final dates = data.keys.toList()..sort();

    if (dates.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "No focus data yet",
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),

          borderData: FlBorderData(
            show: false,
          ),

          titlesData: const FlTitlesData(
            show: false,
          ),

          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                dates.length,
                (i) => FlSpot(
                  i.toDouble(),
                  (data[dates[i]] ?? 0) / 60,
                ),
              ),

              isCurved: true,
              barWidth: 3,
              color: Colors.orange,

              dotData: const FlDotData(
                show: true,
              ),

              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}