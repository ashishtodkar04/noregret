import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';
import 'task_store.dart';

class SessionStore {
  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static final List<Session> _sessions = [];
  static List<Session> get sessions => _sessions;

  // --- PERSISTENCE ENGINE ---

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('user_sessions_v1');
      
      if (data != null) {
        final List decoded = json.decode(data);
        _sessions.clear();
        _sessions.addAll(decoded.map((s) => Session.fromMap(s)).toList());
        debugPrint("SessionStore: Loaded ${_sessions.length} historical sessions.");
      }
    } catch (e) {
      debugPrint("SessionStore Load Error: $e");
    }
    _initialized = true;
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Only keep a healthy amount of history to keep the app fast (e.g., last 1000 sessions)
      // For now, we save everything.
      final String encoded = json.encode(_sessions.map((s) => s.toMap()).toList());
      await prefs.setString('user_sessions_v1', encoded);
    } catch (e) {
      debugPrint("SessionStore Save Error: $e");
    }
  }

  /// Adds a session, triggers task completion, and locks it to disk
  static void addSession(int seconds, {String? taskTitle, int distractions = 0}) {
    if (seconds < 1) return;

    final newSession = Session(
      start: DateTime.now(),
      durationSeconds: seconds,
      distractions: distractions,
    );

    _sessions.add(newSession);

    // TACTICAL INTERCONNECTION: Automatically complete the mission
    if (taskTitle != null && taskTitle.isNotEmpty) {
      try {
        final task = TaskStore.tasks.firstWhere(
          (t) => t.title.trim().toLowerCase() == taskTitle.trim().toLowerCase(),
        );
        TaskStore.markCompletedToday(task.id);
      } catch (e) {
        debugPrint("SessionStore: No active mission matches '$taskTitle'");
      }
    }

    _persist(); 
    TaskStore.notify(); // Refresh UI observers
  }

  // --- ANALYTICS GETTERS ---

  static List<Session> get todaySessions {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.start.year == now.year &&
             s.start.month == now.month &&
             s.start.day == now.day;
    }).toList().reversed.toList();
  }

  static int get todayTotalSeconds {
    final now = DateTime.now();
    return _sessions.fold(0, (sum, s) {
      final isToday = s.start.year == now.year &&
                     s.start.month == now.month &&
                     s.start.day == now.day;
      return isToday ? sum + s.durationSeconds : sum;
    });
  }

  static String get todayTotalFormatted {
    final total = todayTotalSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    if (total > 0 && h == 0 && m == 0) return "1m"; // Smallest unit
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  static Map<DateTime, int> getHeatmapData() {
    final Map<DateTime, int> dataset = {};
    for (var session in _sessions) {
      final date = DateTime(session.start.year, session.start.month, session.start.day);
      final int minutes = session.durationSeconds ~/ 60;
      if (minutes > 0) {
        dataset[date] = (dataset[date] ?? 0) + minutes;
      }
    }
    return dataset;
  }
}