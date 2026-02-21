extension DateHelpers on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  // Checks if 'this' specific DateTime instance is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isBeforeToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return isBefore(today);
  }

  bool get isAfterToday {
    final now = DateTime.now();
    return isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
  }

  String toIsoDateString() => toIso8601String().split('T').first;
}