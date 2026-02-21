import 'package:flutter/material.dart';
import '../core/task_store.dart';
import '../core/schedule_store.dart';
import '../core/time_utils.dart';
import '../core/session_store.dart';
import '../main.dart'; // for appSettings

class WeeklyFocusWidget extends StatelessWidget {
  const WeeklyFocusWidget({super.key});

  Map<DateTime, int> _getWeeklyMomentum() {
    final Map<DateTime, int> momentum = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Initialize last 7 days
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      momentum[date] = 0;
    }

    // 1️⃣ Add Sessions
    final sessions = SessionStore.sessions;
    for (var session in sessions) {
      final date = DateTime(
        session.start.year,
        session.start.month,
        session.start.day,
      );

      if (momentum.containsKey(date)) {
        momentum[date] =
            (momentum[date] ?? 0) + session.durationSeconds;
      }
    }

    // 2️⃣ Add Task Completion Based On Schedule
    final allTasks = TaskStore.tasks;
    final scheduleBlocks = ScheduleStore.todayBlocks;

    for (final task in allTasks) {
      final normalizedTaskTitle =
          task.title.trim().toLowerCase();

      int scheduledSeconds = 1800;

      try {
        final block = scheduleBlocks.firstWhere(
          (b) =>
              b.title.trim().toLowerCase() ==
              normalizedTaskTitle,
        );

        final duration = block.duration;
        if (duration > 0) {
          scheduledSeconds = duration * 60;
        }
      } catch (_) {}

      for (final dateString in task.completionHistory) {
        try {
          final parts = dateString.split('-');
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );

          if (momentum.containsKey(date)) {
            momentum[date] =
                (momentum[date] ?? 0) + scheduledSeconds;
          }
        } catch (_) {}
      }
    }

    return momentum;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode =
            appSettings.ghostMode;
        final Color activeColor =
            Theme.of(context).primaryColor;

        return ValueListenableBuilder(
          valueListenable: TaskStore.tick,
          builder: (context, value, child) {
            final momentumData =
                _getWeeklyMomentum();

            final sortedDates =
                momentumData.keys.toList()
                  ..sort();

            final maxSeconds =
                momentumData.values.isEmpty ||
                        momentumData.values
                            .every((v) => v == 0)
                    ? 3600
                    : momentumData.values
                        .reduce((a, b) =>
                            a > b ? a : b);

            return Container(
              padding:
                  const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF111111),
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white
                        .withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        isGhostMode
                            ? "MOMENTUM_LOG"
                            : "Weekly Focus",
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      Icon(
                        isGhostMode
                            ? Icons
                                .analytics_outlined
                            : Icons
                                .insights_rounded,
                        color: activeColor
                            .withOpacity(0.7),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ...sortedDates.map((date) {
                    final seconds =
                        momentumData[date] ?? 0;

                    final ratio =
                        (seconds / maxSeconds)
                            .clamp(0.0, 1.0);

                    final isToday =
                        date.day ==
                                DateTime.now()
                                    .day &&
                            date.month ==
                                DateTime.now()
                                    .month;

                    final dayLabel = [
                      "Mon",
                      "Tue",
                      "Wed",
                      "Thu",
                      "Fri",
                      "Sat",
                      "Sun"
                    ][date.weekday - 1];

                    return Padding(
                      padding:
                          const EdgeInsets
                              .symmetric(
                                  vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 35,
                            child: Text(
                              dayLabel,
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color: isToday
                                    ? activeColor
                                    : Colors
                                        .white38,
                                fontWeight:
                                    isToday
                                        ? FontWeight
                                            .w900
                                        : FontWeight
                                            .bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 8),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 6,
                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .white
                                        .withOpacity(
                                            0.03),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                3),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration:
                                      const Duration(
                                          milliseconds:
                                              800),
                                  height: 6,
                                  width: (MediaQuery.of(
                                                  context)
                                              .size
                                              .width -
                                          160) *
                                      ratio,
                                  decoration:
                                      BoxDecoration(
                                    color: isToday
                                        ? activeColor
                                        : Colors
                                            .white24,
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                                3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                              width: 12),
                          SizedBox(
                            width: 45,
                            child: Text(
                              formatTotalTime(
                                  seconds),
                              textAlign:
                                  TextAlign.right,
                              style:
                                  TextStyle(
                                fontSize: 10,
                                color: isToday
                                    ? Colors
                                        .white
                                    : Colors
                                        .white24,
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
