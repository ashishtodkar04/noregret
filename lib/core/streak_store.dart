import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak_model.dart';

class StreakStore {
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static Streak _streak = Streak(
    lastActiveDate: DateTime.now().subtract(const Duration(days: 2)),
    currentStreak: 0,
  );

  static Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('user_streak_v1');
      
      if (data != null) {
        _streak = Streak.fromMap(json.decode(data));
      }
      
      // Auto-check on startup: Did they miss yesterday?
      if (_streak.isBroken) {
        _streak.currentStreak = 0;
        _persist();
      }
    } catch (e) {
      debugPrint("StreakStore Init Error: $e");
    }
    _isInitialized = true;
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_streak_v1', json.encode(_streak.toMap()));
  }

  static Streak get streak => _streak;
  static int get currentStreak => _streak.currentStreak;

  /// Call this whenever a task is completed
  static void recordActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      _streak.lastActiveDate.year, 
      _streak.lastActiveDate.month, 
      _streak.lastActiveDate.day
    );

    // 1. Already recorded activity for today? Do nothing.
    if (lastActive.isAtSameMomentAs(today)) return;

    // 2. Was the last activity yesterday? Increment.
    final yesterday = today.subtract(const Duration(days: 1));
    if (lastActive.isAtSameMomentAs(yesterday)) {
      _streak.currentStreak += 1;
    } else {
      // 3. They missed a day or more. Reset to 1.
      _streak.currentStreak = 1;
    }

    _streak.lastActiveDate = today;
    _persist();
  }

  static String getRank(int streakCount) {
    if (streakCount >= 100) return "THE MACHINE";
    if (streakCount >= 50) return "UNTOUCHABLE";
    if (streakCount >= 30) return "DISCIPLINED";
    if (streakCount >= 14) return "WARRIOR";
    if (streakCount >= 7) return "APPRENTICE";
    return "RECRUIT";
  }

  static void reset() {
    _streak.currentStreak = 0;
    _persist();
  }
}