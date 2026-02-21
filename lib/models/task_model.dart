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
  List<String> completionHistory;

  Task({
    required this.id,
    required this.title,
    DateTime? createdDate,
    this.isCompleted = false,
    this.isSkipped = false,
    this.isDaily = false,
    this.focusEnabled = false,
    this.timeSpentInSeconds = 0,
    this.isRunning = false,
    this.isFinished = false,
    List<String>? completionHistory,
  })  : createdDate = createdDate ?? DateTime.now(),
        completionHistory = completionHistory ?? [];

  // FIXED: Corrected createdAt to createdDate
  bool get isFromYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return createdDate.year == yesterday.year &&
           createdDate.month == yesterday.month &&
           createdDate.day == yesterday.day;
  }

  // --- Serialization ---

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
      completionHistory: map['completionHistory'] != null 
          ? List<String>.from(map['completionHistory']) 
          : [],
    );
  }

  bool get isDoneOrSkipped => isCompleted || isSkipped || isFinished;
}