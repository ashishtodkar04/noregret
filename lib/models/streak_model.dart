class Streak {
  DateTime lastActiveDate;
  int currentStreak;

  Streak({
    required this.lastActiveDate,
    required this.currentStreak,
  });

  bool get isActiveToday {
    final now = DateTime.now();
    return lastActiveDate.year == now.year &&
        lastActiveDate.month == now.month &&
        lastActiveDate.day == now.day;
  }

  bool get isBroken {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final midnightYesterday =
        DateTime(yesterday.year, yesterday.month, yesterday.day);

    return lastActiveDate.isBefore(midnightYesterday) && !isActiveToday;
  }

  String get rank {
    if (currentStreak >= 30) return "Legendary";
    if (currentStreak >= 7) return "Consistent";
    if (currentStreak >= 3) return "On Fire";
    return "Beginner";
  }

  bool get isHighStreak => currentStreak >= 7;
}
