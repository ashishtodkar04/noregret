/// Formats seconds into a human-readable duration.
/// Optimized for UI labels and progress tracking animations.
String formatTotalTime(int seconds, {bool showSeconds = false}) {
  if (seconds <= 0) return "0m";

  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;

  // Productivity: Use a List-join approach for cleaner conditional strings
  final parts = <String>[];
  
  if (hours > 0) parts.add('${hours}h');
  if (minutes > 0 || (hours > 0 && secs > 0)) parts.add('${minutes}m');
  if (showSeconds && seconds < 3600) parts.add('${secs}s');

  return parts.isEmpty ? "0m" : parts.join(' ');
}

/// Productive Helper: Formats for "Digital Clock" style animations (00:00:00)
String formatDigitalTime(int seconds) {
  final h = (seconds ~/ 3600).toString().padLeft(2, '0');
  final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final s = (seconds % 60).toString().padLeft(2, '0');
  
  return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
}