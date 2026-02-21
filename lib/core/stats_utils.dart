import '../core/task_store.dart';
import '../models/task_model.dart';

/// Returns a map of the last 7 days of focus data.
/// Optimized for Chart animations and efficient data lookup.
Map<DateTime, int> getLast7DaysFocus() {
  final now = DateTime.now();
  final Map<DateTime, int> data = {};

  // 1. Productivity: Initialize the map with normalized "Midnight" dates
  // This ensures the Map keys exactly match the task comparison logic.
  for (int i = 0; i < 7; i++) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
    data[day] = 0;
  }

  // 2. Performance: Iterate tasks and update the map
  for (final Task task in TaskStore.tasks) {
    // Normalize task date to midnight for a direct key match
    final date = task.createdDate;
    final taskDay = DateTime(date.year, date.month, date.day);

    // Only update if the date falls within our 7-day window
    if (data.containsKey(taskDay)) {
      data[taskDay] = (data[taskDay] ?? 0) + task.timeSpentInSeconds;
    }
  }

  return data;
}