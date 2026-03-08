import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_block.dart';
import 'notification_service.dart';
import 'package:uuid/uuid.dart';
import '../core/task_store.dart';
import '../models/task_model.dart';

class ScheduleStore {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static final Map<String, ScheduleBlock> _storage = {};
  static final ValueNotifier<int> tick = ValueNotifier(0);

  static DateTime? _currentDay;
  static List<ScheduleBlock> _todayCache = [];

  // --- PERSISTENCE ENGINE ---

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('user_schedule_v1');

      if (data != null) {
        final Map<String, dynamic> decoded = json.decode(data);
        _storage.clear();
        decoded.forEach((key, value) {
          _storage[key] = ScheduleBlock.fromMap(value);
        });
        debugPrint("ScheduleStore: Loaded ${_storage.length} blocks.");
      }
    } catch (e) {
      debugPrint("ScheduleStore Load Error: $e");
    }
    _initialized = true;
    _syncAndNotify();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toEncode = {};
      _storage.forEach((key, block) {
        toEncode[key] = block.toMap();
      });
      final jsonString = json.encode(toEncode);
      await prefs.setString('user_schedule_v1', jsonString);
    } catch (e) {
      debugPrint("ScheduleStore Save Error: $e");
    }
  }

  // --- CORE LOGIC ---

  static List<ScheduleBlock> get dailyBlocks {
    final blocks = _storage.values.toList();
    // Sort chronologically by start time
    blocks.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return blocks;
  }

  static Future<void> saveBlock(ScheduleBlock block) async {
    _storage[block.id] = block;

    // AUTO CREATE TASK IF NOT EXISTS
    final normalizedTitle = block.title.trim().toLowerCase();

    bool taskExists = TaskStore.tasks.any(
      (t) => t.title.trim().toLowerCase() == normalizedTitle,
    );

    if (!taskExists) {
      final task = Task(
        id: const Uuid().v4(),
        title: block.title,
        isDaily: false,
      );

      TaskStore.addTask(task);
    }

    _syncAndNotify();
  }

  static Future<void> deleteBlock(String id) async {
    _storage.remove(id);
    _syncAndNotify();
  }

  // Re-routing for consistency
  static Future<void> removeDailyBlock(String id) async {
    final block = _storage[id];

    if (block != null) {
      final normalizedTitle = block.title.trim().toLowerCase();

      try {
        final task = TaskStore.tasks.firstWhere(
          (t) => t.title.trim().toLowerCase() == normalizedTitle,
        );

        TaskStore.delete(task.id);
      } catch (_) {}
    }

    _storage.remove(id);

    _syncAndNotify();
  }

  // --- RUNTIME CACHING ---

  static List<ScheduleBlock> get todayBlocks {
    final now = DateTime.now();
    // If date changed since last access, refresh cache
    if (_currentDay == null ||
        _currentDay!.year != now.year ||
        _currentDay!.month != now.month ||
        _currentDay!.day != now.day) {
      _currentDay = now;
      _rebuildCache();
    }
    return _todayCache;
  }

  static void _rebuildCache() {
    // We map stored blueprints to the actual current date
    _todayCache = dailyBlocks.map((b) => b.copyForToday()).toList();
  }

  static void _syncAndNotify() {
    _rebuildCache();

    _persist().then((_) async {
      // 🔔 Schedule notifications for today's blocks
      await NotificationService.scheduleScheduleReminders();

      tick.value++;
    });
  }

  // --- ANALYTICS & STATE ---

  static ScheduleBlock? currentBlock() {
    final nowTime = TimeOfDay.now();
    final totalMinutes = nowTime.hour * 60 + nowTime.minute;

    for (var b in todayBlocks) {
      if (totalMinutes >= b.startMinutes && totalMinutes < b.endMinutes) {
        return b;
      }
    }
    return null;
  }

  static ScheduleBlock? get activeBlock => currentBlock();

  static double get totalPlannedHours {
    int minutes = 0;
    for (var b in todayBlocks) {
      minutes += b.duration;
    }
    return minutes / 60.0;
  }

  static int get totalBlocksCount => todayBlocks.length;
}
