import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/schedule_store.dart';
import '../models/schedule_block.dart';
import '../main.dart'; // <-- For appSettings

class AddScheduleScreen extends StatefulWidget {
  final ScheduleBlock? editBlock;

  const AddScheduleScreen({super.key, this.editBlock});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    if (widget.editBlock != null) {
      final b = widget.editBlock!;
      _titleController.text = b.title;
      _start = b.start;
      _end = b.end;
    } else {
      _start = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _updateStartTime(TimeOfDay result) {
    setState(() {
      _start = result;
      final startMin = result.hour * 60 + result.minute;
      final endMin =
          _end != null ? (_end!.hour * 60 + _end!.minute) : 0;

      if (_end == null || endMin <= startMin) {
        final now =
            DateTime(2026, 1, 1, result.hour, result.minute);
        final suggestEnd =
            now.add(const Duration(minutes: 30));
        _end = TimeOfDay(
            hour: suggestEnd.hour,
            minute: suggestEnd.minute);
      }
    });
  }

  Future<void> _pickTime(
      {required bool isStart,
      required Color activeColor}) async {
    final result = await showTimePicker(
      context: context,
      initialTime:
          (isStart ? _start : _end) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: activeColor,
              onPrimary: Colors.black,
              surface: const Color(0xFF111111),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      isStart
          ? _updateStartTime(result)
          : setState(() => _end = result);
    }
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _start == null || _end == null) {
      return;
    }

    final startMin =
        _start!.hour * 60 + _start!.minute;
    final endMin =
        _end!.hour * 60 + _end!.minute;

    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "End time must be after start time",
            style:
                TextStyle(fontWeight: FontWeight.bold),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final block = ScheduleBlock(
      id: widget.editBlock?.id ??
          const Uuid().v4(),
      title: title,
      startMinutes: startMin,
      endMinutes: endMin,
      isCompleted:
          widget.editBlock?.isCompleted ?? false,
    );

    ScheduleStore.saveBlock(block);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isGhostMode =
        appSettings.ghostMode; // <-- replaced Hive
    final Color activeColor =
        Theme.of(context).primaryColor;

    final isValid =
        _titleController.text.trim().isNotEmpty &&
            _start != null &&
            _end != null;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editBlock == null
              ? (isGhostMode
                  ? "NEW_PROTOCOL"
                  : "NEW PLAN")
              : (isGhostMode
                  ? "EDIT_LOG"
                  : "EDIT PLAN"),
          style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 14,
              color: Colors.white70),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              isGhostMode
                  ? "LOG_IDENTIFIER"
                  : "TASK IDENTIFIER",
              style: TextStyle(
                  color: activeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              autofocus:
                  widget.editBlock == null,
              cursorColor: activeColor,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white),
              decoration: InputDecoration(
                hintText: isGhostMode
                    ? "Define objective..."
                    : "Enter objective...",
                hintStyle: TextStyle(
                    color:
                        Colors.white.withOpacity(0.05)),
                border: InputBorder.none,
              ),
              onChanged: (_) =>
                  setState(() {}),
            ),
            Container(
                height: 1,
                width: 60,
                color:
                    activeColor.withOpacity(0.5)),
            const SizedBox(height: 48),
            const Text(
              "TIME ALLOCATION",
              style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _TimePickerButton(
                  label: isGhostMode
                      ? "START_LOG"
                      : "DEPLOYMENT",
                  time: _start,
                  activeColor: activeColor,
                  onTap: () => _pickTime(
                      isStart: true,
                      activeColor:
                          activeColor),
                ),
                const SizedBox(width: 16),
                _TimePickerButton(
                  label: isGhostMode
                      ? "END_LOG"
                      : "EXTRACTION",
                  time: _end,
                  activeColor: activeColor,
                  onTap: () => _pickTime(
                      isStart: false,
                      activeColor:
                          activeColor),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor:
                      Colors.black,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            20),
                  ),
                ),
                onPressed:
                    isValid ? _save : null,
                child: Text(
                  widget.editBlock == null
                      ? (isGhostMode
                          ? "INITIALIZE_TIMELINE"
                          : "INITIALIZE TIMELINE")
                      : (isGhostMode
                          ? "UPDATE_LOG"
                          : "RE-MAP PLAN"),
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final Color activeColor;
  final VoidCallback onTap;

  const _TimePickerButton({
    required this.label,
    required this.time,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                const Color(0xFF111111),
            borderRadius:
                BorderRadius.circular(
                    20),
            border: Border.all(
                color: Colors.white
                    .withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Colors.white38,
                      letterSpacing: 1)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                      Icons
                          .access_time_filled_rounded,
                      size: 14,
                      color:
                          activeColor),
                  const SizedBox(
                      width: 8),
                  Text(
                    time?.format(
                            context) ??
                        "--:--",
                    style:
                        const TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
