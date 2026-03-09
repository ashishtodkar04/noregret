import 'package:flutter/material.dart';
import '../core/task_store.dart';
import '../core/session_store.dart';
import '../core/streak_store.dart';
import '../core/time_utils.dart';
import '../main.dart';
import '../core/stats_utils.dart' as stats_utils;
import '../widgets/focus_heatmap.dart';
import '../core/heatmap_utils.dart';
import '../widgets/focus_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  // ✅ TOTAL XP: Aggregates from ALL historical sessions
  int _calculateTotalXP() {
    final sessions = SessionStore.sessions;
    if (sessions.isEmpty) return 0;

    return sessions.fold(
      0,
      (sum, s) => sum + (s.durationMinutes * s.focusScore).toInt(),
    );
  }

  // ✅ RANK LOGIC
  String _getRankTitle(int xp) {
    if (xp > 10000) return "UNSTOPPABLE ENTITY";
    if (xp > 5000) return "WAR ROOM LEGEND";
    if (xp > 2000) return "DEEP KNIGHT";
    if (xp > 500) return "FOCUS SQUIRE";
    return "NOVICE MONK";
  }

  double _getRankProgress(int xp) {
    if (xp > 5000) return 1.0;
    if (xp > 2000) return (xp - 2000) / 3000;
    if (xp > 500) return (xp - 500) / 1500;
    return (xp / 500).clamp(0.0, 1.0);
  }

  Color _heatColor(int minutes, Color active) {
    if (minutes == 0) return const Color(0xFF1A1A1A);
    if (minutes < 90) return active.withOpacity(0.3);
    if (minutes < 180) return active.withOpacity(0.6);
    return active;
  }

  void _resetAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "PURGE ALL DATA?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This action is irreversible. All history will be lost.",
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "ERASE",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      TaskStore.clearAll();
      SessionStore.sessions.clear();
      StreakStore.reset();
      TaskStore.notify();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode = appSettings.ghostMode;
        final Color activeColor = Theme.of(context).primaryColor;

        return ValueListenableBuilder(
          valueListenable: TaskStore.tick,
          builder: (context, _, __) {
            return ValueListenableBuilder(
              valueListenable: SessionStore.tick,
              builder: (context, _, __) {
                final dailyTotals = stats_utils.getLast7DaysFocus();
                final sortedDates = dailyTotals.keys.toList()..sort();
                final heatmapData = SessionStore.getHeatmapData();
                final totalXP = _calculateTotalXP();
                final rankTitle = _getRankTitle(totalXP);
                final rankProgress = _getRankProgress(totalXP);

                return Scaffold(
                  backgroundColor: const Color(0xFF080808),
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    title: GestureDetector(
                      onLongPress: _resetAllData,
                      child: Text(
                        "PERFORMANCE",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 14,
                          color: isGhostMode ? Colors.white38 : Colors.white70,
                        ),
                      ),
                    ),
                    centerTitle: true,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // 🔥 Rank Section
                      Center(
                        child: Column(
                          children: [
                            Text(
                              rankTitle,
                              style: TextStyle(
                                color: activeColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: rankProgress,
                              backgroundColor: Colors.white10,
                              color: activeColor,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$totalXP TOTAL XP",
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      Row(
                        children: [
                          _MetricCard(
                            label: "FOCUS TIME",
                            value: formatTotalTime(
                              SessionStore.todayTotalSeconds,
                            ),
                            icon: Icons.timer_rounded,
                            color: activeColor,
                          ),
                          const SizedBox(width: 12),
                          _MetricCard(
                            label: "SESSIONS",
                            value: "${SessionStore.todaySessions.length}",
                            icon: Icons.bolt_rounded,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 12),
                          _MetricCard(
                            label: "TASKS",
                            value:
                                "${TaskStore.tasks.where((t) => t.isCompleted).length}",
                            icon: Icons.check_circle,
                            color: Colors.greenAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 📊 7 Day Momentum Chart (Time Focus)
                      const Text(
                        "MOMENTUM (LAST 7 DAYS)",
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...sortedDates.map((date) {
                        final seconds = dailyTotals[date] ?? 0;

                        // Determine scale based on max activity to make chart relative
                        final maxSeconds =
                            dailyTotals.values.every((v) => v == 0)
                            ? 3600
                            : dailyTotals.values.reduce(
                                (a, b) => a > b ? a : b,
                              );

                        final ratio = (seconds / maxSeconds).clamp(0.0, 1.0);
                        final dayLabel = [
                          "Mon",
                          "Tue",
                          "Wed",
                          "Thu",
                          "Fri",
                          "Sat",
                          "Sun",
                        ][date.weekday - 1];

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 35,
                                child: Text(
                                  dayLabel,
                                  style: const TextStyle(color: Colors.white38),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 500),
                                    alignment: Alignment.centerLeft,
                                    widthFactor: ratio,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: ratio > 0.8
                                            ? activeColor
                                            : activeColor.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 50,
                                child: Text(
                                  formatTotalTime(seconds),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white24,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 48),

                      const Text(
                        "FOCUS HISTORY",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FocusHeatmap(dataset: heatmapData),

                            const SizedBox(height: 12),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  "Less",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(width: 6),

                                ...[0, 10, 30, 60].map((v) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _heatColor(v, activeColor),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  );
                                }),

                                const SizedBox(width: 6),

                                const Text(
                                  "More",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.emoji_events, color: activeColor),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Longest Focus Session",
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  "${SessionStore.sessions.isEmpty ? 0 : SessionStore.sessions.map((s) => s.durationSeconds).reduce((a, b) => a > b ? a : b) ~/ 60} minutes",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Text(
                        "FOCUS TREND",
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      FocusChart(data: stats_utils.getLast7DaysFocus()),

                      const SizedBox(height: 40),

                      const SizedBox(height: 60),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
