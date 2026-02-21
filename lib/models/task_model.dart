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

  bool get isDoneOrSkipped => isCompleted || isSkipped || isFinished;

  String get formattedTime {
    final minutes = (timeSpentInSeconds % 3600) ~/ 60;
    final seconds = timeSpentInSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isHighQualitySession => timeSpentInSeconds >= 1500;

  bool get wasCreatedToday {
    final now = DateTime.now();
    return createdDate.year == now.year &&
        createdDate.month == now.month &&
        createdDate.day == now.day;
  }

  bool get isFromYesterday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return createdDate.isBefore(today);
  }
}
