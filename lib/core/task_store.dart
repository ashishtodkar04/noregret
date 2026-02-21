import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskStore {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  // Internal storage using a Map for O(1) lookups
  static final Map<String, Task> _storage = {};

  /// Global notifier to refresh Dashboard, Stats, and Widgets
  static final ValueNotifier<int> tick = ValueNotifier(0);

  // --- PERSISTENCE ENGINE ---

  /// Resets daily tasks if they haven't been completed for the current date
  static void refreshForToday() {
    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    bool changed = false;
    // Corrected: Use _storage.values instead of _tasks list
    for (var task in _storage.values) {
      if (task.isDaily) {
        bool completedInHistory = task.completionHistory.contains(todayKey);
        
        if (completedInHistory && !task.isCompleted) {
          task.isCompleted = true;
          changed = true;
        } else if (!completedInHistory && task.isCompleted) {
          task.isCompleted = false;
          task.isRunning = false;
          changed = true;
        }
      }
    }

    if (changed) {
      _persist();
      notify();
    }
  }

  /// Initialize and load data from disk.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('noregret_tasks_v1');

      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        _storage.clear(); 
        decoded.forEach((key, value) {
          _storage[key] = Task.fromMap(value);
        });
      }
      debugPrint("TaskStore: Loaded ${_storage.length} tasks.");
    } catch (e) {
      debugPrint("TaskStore Load Error: $e");
    }

    _initialized = true;
    notify();
  }

  /// Saves current state to physical storage.
  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toEncode = {};
      _storage.forEach((key, task) {
        toEncode[key] = task.toMap();
      });
      await prefs.setString('noregret_tasks_v1', json.encode(toEncode));
    } catch (e) {
      debugPrint("TaskStore Save Error: $e");
    }
  }

  // --- GETTERS ---

  static List<Task> get tasks =>
      _storage.values.toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  static List<Task> get todayAndCalendarTasks {
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.isDaily) return true;
      if (t.createdDate.year == now.year &&
          t.createdDate.month == now.month &&
          t.createdDate.day == now.day)
        return true;
      if (t.title.startsWith("📅")) return true;
      return false;
    }).toList();
  }

  static int get pendingTaskCount => tasks.where((t) => !t.isCompleted).length;

  // --- CORE LOGIC ---

  static void toggleTaskCompletion(String id, {String? customDateKey}) {
    final task = _storage[id];
    if (task == null) return;

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";
    final dateKey = customDateKey ?? todayKey;

    if (task.completionHistory.contains(dateKey)) {
      task.completionHistory.remove(dateKey);
      if (dateKey == todayKey) task.isCompleted = false;
    } else {
      task.completionHistory.add(dateKey);
      if (dateKey == todayKey) {
        task.isCompleted = true;
        task.isRunning = false;
      }
    }

    _persist();
    notify();
  }

  static void markCompletedToday(dynamic taskOrId) {
    final Task? task = taskOrId is String
        ? _storage[taskOrId]
        : (taskOrId is Task ? taskOrId : null);
    if (task == null) return;

    final now = DateTime.now();
    final todayKey = "${now.year}-${now.month}-${now.day}";

    if (!task.completionHistory.contains(todayKey)) {
      task.completionHistory.add(todayKey);
    }
    task.isCompleted = true;
    task.isRunning = false;

    _persist();
    notify();
  }

  static void addTask(Task task) {
    _storage[task.id] = task;
    _persist();
    notify();
  }

  static void delete(String id) {
    _storage.remove(id);
    _persist();
    notify();
  }

  static void update(Task task) {
    _storage[task.id] = task;
    _persist();
    notify();
  }

  static void clearGoogleTasks() {
    _storage.removeWhere((key, t) => t.title.startsWith("📅"));
    _persist();
    notify();
  }

  static void updateTimeSpent(String id, int seconds) {
    final task = _storage[id];
    if (task != null) {
      task.timeSpentInSeconds = seconds;
      notify();
    }
  }

  static void startTask(String id) {
    for (final task in _storage.values) {
      task.isRunning = (task.id == id);
    }
    _persist();
    notify();
  }

  static void stopTask(String id) {
    final task = _storage[id];
    if (task != null && task.isRunning) {
      task.isRunning = false;
      _persist();
      notify();
    }
  }

  static void notify() {
    tick.value++;
  }
}