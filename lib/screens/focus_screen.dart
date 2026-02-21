import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/task_model.dart';
import '../core/streak_store.dart';
import '../core/task_store.dart';
import '../core/session_store.dart';
import '../core/ai_store.dart';
import '../main.dart';

class FocusScreen extends StatefulWidget {
  final Task task;
  const FocusScreen({super.key, required this.task});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  Timer? _timer;
  bool _isRunning = false;
  bool _isBreak = false;

  static const int focusDuration = 25 * 60;
  static const int breakDuration = 5 * 60;

  int _sessionSecondsLeft = focusDuration;
  late int _initialTaskSeconds;
  int _distractions = 0;
  int _ticksSinceLastSave = 0; // Performance optimizer

  @override
  void initState() {
    super.initState();
    _initialTaskSeconds = widget.task.timeSpentInSeconds;
    _startTimer();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_sessionSecondsLeft > 0) {
        setState(() {
          _sessionSecondsLeft--;
          if (!_isBreak) {
            widget.task.timeSpentInSeconds++;
            _ticksSinceLastSave++;

            // Auto-save progress to disk every 30 seconds to prevent data loss
            if (_ticksSinceLastSave >= 30) {
              TaskStore.update(widget.task);
              _ticksSinceLastSave = 0;
            }
            TaskStore.notify();
          }
        });
      } else {
        _switchSession();
      }
    });
  }

  void _switchSession() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _isBreak = !_isBreak;
      _sessionSecondsLeft = _isBreak ? breakDuration : focusDuration;
    });
    // Auto-save on session switch
    TaskStore.update(widget.task);
    _startTimer();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      TaskStore.update(widget.task); // Save when pausing
      setState(() => _isRunning = false);
    } else {
      _startTimer();
    }
  }

  void _logDistraction() {
    HapticFeedback.vibrate();
    setState(() => _distractions++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "DISTRACTION LOGGED. STAY FOCUSED.",
          style: TextStyle(
            fontFamily: 'Monospace',
            fontSize: 10,
            color: Colors.white,
          ),
        ),
        duration: Duration(milliseconds: 800),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _finish(Color activeColor) {
    _timer?.cancel();
    setState(() => _isRunning = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GatekeeperDialog(
        taskTitle: widget.task.title,
        activeColor: activeColor,
        onSuccess: () {
          _finalizeSession();
          Navigator.of(context).pop(); // Close Dialog
          Navigator.of(context).pop(); // Exit Focus Screen
        },
      ),
    );
  }

  void _finalizeSession() {
    final sessionTotal = widget.task.timeSpentInSeconds - _initialTaskSeconds;

    if (sessionTotal > 0) {
      // 1. Record the session in history
      SessionStore.addSession(
        sessionTotal,
        taskTitle: widget.task.title,
        distractions: _distractions,
      );

      // 2. Increment streak using our new logic
      StreakStore.recordActivity();

      // 3. Mark the task as completed if it's a "one-off" or update its state
      TaskStore.update(widget.task);
      TaskStore.notify();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode = appSettings.ghostMode;
        final Color activeColor = Theme.of(context).primaryColor;

        final minutes = _sessionSecondsLeft ~/ 60;
        final seconds = _sessionSecondsLeft % 60;
        final progress =
            1.0 -
            (_sessionSecondsLeft / (_isBreak ? breakDuration : focusDuration));

        return PopScope(
          canPop:
              false, // Force them to use the "Stop" button and face the Gatekeeper
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onLongPress:
                        _logDistraction, // Hidden feature: long press title to log distraction
                    child: Text(
                      isGhostMode
                          ? "MONITORING_ACTIVE: ${widget.task.title.toUpperCase()}"
                          : "ACTIVE_MISSION: ${widget.task.title.toUpperCase()}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white38,
                        letterSpacing: 2,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 280,
                        height: 280,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isBreak ? Colors.greenAccent : activeColor,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 72,
                              fontWeight: FontWeight.w100,
                              color: Colors.white,
                              fontFamily: 'Monospace',
                            ),
                          ),
                          Text(
                            _isBreak ? "RECOVERY" : "WORK",
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 4,
                              color: _isBreak
                                  ? Colors.greenAccent
                                  : activeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ActionButton(
                          icon: _isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          onTap: _toggleTimer,
                          color: Colors.white.withOpacity(0.05),
                        ),
                        _ActionButton(
                          icon: Icons.stop_rounded,
                          onTap: () => _finish(activeColor),
                          color: Colors.redAccent.withOpacity(0.1),
                          iconColor: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ... GatekeeperDialog and _ActionButton remain largely the same,
// just ensure GatekeeperDialog handles the onSuccess correctly.

class GatekeeperDialog extends StatefulWidget {
  final String taskTitle;
  final Color activeColor;
  final VoidCallback onSuccess;

  const GatekeeperDialog({
    super.key,
    required this.taskTitle,
    required this.activeColor,
    required this.onSuccess,
  });

  @override
  State<GatekeeperDialog> createState() => _GatekeeperDialogState();
}

class _GatekeeperDialogState extends State<GatekeeperDialog> {
  final TextEditingController _inputController = TextEditingController();

  String? _quizQuestion;
  bool _isAwaitingTopic = true;
  bool _isGenerating = false;
  bool _isGrading = false;

  Future<void> _handleTopicSubmitted() async {
    if (_inputController.text.isEmpty) return;

    setState(() => _isGenerating = true);

    final question = await AIStore.generateGatekeeperQuiz(
      widget.taskTitle,
      _inputController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _quizQuestion = question;
      _isGenerating = false;
      _isAwaitingTopic = false;
      _inputController.clear();
    });
  }

  Future<void> _handleAnswerSubmitted() async {
    if (_inputController.text.isEmpty) return;

    setState(() => _isGrading = true);

    final passed = await AIStore.gradeAnswer(
      _quizQuestion!,
      _inputController.text,
    );

    if (!mounted) return;

    if (passed) {
      widget.onSuccess();
    } else {
      setState(() {
        _isGrading = false;
        _isAwaitingTopic = true;
        _inputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0D0D0D),
      title: Text(
        "GATEKEEPER PROTOCOL",
        style: TextStyle(
          color: widget.activeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: _isGenerating || _isGrading
          ? const CircularProgressIndicator()
          : _isAwaitingTopic
          ? TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                hintText: "What did you study?",
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarkdownBody(data: _quizQuestion ?? ""),
                TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(hintText: "Answer"),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isAwaitingTopic
              ? _handleTopicSubmitted
              : _handleAnswerSubmitted,
          child: const Text("SUBMIT"),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.color,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: Icon(icon, color: iconColor, size: 40),
      ),
    );
  }
}
