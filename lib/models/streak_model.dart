class Streak {
  DateTime lastActiveDate;
  int currentStreak;

  Streak({
    required this.lastActiveDate,
    required this.currentStreak,
  });

  Map<String, dynamic> toMap() {
    return {
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'currentStreak': currentStreak,
    };
  }

  factory Streak.fromMap(Map<String, dynamic> map) {
    return Streak(
      // Added a try-parse fallback to prevent startup crashes
      lastActiveDate: map['lastActiveDate'] != null 
          ? DateTime.parse(map['lastActiveDate']) 
          : DateTime.now().subtract(const Duration(days: 1)),
      currentStreak: map['currentStreak'] ?? 0,
    );
  }

  bool get isActiveToday {
    final now = DateTime.now();
    return lastActiveDate.year == now.year &&
           lastActiveDate.month == now.month &&
           lastActiveDate.day == now.day;
  }

  bool get isBroken {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final lastDateOnly = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
    
    // It's broken if the last active date is older than yesterday
    return lastDateOnly.isBefore(yesterday);
  }
}