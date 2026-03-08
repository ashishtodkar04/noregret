import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../core/streak_store.dart';
import '../screens/focus_screen.dart';
import '../core/task_store.dart';
import '../core/session_store.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;

  const TaskCard({super.key, required this.task, required this.onToggle});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();

    if (widget.task.isRunning) {
      _startUITimer();
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  void _startUITimer() {
    _uiTimer?.cancel();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _startTimer() {
    TaskStore.startTask(widget.task.id);
    _startUITimer();
    HapticFeedback.lightImpact();
  }

  void _stopTimer() {
    TaskStore.stopTask(widget.task.id);
    _uiTimer?.cancel();
    _uiTimer = null;
    HapticFeedback.lightImpact();
  }

  int _getLiveSeconds(Task task) {
    if (!task.isRunning || task.startedAt == null) {
      return task.timeSpentInSeconds;
    }

    final diff = DateTime.now().difference(task.startedAt!).inSeconds;

    return task.timeSpentInSeconds + diff;
  }

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    if (h > 0) return '${h}h ${m}m';

    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    final liveSeconds = _getLiveSeconds(task);

    final isInactive = task.isCompleted || task.isSkipped;

    return AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: task.isRunning ? 1.02 : (task.isCompleted ? 0.95 : 1.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isInactive ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: task.isRunning
                ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Card(
            elevation: task.isRunning ? 4 : 0,
            color: task.isRunning ? Colors.grey[900] : Colors.black12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: task.isRunning
                    ? Colors.orange.withOpacity(0.5)
                    : Colors.white10,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),

              /// ✅ FIXED CHECKBOX
              leading: Checkbox(
                activeColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                value: task.isCompleted,
                onChanged: task.isSkipped
                    ? null
                    : (val) {
                        if (task.isRunning) _stopTimer();

                        /// Only call parent toggle
                        widget.onToggle();

                        if (val == true) {
                          HapticFeedback.mediumImpact();
                          StreakStore.recordActivity();
                        } else {
                          HapticFeedback.selectionClick();
                        }
                      },
              ),

              title: Text(
                task.title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: task.isRunning
                      ? FontWeight.bold
                      : FontWeight.normal,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor: Colors.orange,
                ),
              ),

              subtitle: Row(
                children: [
                  Text(
                    _formatTime(liveSeconds),
                    style: TextStyle(
                      color: task.isRunning ? Colors.orange : Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  if (task.isRunning) ...[
                    const SizedBox(width: 8),
                    const _PulseDot(),
                  ],
                ],
              ),

              /// ▶ / ⏸ PLAY PAUSE BUTTON
              trailing: IconButton(
                icon: Icon(
                  task.isRunning
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: task.isSkipped
                      ? Colors.white10
                      : (task.isRunning ? Colors.orange : Colors.white70),
                  size: 32,
                ),
                onPressed: (task.isSkipped || task.isCompleted)
                    ? null
                    : () {
                        if (task.focusEnabled) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FocusScreen(task: task),
                            ),
                          );
                        } else {
                          task.isRunning ? _stopTimer() : _startTimer();
                        }
                      },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Icon(Icons.circle, size: 6, color: Colors.orange),
    );
  }
}
