class Session {
  DateTime start;
  int durationSeconds;
  int distractions;

  Session({
    required this.start,
    required this.durationSeconds,
    this.distractions = 0,
  });

  // --- NEW: Serialization ---
  Map<String, dynamic> toMap() {
    return {
      'start': start.toIso8601String(),
      'durationSeconds': durationSeconds,
      'distractions': distractions,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      start: DateTime.parse(map['start']),
      durationSeconds: map['durationSeconds'] ?? 0,
      distractions: map['distractions'] ?? 0,
    );
  }

  DateTime get end => start.add(Duration(seconds: durationSeconds));
  int get durationMinutes => (durationSeconds / 60).ceil();

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  bool get isDeepWork => durationSeconds >= 1200;

  double get focusScore {
    if (durationSeconds == 0) return 0.0;
    final penalty = distractions * 0.1;
    return (1.0 - penalty).clamp(0.0, 1.0);
  }
}