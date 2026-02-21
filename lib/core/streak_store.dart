import '../models/streak_model.dart';

class StreakStore {
  // 1. SAFETY: Added isInitialized flag for AIStore and CalendarService
  static bool get isInitialized => true;

  // In-memory storage replacing Hive
  static final Streak _streak = Streak(
    lastActiveDate: DateTime.now().subtract(const Duration(days: 1)),
    currentStreak: 0,
  );

  /// Returns the current streak object
  static Streak get streak => _streak;

  /// Getter for integer value (fixes StatsScreen and AIStore)
  static int get currentStreak => _streak.currentStreak;

  /// Rank Logic
  static String getRank(int streakCount) {
    if (streakCount >= 100) return "THE MACHINE";
    if (streakCount >= 50) return "UNTOUCHABLE";
    if (streakCount >= 30) return "DISCIPLINED";
    if (streakCount >= 14) return "WARRIOR";
    if (streakCount >= 7) return "APPRENTICE";
    return "RECRUIT";
  }

  /// Updates the streak logic based on the passage of time.
  static void updateForToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastActive = DateTime(
      _streak.lastActiveDate.year,
      _streak.lastActiveDate.month,
      _streak.lastActiveDate.day,
    );

    // Guard: already updated today
    if (lastActive.isAtSameMomentAs(today)) return;

    final isYesterday = lastActive.isAtSameMomentAs(
      today.subtract(const Duration(days: 1)),
    );

    if (isYesterday) {
      _streak.currentStreak += 1;
    } else {
      // If a day was skipped, we reset to 1 (starting today)
      _streak.currentStreak = 1;
    }

    _streak.lastActiveDate = today;
  }

  /// Helper for UI animations
  static bool get isStreakActiveToday {
    final last = _streak.lastActiveDate;
    final now = DateTime.now();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  static void reset() {
    _streak.currentStreak = 0;
  }
}