import '../models/task_model.dart';
import '../models/schedule_block.dart';

/// Converts a [ScheduleBlock] to a [Task].
/// [createdAt] allows for custom timestamps, useful for sync or undo animations.
Task taskFromSchedule(ScheduleBlock block, {DateTime? createdAt}) {
  return Task(
    // Productive: Standardized prefixing for easier filtering/regex
    id: 'sched_${block.id}', 
    title: block.title.trim(), // Productivity: Clean whitespace automatically
    createdDate: createdAt ?? DateTime.now(),
    focusEnabled: true,
  );
}