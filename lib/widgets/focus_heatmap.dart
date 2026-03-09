import 'package:flutter/material.dart';

class FocusHeatmap extends StatelessWidget {
  final Map<DateTime, int> dataset;

  const FocusHeatmap({super.key, required this.dataset});

  Color _getColor(int minutes) {
    if (minutes == 0) return const Color(0xFF1A1A1A);
    if (minutes < 10) return const Color(0xFF3A2A00);
    if (minutes < 30) return const Color(0xFF7A4B00);
    if (minutes < 60) return Colors.orange;
    return const Color(0xFFFFB74D);
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    List<DateTime> days = List.generate(
      120,
      (i) => today.subtract(Duration(days: i)),
    ).reversed.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: days.map((date) {
          final minutes = dataset[DateTime(date.year, date.month, date.day)] ?? 0;

          return Tooltip(
            message: "$minutes minutes",
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _getColor(minutes),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}