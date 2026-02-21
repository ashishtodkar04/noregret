import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule_block.dart';

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
    _syncAndNotify();
  }

  static Future<void> deleteBlock(String id) async {
    _storage.remove(id);
    _syncAndNotify();
  }

  // Re-routing for consistency
  static Future<void> removeDailyBlock(String id) async => await deleteBlock(id);

  // --- RUNTIME CACHING ---

  static List<ScheduleBlock> get todayBlocks {
    final now = DateTime.now();
    // If date changed since last access, refresh cache
    if (_currentDay == null || _currentDay!.day != now.day) {
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
    // Final chain: Persist to disk -> Notify UI
    _persist().then((_) {
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
    for (var b in todayBlocks) { minutes += b.duration; }
    return minutes / 60.0;
  }

  static int get totalBlocksCount => todayBlocks.length;
}