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
  Timer? _timer;
  int _sessionStartSeconds = 0;
  int _ticksSinceLastSave = 0; // Performance optimizer

  @override
  void initState() {
    super.initState();
    if (widget.task.isRunning) {
      _resumeTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resumeTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        widget.task.timeSpentInSeconds++;
        _ticksSinceLastSave++;
      });

      // UI update only
      TaskStore.notify();

      // SAVE TO DISK every 30 seconds to prevent lag
      if (_ticksSinceLastSave >= 30) {
        TaskStore.update(widget.task);
        _ticksSinceLastSave = 0;
      }
    });
  }

  void _startTimer() {
    if (_timer != null) return;

    _sessionStartSeconds = widget.task.timeSpentInSeconds;
    widget.task.isRunning = true;

    TaskStore.update(widget.task);
    _resumeTimer();
  }

  void _stopTimer() {
    if (_timer == null) return;

    _timer?.cancel();
    _timer = null;
    _ticksSinceLastSave = 0;

    setState(() {
      widget.task.isRunning = false;
    });

    final sessionSeconds =
        widget.task.timeSpentInSeconds - _sessionStartSeconds;

    if (sessionSeconds > 0) {
      SessionStore.addSession(sessionSeconds, taskTitle: widget.task.title);
      // NOTE: We don't record activity for the streak here,
      // we do it when the task is actually CHECKED as completed.
    }

    TaskStore.update(widget.task);
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

                        // Use the store method to ensure history & streaks are updated
                        TaskStore.toggleTaskCompletion(task.id);

                        if (val == true) {
                          HapticFeedback.mediumImpact();
                          StreakStore.recordActivity(); // Valid activity recorded
                        } else {
                          HapticFeedback.selectionClick();
                        }

                        // Call parent callback if needed
                        widget.onToggle();
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
                    _formatTime(task.timeSpentInSeconds),
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
                          HapticFeedback.lightImpact();
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

// _PulseDot code remains the same as your previous snippet...
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
