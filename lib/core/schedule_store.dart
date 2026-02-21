import 'package:flutter/material.dart';
import '../models/schedule_block.dart';

class ScheduleStore {
  // In-memory storage replacing Hive
  static final Map<String, ScheduleBlock> _storage = {};

  // Unified Notifier: Listen to this in your UI (ValueListenableBuilder)
  static final ValueNotifier<int> tick = ValueNotifier(0);

  static DateTime? _currentDay;
  static List<ScheduleBlock> _todayCache = [];

  // ===== PERSISTENCE (Now In-Memory) =====

  /// Gets all blocks, sorted by their start time
  static List<ScheduleBlock> get dailyBlocks {
    final blocks = _storage.values.toList();
    blocks.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return blocks;
  }

  /// Saves or updates a block
  static Future<void> saveBlock(ScheduleBlock block) async {
    _storage[block.id] = block;
    _syncAndNotify();
  }

  /// Deletes a block
  static Future<void> deleteBlock(String id) async {
    _storage.remove(id);
    _syncAndNotify();
  }

  /// Compatibility method for your Timetable Screen delete action
  static Future<void> removeDailyBlock(String id) async {
    await deleteBlock(id);
  }

  // ===== RUNTIME LOGIC & CACHING =====

  /// Returns the blocks for the current day, ensuring the cache is fresh
  static List<ScheduleBlock> get todayBlocks {
    final now = DateTime.now();

    if (_currentDay == null || _currentDay!.day != now.day) {
      _currentDay = now;
      _rebuildCache();
    }

    return _todayCache;
  }

  static void _rebuildCache() {
    _todayCache = dailyBlocks.map((b) => b.copyForToday()).toList();
  }

  /// Refreshes the cache and signals the UI to rebuild
  static void _syncAndNotify() {
    _rebuildCache();
    tick.value++;
  }

  // ===== UI HELPERS =====

  /// Returns the block currently happening based on system time
  static ScheduleBlock? currentBlock() {
    final now = TimeOfDay.now();
    final totalMinutes = now.hour * 60 + now.minute;

    try {
      return todayBlocks.firstWhere(
        (b) =>
            totalMinutes >= b.startMinutes &&
            totalMinutes < b.endMinutes,
      );
    } catch (_) {
      return null;
    }
  }

  static ScheduleBlock? get activeBlock => currentBlock();

  static double currentBlockProgress(ScheduleBlock block) {
    return block.progress;
  }

  // ===== STATS CALCULATIONS =====

  static double get totalPlannedHours {
    int totalMinutes = 0;
    for (var block in todayBlocks) {
      totalMinutes += block.duration;
    }
    return totalMinutes / 60.0;
  }

  static int get totalBlocksCount => todayBlocks.length;
}
