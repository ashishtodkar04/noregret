import 'package:flutter/material.dart';
import '../core/schedule_store.dart';
import '../models/schedule_block.dart';

class ScheduleTimeline extends StatelessWidget {
  const ScheduleTimeline({super.key});

  String _format(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final blocks = ScheduleStore.dailyBlocks;

    if (blocks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Opacity(
            opacity: 0.4,
            child: Text(
              "No schedule planned for today.",
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            "UP NEXT",
            style: TextStyle(
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.2, 
              color: Colors.white38
            ),
          ),
        ),
        ...blocks.asMap().entries.map((entry) {
          int idx = entry.key;
          ScheduleBlock block = entry.value;
          bool isLast = idx == blocks.length - 1;

          return IntrinsicHeight(
            child: Row(
              children: [
                // Timeline Connector Logic
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 2),
                        color: Colors.black,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.white10,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Task Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_format(block.start)} – ${_format(block.end)}",
                          style: const TextStyle(
                            fontSize: 11, 
                            color: Colors.orange, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          block.title,
                          style: const TextStyle(
                            fontSize: 15, 
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}