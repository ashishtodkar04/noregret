import 'package:flutter/material.dart';
import '../core/time_utils.dart';
import '../core/task_store.dart';
import '../core/session_store.dart';
import '../core/streak_store.dart';
import '../widgets/task_card.dart';
import '../widgets/daily_quote_card.dart';
import '../models/task_model.dart';
import 'add_task_screen.dart';
import 'stats_screen.dart';
import 'timetable_screen.dart';
import '../screens/ai_screen.dart';
import '../core/calendar_service.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    TaskStore.refreshForToday();
  }

  int _calculateTotalXP() {
    final sessions = SessionStore.todaySessions;
    if (sessions.isEmpty) return 0;
    return sessions.fold(0, (sum, s) => sum + (s.durationSeconds ~/ 60) * 10);
  }

  String _getRankTitle(int xp) {
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

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      // Clear existing calendar tasks to ensure fresh data
      TaskStore.clearGoogleTasks();
      await CalendarService.syncGoogleTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Calendar Synced Successfully"),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sync Error: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _navTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Theme.of(context).primaryColor;

    return ValueListenableBuilder(
      valueListenable: TaskStore.tick,
      builder: (context, _, __) {
        final List<Task> allTasks = TaskStore.tasks;
        final int totalXP = _calculateTotalXP();
        final String rankTitle = _getRankTitle(totalXP);
        final double rankProgress = _getRankProgress(totalXP);

        // Filter 1: Yesterday's Debt
        final yesterdayUnfinished = allTasks
            .where((t) => !t.isCompleted && !t.isDaily && t.isFromYesterday)
            .toList();

        // Filter 2: Today's Missions (Uses the new centralized TaskStore filter)
        final todayTasks = TaskStore.todayAndCalendarTasks.where((t) {
          // If completed, only show if it was finished TODAY
          if (t.isCompleted) {
            final todayKey =
                "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
            return t.completionHistory.contains(todayKey);
          }
          return true; // Keep all active tasks returned by the store
        }).toList();

        final bool isLocked = yesterdayUnfinished.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "NO REGRET",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  rankTitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.black,
            actions: [
              if (_isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: Icon(Icons.sync_rounded, color: activeColor),
                  onPressed: _handleSync,
                ),
              IconButton(
                icon: const Icon(Icons.insights_rounded),
                onPressed: () => _navTo(const StatsScreen()),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => _navTo(const ProfileScreen()),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            children: [
              _OverviewHeader(
                allTasks: allTasks,
                totalXP: totalXP,
                rankProgress: rankProgress,
                isGhostMode: false,
              ),
              const _StreakBanner(),
              if (isLocked) ...[
                _SectionHeader(
                  title: "YESTERDAY'S DEBT",
                  trailing: "RESOLVE TO UNLOCK",
                  icon: Icons.history_toggle_off_rounded,
                  color: activeColor,
                ),
                ...yesterdayUnfinished.map(
                  (t) => TaskCard(
                    task: t,
                    onToggle: () => TaskStore.toggleTaskCompletion(t.id),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              _SectionHeader(
                title: "TODAY'S MISSION",
                icon: isLocked
                    ? Icons.lock_outline_rounded
                    : Icons.flash_on_rounded,
                trailing: isLocked ? "LOCKED" : "${todayTasks.length} ACTIVE",
                color: activeColor,
              ),
              const DailyQuoteCard(),
              const SizedBox(height: 16),
              if (!isLocked && todayTasks.isEmpty)
                const _EmptyState()
              else
                ...todayTasks.map(
                  (t) => Opacity(
                    opacity: isLocked ? 0.3 : 1.0,
                    child: IgnorePointer(
                      ignoring: isLocked,
                      child: TaskCard(
                        task: t,
                        onToggle: () => TaskStore.toggleTaskCompletion(t.id),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 140),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "ai_btn",
                backgroundColor: activeColor,
                mini: true,
                onPressed: () => _navTo(const AIScreen()),
                child: const Icon(Icons.bolt_rounded, color: Colors.black),
              ),
              const SizedBox(height: 14),
              FloatingActionButton.extended(
                onPressed: isLocked
                    ? null
                    : () => _navTo(const AddTaskScreen()),
                backgroundColor: isLocked
                    ? const Color(0xFF1A1A1A)
                    : activeColor,
                label: Text(
                  isLocked ? "DEBT DETECTED" : "NEW MISSION",
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                icon: Icon(
                  isLocked ? Icons.lock_clock_rounded : Icons.add_rounded,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final List<Task> allTasks;
  final int totalXP;
  final double rankProgress;
  final bool isGhostMode;

  const _OverviewHeader({
    required this.allTasks,
    required this.totalXP,
    required this.rankProgress,
    required this.isGhostMode,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month}-${now.day}";
    final Color activeColor = Theme.of(context).primaryColor;

    final doneToday = allTasks
        .where((t) => t.completionHistory.contains(dateKey))
        .length;

    final focusSeconds = SessionStore.todayTotalSeconds;
    final sessionCount = SessionStore.todaySessions.length;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: "COMPLETED",
                value: "$doneToday",
                color: isGhostMode ? Colors.white70 : Colors.greenAccent,
              ),
              _Stat(
                label: "FOCUS TIME",
                value: formatTotalTime(focusSeconds),
                color: activeColor,
              ),
              _Stat(
                label: "SESSIONS",
                value: "$sessionCount",
                color: isGhostMode ? Colors.white70 : Colors.blueAccent,
              ),
            ],
          ),
          if (!isGhostMode) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  "$totalXP XP",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: rankProgress,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      color: activeColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.military_tech_rounded, size: 18, color: activeColor),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.white38,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner();

  @override
  Widget build(BuildContext context) {
    final streak = StreakStore.streak;

    if (streak.currentStreak == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: Theme.of(context).primaryColor,
            size: 26,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${streak.currentStreak} DAY STREAK",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                "UNSTOPPABLE MOMENTUM",
                style: TextStyle(fontSize: 9, color: Colors.white24),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final IconData? icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailing!,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.radio_button_off_rounded,
              color: Colors.white10,
              size: 50,
            ),
            SizedBox(height: 16),
            Text(
              "NO MISSIONS REMAINING",
              style: TextStyle(
                color: Colors.white10,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
