import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';

class TaskStore {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static final Map<String, Task> _storage = {};

  static final ValueNotifier<int> tick = ValueNotifier(0);

  // ---------------- DATE HELPER ----------------

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return "$y-$m-$d";
  }

  // ---------------- DAILY REFRESH ----------------

  static void refreshForToday() {
    final todayKey = _todayKey();
    bool changed = false;

    for (var task in _storage.values) {
      if (!task.isDaily) continue;

      bool completedToday = task.completionHistory.contains(todayKey);

      if (completedToday && !task.isCompleted) {
        task.isCompleted = true;
        changed = true;
      }

      if (!completedToday && task.isCompleted) {
        task.isCompleted = false;
        task.isRunning = false;
        task.startedAt = null;
        changed = true;
      }
    }

    if (changed) {
      _persist();
      notify();
    }
  }

  // ---------------- INIT ----------------

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

  // ---------------- SAVE ----------------

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

  // ---------------- GETTERS ----------------

  static List<Task> get tasks =>
      _storage.values.toList()
        ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

  static List<Task> get todayAndCalendarTasks {
    final now = DateTime.now();

    return tasks.where((t) {
      if (t.isDaily) return true;

      if (t.title.startsWith("📅")) return true;

      if (t.createdDate.year == now.year &&
          t.createdDate.month == now.month &&
          t.createdDate.day == now.day) {
        return true;
      }

      return false;
    }).toList();
  }

  static int get pendingTaskCount => tasks.where((t) => !t.isCompleted).length;

  // ---------------- CORE LOGIC ----------------

  static void toggleTaskCompletion(String id, {String? customDateKey}) {
    final task = _storage[id];
    if (task == null) return;

    final todayKey = _todayKey();
    final dateKey = customDateKey ?? todayKey;

    if (task.completionHistory.contains(dateKey)) {
      // undo completion
      task.completionHistory.remove(dateKey);

      if (dateKey == todayKey) {
        task.isCompleted = false;
      }
    } else {
      // mark completed
      task.completionHistory.add(dateKey);

      if (dateKey == todayKey) {
        task.isCompleted = true;
        task.isRunning = false;
        task.startedAt = null;
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

    final todayKey = _todayKey();

    if (!task.completionHistory.contains(todayKey)) {
      task.completionHistory.add(todayKey);
    }

    task.isCompleted = true;
    task.isRunning = false;
    task.startedAt = null;

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

      _persist();
      notify();
    }
  }

  // ---------------- TIMER ENGINE ----------------

  static void startTask(String id) {
    final now = DateTime.now();

    for (final task in _storage.values) {
      if (task.id == id) {
        task.isRunning = true;
        task.startedAt = now;
      } else {
        task.isRunning = false;
        task.startedAt = null;
      }
    }

    _persist();
    notify();
  }

  static void stopTask(String id) {
    final task = _storage[id];

    if (task == null || !task.isRunning) return;

    final now = DateTime.now();

    if (task.startedAt != null) {
      final seconds = now.difference(task.startedAt!).inSeconds;
      task.timeSpentInSeconds += seconds;
    }

    task.startedAt = null;
    task.isRunning = false;

    _persist();
    notify();
  }

  // ---------------- UI UPDATE ----------------

  static void notify() {
    tick.value++;
  }
}
