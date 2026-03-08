class Task {
  String id;
  String title;
  DateTime createdDate;

  bool isCompleted;
  bool isSkipped;
  bool isDaily;

  bool focusEnabled;

  int timeSpentInSeconds;

  bool isRunning;
  bool isFinished;

  /// NEW: used to calculate elapsed time when screen is off
  DateTime? startedAt;

  List<String> completionHistory;

  Task({
    required this.id,
    required this.title,
    DateTime? createdDate,
    this.startedAt,
    this.isCompleted = false,
    this.isSkipped = false,
    this.isDaily = false,
    this.focusEnabled = false,
    this.timeSpentInSeconds = 0,
    this.isRunning = false,
    this.isFinished = false,
    List<String>? completionHistory,
  }) : createdDate = createdDate ?? DateTime.now(),
       completionHistory = completionHistory ?? [];

  // ---------------- DATE HELPERS ----------------

  bool get isFromYesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    return createdDate.year == yesterday.year &&
        createdDate.month == yesterday.month &&
        createdDate.day == yesterday.day;
  }

  bool get isDoneOrSkipped {
    return isCompleted || isSkipped || isFinished;
  }
  void markFinished() {
  isCompleted = true;
  isFinished = true;
  isRunning = false;
  startedAt = null;
}
void undoFinished() {
  isCompleted = false;
  isFinished = false;
}
  // ---------------- SERIALIZATION ----------------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'createdDate': createdDate.toIso8601String(),
      'isCompleted': isCompleted,
      'isSkipped': isSkipped,
      'isDaily': isDaily,
      'focusEnabled': focusEnabled,
      'timeSpentInSeconds': timeSpentInSeconds,
      'isRunning': isRunning,
      'isFinished': isFinished,
      'startedAt': startedAt?.toIso8601String(),
      'completionHistory': completionHistory,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled',
      createdDate: map['createdDate'] != null
          ? DateTime.parse(map['createdDate'])
          : DateTime.now(),
      isCompleted: map['isCompleted'] ?? false,
      isSkipped: map['isSkipped'] ?? false,
      isDaily: map['isDaily'] ?? false,
      focusEnabled: map['focusEnabled'] ?? false,
      timeSpentInSeconds: map['timeSpentInSeconds'] ?? 0,
      isRunning: map['isRunning'] ?? false,
      isFinished: map['isFinished'] ?? false,
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'])
          : null,
      completionHistory: map['completionHistory'] != null
          ? List<String>.from(map['completionHistory'])
          : [],
    );
  }
}
