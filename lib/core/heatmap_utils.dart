import 'package:flutter/material.dart';
import 'session_store.dart';

Map<DateTime, int> generateHeatmapDataset() {
  final sessions = SessionStore.sessions;

  final Map<DateTime, int> data = {};

  for (final s in sessions) {
    final date = DateTime(s.start.year, s.start.month, s.start.day);

    final minutes = s.durationSeconds ~/ 60;

    if (minutes > 0) {
      data[date] = (data[date] ?? 0) + minutes;
    }
  }

  return data;
}