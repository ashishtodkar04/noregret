import '../models/session_model.dart';
import 'task_store.dart';

class SessionStore {
  // 1. FIX: Added isInitialized flag for AIStore and CalendarService safety
  static bool get isInitialized => true;

  // In-memory storage replacing Hive
  static final List<Session> _sessions = [];
  static List<Session> get sessions => _sessions;

  /// Adds a session, records distractions, and updates Task history.
  static void addSession(int seconds,
      {String? taskTitle, int distractions = 0}) {
    if (seconds < 1) return;

    // 1. Log raw session data
    _sessions.add(
      Session(
        start: DateTime.now(),
        durationSeconds: seconds,
        distractions: distractions,
      ),
    );

    // 2. INTERCONNECTION LOGIC:
    if (taskTitle != null) {
      try {
        final task = TaskStore.tasks.firstWhere(
          (t) =>
              t.title.trim().toLowerCase() ==
              taskTitle.trim().toLowerCase(),
        );

        TaskStore.markCompletedToday(task.id);
      } catch (e) {
        print("Session logged. No matching mission for: $taskTitle");
      }
    }

    // Refresh global UI listeners
    TaskStore.notify();
  }

  /// Returns today's sessions (reversed for chronological UI).
  static List<Session> get todaySessions {
    final now = DateTime.now();

    return _sessions.where((s) {
      return s.start.year == now.year &&
          s.start.month == now.month &&
          s.start.day == now.day;
    }).toList().reversed.toList();
  }

  /// Calculates total focus time for today in seconds.
  static int get todayTotalSeconds {
    final now = DateTime.now();

    return _sessions.fold(0, (sum, s) {
      final d = s.start;
      final isToday =
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;

      return isToday ? sum + s.durationSeconds : sum;
    });
  }

  /// Formatted string: e.g., "2h 15m" or "45m"
  static String get todayTotalFormatted {
    final total = todayTotalSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;

    if (h == 0 && m == 0 && total > 0) return "1m";
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  /// Heatmap data: Maps normalized Dates to total Minutes
  static Map<DateTime, int> getHeatmapData() {
    final Map<DateTime, int> dataset = {};

    for (var session in _sessions) {
      final date = DateTime(
          session.start.year,
          session.start.month,
          session.start.day);

      final int minutes = session.durationSeconds ~/ 60;

      if (minutes > 0) {
        dataset[date] = (dataset[date] ?? 0) + minutes;
      } else if (session.durationSeconds > 10) {
        dataset[date] = (dataset[date] ?? 0) + 1;
      }
    }

    return dataset;
  }
}