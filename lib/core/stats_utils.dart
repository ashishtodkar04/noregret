import '../core/session_store.dart';

/// Returns a map of the last 7 days of ACTUAL focus time.
/// Pulls data from SessionStore (historical) rather than TaskStore (creation date).
Map<DateTime, int> getLast7DaysFocus() {
  final now = DateTime.now();
  final Map<DateTime, int> data = {};

  // 1. Initialize the 7-day window (Midnight normalized)
  for (int i = 0; i < 7; i++) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
    data[day] = 0;
  }

  // 2. Iterate through ALL historical sessions
  // This gives a true graphical representation of time spent per day.
  for (final session in SessionStore.sessions) {
    final sessionDay = DateTime(
      session.start.year,
      session.start.month,
      session.start.day,
    );

    if (data.containsKey(sessionDay)) {
      data[sessionDay] = (data[sessionDay] ?? 0) + session.durationSeconds;
    }
  }

  return data;
}