import 'package:flutter/material.dart';
import '../core/task_store.dart';
import '../models/task_model.dart';
import '../main.dart'; // for appSettings

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _focusEnabled = true;
  bool _isDaily = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTask() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    final task = Task(
      id: 'task_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      focusEnabled: _focusEnabled,
      isDaily: _isDaily,
    );

    TaskStore.addTask(task);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isGhostMode = appSettings.ghostMode;
    final Color activeColor = Theme.of(context).primaryColor;
    final canSave = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isGhostMode ? "NEW ENTRY" : "NEW MISSION",
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGhostMode ? "DATA_POINT" : "OBJECTIVE",
              style: TextStyle(
                color: activeColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization:
                  TextCapitalization.sentences,
              onSubmitted: (_) => _addTask(),
              onChanged: (_) => setState(() {}),
              cursorColor: activeColor,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                hintText: isGhostMode
                    ? "Input objective..."
                    : "Enter mission name...",
                border: InputBorder.none,
                hintStyle: TextStyle(
                    color:
                        Colors.white.withOpacity(0.05)),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              width: 60,
              color: activeColor.withOpacity(0.5),
            ),
            const SizedBox(height: 40),
            const Text(
              "CONFIGURATION",
              style: TextStyle(
                color: Colors.white24,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _TaskOptionTile(
              title:
                  isGhostMode ? "DEEP WORK" : "FOCUS MODE",
              subtitle: isGhostMode
                  ? "Apply logic restrictions"
                  : "Enable deep work protocol",
              icon: isGhostMode
                  ? Icons.visibility_off_outlined
                  : Icons.bolt_rounded,
              value: _focusEnabled,
              activeColor: activeColor,
              onChanged: (val) =>
                  setState(() => _focusEnabled = val),
            ),
            const SizedBox(height: 12),
            _TaskOptionTile(
              title:
                  isGhostMode ? "RECURRING" : "DAILY GOAL",
              subtitle: "Repeat every 24 hours",
              icon: Icons.history_rounded,
              value: _isDaily,
              activeColor: activeColor,
              onChanged: (val) =>
                  setState(() => _isDaily = val),
            ),
            const SizedBox(height: 60),
            AnimatedScale(
              scale: canSave ? 1.0 : 0.98,
              duration:
                  const Duration(milliseconds: 200),
              child: Opacity(
                opacity: canSave ? 1.0 : 0.5,
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                    onPressed:
                        canSave ? _addTask : null,
                    child: Text(
                      isGhostMode
                          ? "CONFIRM_ENTRY"
                          : "INITIALIZE MISSION",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _TaskOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: value
            ? activeColor.withOpacity(0.05)
            : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? activeColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 8),
        child: SwitchListTile(
          secondary: Container(
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: value
                  ? activeColor
                  : Colors.white
                      .withOpacity(0.05),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: value
                  ? Colors.black
                  : Colors.white38,
            ),
          ),
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor,
          activeTrackColor:
              activeColor.withOpacity(0.2),
          inactiveTrackColor:
              Colors.white10,
          title: Text(
            title,
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
              fontSize: 13,
              letterSpacing: 0.5,
              color: value
                  ? Colors.white
                  : Colors.white60,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
                fontSize: 11,
                color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
