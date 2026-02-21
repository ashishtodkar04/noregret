import 'package:flutter/material.dart';
import '../core/session_store.dart';
import '../core/streak_store.dart';
import '../core/task_store.dart';
import '../main.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  int _calculateTotalXP() {
    final sessions = SessionStore.sessions;
    if (sessions.isEmpty) return 0;

    return sessions.fold(
      0,
      (sum, s) =>
          sum + (s.durationMinutes * (s.focusScore / 10)).toInt(),
    );
  }

  String _getRank(int xp) {
    if (xp > 10000) return "VOID WALKER";
    if (xp > 5000) return "WAR ROOM LEGEND";
    if (xp > 2000) return "DEEP KNIGHT";
    return "NOVICE MONK";
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode = appSettings.ghostMode;
        final Color activeColor =
            Theme.of(context).primaryColor;

        final int totalXP = _calculateTotalXP();
        final String rank = _getRank(totalXP);
        final int streak =
            StreakStore.currentStreak;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme:
                const IconThemeData(color: Colors.white70),
            title: const Text(
              "SERVICE_RECORD",
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 14,
                letterSpacing: 3,
                color: Colors.white70,
              ),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (!isGhostMode) ...[
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: activeColor,
                              width: 2),
                        ),
                        child:
                            const CircleAvatar(
                          radius: 50,
                          backgroundColor:
                              Color(0xFF111111),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rank,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w900,
                          color: activeColor,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        "$totalXP TOTAL XP",
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding:
                      const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: activeColor
                        .withOpacity(0.05),
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                        color: activeColor
                            .withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.visibility_off_rounded,
                        color: activeColor,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "GHOST_MODE_ACTIVE",
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight:
                              FontWeight.bold,
                          letterSpacing:
                              2,
                        ),
                      ),
                      const Text(
                        "Distractions suppressed. Focus on the mission.",
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),

              Row(
                children: [
                  _ExpandedStatCard(
                    label: "CURRENT_STREAK",
                    value: "$streak DAYS",
                    icon: Icons.whatshot,
                    color: activeColor,
                  ),
                  const SizedBox(width: 12),
                  _ExpandedStatCard(
                    label: "TASKS_KILLED",
                    value: "${TaskStore.tasks.length}",
                    icon: Icons.check_circle_outline,
                    color: activeColor,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              if (!isGhostMode) ...[
                const _SectionLabel(label: "HONOR_ROLL"),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      _Medal(
                          icon: Icons.wb_sunny_outlined,
                          label: "Early Bird",
                          color: Colors.yellow),
                      _Medal(
                          icon: Icons.nightlight_round,
                          label: "Night Owl",
                          color: Colors.purpleAccent),
                      _Medal(
                          icon: Icons.anchor,
                          label: "Deep Diver",
                          color: Colors.blueAccent),
                      _Medal(
                          icon: Icons.auto_awesome,
                          label: "Unstoppable",
                          color: Colors.orangeAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              const _SectionLabel(label: "SYSTEM_CONTROLS"),
              const SizedBox(height: 12),

              _SettingsToggle(
                label: "GHOST_MODE",
                value: isGhostMode,
                activeColor: activeColor,
                onChanged: (_) =>
                    appSettings.toggleGhostMode(),
              ),

              const SizedBox(height: 20),

              TextButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.delete_forever,
                  color: Colors.redAccent,
                  size: 18,
                ),
                label: const Text(
                  "WIPE_ALL_DATA",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

/* -------------------- SUPPORT WIDGETS -------------------- */

class _ExpandedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ExpandedStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
        color: Colors.white38,
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: activeColor,
      title: Text(label,
          style: const TextStyle(color: Colors.white)),
    );
  }
}

class _Medal extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Medal({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70)),
        ],
      ),
    );
  }
}
