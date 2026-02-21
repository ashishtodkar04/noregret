extension DateHelpers on DateTime {
  /// Returns a DateTime with only Year, Month, and Day (Midnight)
  /// Used to normalize comparisons for animations and logic.
  DateTime get dateOnly => DateTime(year, month, day);

  /// Checks if the date matches today's date.
  /// Highly efficient comparison for building list items or highlights.
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Checks if the date is in the past (before today's midnight)
  /// Useful for "dimming" or "fading out" UI elements.
  bool isBeforeToday(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today);
  }

  /// Checks if the date is in the future (after today's last second)
  /// Useful for triggering "upcoming" badges or bounce animations.
  bool get isAfterToday {
    final now = DateTime.now();
    return isAfter(DateTime(now.year, now.month, now.day, 23, 59, 59));
  }

  /// Clean formatting using built-in ISO logic
  /// Faster than manual padding and more "productive" to maintain.
  String toIsoDateString() => toIso8601String().split('T').first;
}
