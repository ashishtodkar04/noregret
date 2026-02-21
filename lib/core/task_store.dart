import '../models/task_model.dart';
import 'package:flutter/foundation.dart';

class TaskStore {
  // 1. FIX: Flag to satisfy CalendarService and AIStore
  // Since we are using in-memory storage, this is always true once the app starts.
  static bool get isInitialized => true;

  // In-memory storage replacing Hive
  static final Map<String, Task> _storage = {};

  /// Source for UI lists, sorted by newest first
  static List<Task> get tasks =>
      _storage.values.toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  /// Specialized getter for Dashboard to handle Calendar visibility and Daily tasks
  static List<Task> get todayAndCalendarTasks {
    final now = DateTime.now();
    return tasks.where((t) {
      // Show if it's a daily task
      if (t.isDaily) return true;
      
      // Show if it was created today
      if (t.createdDate.year == now.year && 
          t.createdDate.month == now.month && 
          t.createdDate.day == now.day) return true;
          
      // Show if it is a Google Calendar event (identifiable by the emoji)
      if (t.title.startsWith("📅")) return true;
      
      return false;
    }).toList();
  }

  // 2. FIX: Added pendingTaskCount for the AIStore logic
  static int get pendingTaskCount => tasks.where((t) => !t.isCompleted).length;

  /// Global notifier to refresh Dashboard, Stats, and WeeklyFocusWidget
  static final ValueNotifier<int> tick = ValueNotifier(0);

  // --- CORE LOGIC ---

  static void toggleTaskCompletion(String id, {String? customDateKey}) {
    final task = _storage[id];
    if (task == null) return;

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";
    final dateKey = customDateKey ?? todayKey;

    final List<String> history = List<String>.from(task.completionHistory);

    if (history.contains(dateKey)) {
      history.remove(dateKey);
      if (dateKey == todayKey) {
        task.isCompleted = false;
      }
    } else {
      history.add(dateKey);
      if (dateKey == todayKey) {
        task.isCompleted = true;
        task.isRunning = false; // Kill timer on completion
      }
    }

    task.completionHistory = history;
    notify();
  }

  /// Explicitly marks a task done. Used by the SessionStore auto-completion.
  static void markCompletedToday(String id) {
    final task = _storage[id];
    if (task == null) return;

    final todayKey =
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";

    if (!task.completionHistory.contains(todayKey)) {
      toggleTaskCompletion(id);
    }
  }

  // --- TASK MANAGEMENT ---

  static void addTask(Task task) {
    _storage[task.id] = task;
    notify();
  }

  static void delete(String id) {
    _storage.remove(id);
    notify();
  }

  static void update(Task task) {
    _storage[task.id] = task;
    notify();
  }

  // --- GOOGLE CALENDAR SYNC HELPERS ---

  /// Safely removes only tasks imported from Google Calendar
  static void clearGoogleTasks() {
    final googleTaskIds = _storage.values
        .where((t) => t.title.startsWith("📅"))
        .map((t) => t.id)
        .toList();

    for (var id in googleTaskIds) {
      _storage.remove(id);
    }

    notify();
  }

  // --- AUTOMATION & CONTROL ---

  /// Resets UI state for 'Daily' tasks at midnight.
  static void refreshForToday() {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    bool changed = false;

    for (final task in _storage.values) {
      if (task.isDaily && task.createdDate.isBefore(todayMidnight)) {
        task
          ..createdDate = now
          ..isCompleted = false
          ..isSkipped = false
          ..isRunning = false;

        changed = true;
      }
    }

    if (changed) notify();
  }

  /// Ensures only one task is 'Running' at a time
  static void startTask(String id) {
    for (final task in _storage.values) {
      final shouldRun = task.id == id;
      if (task.isRunning != shouldRun) {
        task.isRunning = shouldRun;
      }
    }
    notify();
  }

  static void stopTask(String id) {
    final task = _storage[id];
    if (task != null && task.isRunning) {
      task.isRunning = false;
      notify();
    }
  }

  /// Helper to trigger the global UI listener
  static void notify() {
    tick.value++;
  }
}