import 'package:flutter/material.dart';

class ScheduleBlock {
  final String id;
  final String title;
  int startMinutes;
  int endMinutes;
  bool isCompleted;

  ScheduleBlock({
    required this.id,
    required this.title,
    required this.startMinutes,
    required this.endMinutes,
    this.isCompleted = false,
  });

  TimeOfDay get start =>
      TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);

  TimeOfDay get end =>
      TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

  int get duration => endMinutes - startMinutes;

  double get progress {
    final now = TimeOfDay.now();
    final current = now.hour * 60 + now.minute;

    if (current < startMinutes) return 0.0;
    if (current >= endMinutes) return 1.0;
    if (duration <= 0) return 0.0;

    return (current - startMinutes) / duration;
  }

  bool get isNow {
    final now = TimeOfDay.now();
    final current = now.hour * 60 + now.minute;
    return current >= startMinutes && current < endMinutes;
  }

  ScheduleBlock copyForToday() {
    return ScheduleBlock(
      id: id,
      title: title,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      isCompleted: false,
    );
  }
}
