import 'package:flutter/material.dart';
import '../core/schedule_store.dart';
import '../core/task_store.dart';
import '../core/notification_service.dart';
import '../models/task_model.dart';
import '../models/schedule_block.dart';
import '../main.dart';
import 'add_schedule_screen.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;

    final bool isGhostMode =
        appSettings.ghostMode;
    final Color activeColor =
        Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor:
          const Color(0xFF080808),
      appBar: AppBar(
        title: Text(
          "MISSION TIMELINE",
          style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 3,
              color: isGhostMode
                  ? Colors.white38
                  : Colors.white70),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor:
            Colors.transparent,
        leading: IconButton(
          icon: const Icon(
              Icons.chevron_left_rounded,
              color: Colors.white,
              size: 28),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: ScheduleStore.tick,
        builder: (context, _, __) {
          final current =
              ScheduleStore.currentBlock();
          final blocks =
              ScheduleStore.todayBlocks;

          return Column(
            children: [
              if (current != null)
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                          20, 10, 20, 20),
                  child: _ActiveBlockCard(
                      block: current,
                      activeColor:
                          activeColor),
                ),
              Padding(
                padding:
                    const EdgeInsets.only(
                        left: 140,
                        bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection:
                      Axis.horizontal,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  child: Row(
                    children:
                        List.generate(
                      daysInMonth,
                      (i) =>
                          _buildDayHeader(
                              i + 1,
                              activeColor),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: blocks.isEmpty
                    ? const _EmptySchedule()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal:
                                    16,
                                vertical:
                                    10),
                        itemCount:
                            blocks.length,
                        itemBuilder:
                            (context,
                                index) {
                          final block =
                              blocks[
                                  index];
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .stretch,
                              children: [
                                SizedBox(
                                  width:
                                      120,
                                  child:
                                      _TimelineTile(
                                    block:
                                        block,
                                    activeColor:
                                        activeColor,
                                    isActive:
                                        current
                                                ?.id ==
                                            block
                                                .id,
                                    onLongPress:
                                        () =>
                                            _showBlockActions(
                                                context,
                                                block),
                                    onTap:
                                        () =>
                                            _handleToggle(
                                                block.title,
                                                DateTime.now().day),
                                  ),
                                ),
                                const SizedBox(
                                    width: 8),
                                Expanded(
                                  child:
                                      ValueListenableBuilder(
                                    valueListenable:
                                        TaskStore.tick,
                                    builder:
                                        (context,
                                            _,
                                            __) {
                                      return SingleChildScrollView(
                                        scrollDirection:
                                            Axis.horizontal,
                                        child:
                                            Row(
                                          children:
                                              List.generate(
                                            daysInMonth,
                                            (dayIndex) {
                                              return _buildCheckCell(
                                                  context,
                                                  block
                                                      .title,
                                                  dayIndex +
                                                      1,
                                                  activeColor);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            activeColor,
        elevation: 10,
        shape:
            RoundedRectangleBorder(
                borderRadius:
                    BorderRadius
                        .circular(18)),
        child: Icon(
            Icons.add_rounded,
            color: isGhostMode
                ? Colors.white
                : Colors.black,
            size: 32),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    const AddScheduleScreen()),
          );
          NotificationService
              .scheduleScheduleReminders();
        },
      ),
    );
  }

  Widget _buildDayHeader(
      int day, Color activeColor) {
    bool isToday =
        day == DateTime.now().day;
    return Container(
      width: 32,
      alignment: Alignment.center,
      child: Text(
        day
            .toString()
            .padLeft(2, '0'),
        style: TextStyle(
          fontSize: 9,
          fontFamily:
              'Monospace',
          fontWeight:
              FontWeight.w900,
          color: isToday
              ? activeColor
              : Colors.white10,
        ),
      ),
    );
  }

  void _handleToggle(
      String title, int day) {
    final now =
        DateTime.now();
    final dateKey =
        "${now.year}-${now.month}-$day";
    final normalizedTitle =
        title.trim().toLowerCase();

    try {
      final task =
          TaskStore.tasks.firstWhere(
              (t) =>
                  t.title
                      .trim()
                      .toLowerCase() ==
                  normalizedTitle);
      TaskStore
          .toggleTaskCompletion(
              task.id,
              customDateKey:
                  dateKey);
    } catch (_) {}
  }

  Widget _buildCheckCell(
      BuildContext context,
      String title,
      int day,
      Color activeColor) {
    final now =
        DateTime.now();
    final dateKey =
        "${now.year}-${now.month}-$day";
    final normalizedTitle =
        title.trim().toLowerCase();

    Task? matchingTask;
    try {
      matchingTask =
          TaskStore.tasks.firstWhere(
              (t) =>
                  t.title
                      .trim()
                      .toLowerCase() ==
                  normalizedTitle);
    } catch (_) {
      matchingTask = null;
    }

    bool isDone =
        matchingTask != null &&
            matchingTask
                .completionHistory
                .contains(dateKey);
    bool isFuture =
        day > now.day;
    bool isToday =
        day == now.day;
    bool hasNoTask =
        matchingTask == null;

    return GestureDetector(
      onTap: (isFuture ||
              hasNoTask)
          ? null
          : () => _handleToggle(
              title, day),
      child: Container(
        width: 32,
        height: 50,
        alignment:
            Alignment.center,
        child:
            AnimatedContainer(
          duration:
              const Duration(
                  milliseconds:
                      300),
          width: 24,
          height: 24,
          decoration:
              BoxDecoration(
            color: isDone
                ? activeColor
                : Colors
                    .transparent,
            borderRadius:
                BorderRadius
                    .circular(4),
            border:
                Border.all(
              color: isDone
                  ? activeColor
                  : (isToday
                      ? activeColor
                          .withOpacity(
                              0.5)
                      : Colors.white
                          .withOpacity(
                              0.05)),
              width:
                  isToday
                      ? 1.5
                      : 1,
            ),
            boxShadow: isDone
                ? [
                    BoxShadow(
                        color:
                            activeColor
                                .withOpacity(
                                    0.2),
                        blurRadius:
                            8)
                  ]
                : [],
          ),
          child: isDone
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: activeColor ==
                          Colors
                              .orange
                      ? Colors
                          .black
                      : Colors
                          .white)
              : (hasNoTask &&
                      !isFuture
                  ? const Icon(
                      Icons
                          .remove,
                      size: 10,
                      color: Colors
                          .white10)
                  : null),
        ),
      ),
    );
  }

  void _showBlockActions(
      BuildContext context,
      ScheduleBlock block) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          const Color(
              0xFF111111),
      shape:
          const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(
                      top:
                          Radius.circular(
                              30))),
      builder: (_) => Container(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(
                        color: Colors
                            .white10,
                        borderRadius:
                            BorderRadius
                                .circular(
                                    10))),
            const SizedBox(
                height: 24),
            ListTile(
              leading: const Icon(
                  Icons
                      .edit_rounded,
                  color:
                      Colors.white),
              title: const Text(
                  "MODIFY SEQUENCE",
                  style: TextStyle(
                      color:
                          Colors.white,
                      fontWeight:
                          FontWeight
                              .bold,
                      letterSpacing:
                          1)),
              onTap: () async {
                Navigator.pop(
                    context);
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            AddScheduleScreen(
                                editBlock:
                                    block)));
                NotificationService
                    .scheduleScheduleReminders();
              },
            ),
            ListTile(
              leading: const Icon(
                  Icons
                      .delete_outline_rounded,
                  color: Colors
                      .redAccent),
              title: const Text(
                  "TERMINATE BLOCK",
                  style: TextStyle(
                      color: Colors
                          .redAccent,
                      fontWeight:
                          FontWeight
                              .bold,
                      letterSpacing:
                          1)),
              onTap: () async {
                await ScheduleStore
                    .removeDailyBlock(
                        block.id);
                NotificationService
                    .scheduleScheduleReminders();
                if (context
                    .mounted) {
                  Navigator.pop(
                      context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTile
    extends StatelessWidget {
  final ScheduleBlock block;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _TimelineTile(
      {required this.block,
      required this.isActive,
      required this.activeColor,
      required this.onLongPress,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress:
          onLongPress,
      child: Container(
        margin:
            const EdgeInsets
                .symmetric(
                    vertical: 6),
        padding:
            const EdgeInsets
                .all(12),
        decoration:
            BoxDecoration(
          color: isActive
              ? activeColor
                  .withOpacity(
                      0.1)
              : const Color(
                  0xFF111111),
          borderRadius:
              BorderRadius
                  .circular(12),
          border: Border.all(
              color: isActive
                  ? activeColor
                  : Colors.white
                      .withOpacity(
                          0.05)),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Text(
              block.title
                  .toUpperCase(),
              maxLines: 1,
              overflow:
                  TextOverflow
                      .ellipsis,
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight
                        .w900,
                color: isActive
                    ? activeColor
                    : Colors.white,
                letterSpacing:
                    0.5,
              ),
            ),
            const SizedBox(
                height: 4),
            Text(
              block.start
                  .format(
                      context),
              style:
                  TextStyle(
                fontSize: 10,
                color: isActive
                    ? activeColor
                        .withOpacity(
                            0.5)
                    : Colors
                        .white24,
                fontWeight:
                    FontWeight
                        .w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBlockCard
    extends StatelessWidget {
  final ScheduleBlock block;
  final Color activeColor;

  const _ActiveBlockCard(
      {required this.block,
      required this.activeColor});

  @override
  Widget build(
      BuildContext context) {
    return Container(
      padding:
          const EdgeInsets
              .all(24),
      decoration:
          BoxDecoration(
        color:
            const Color(
                0xFF141414),
        borderRadius:
            BorderRadius
                .circular(24),
        border: Border.all(
            color: activeColor
                .withOpacity(
                    0.2)),
        boxShadow: [
          BoxShadow(
              color: activeColor
                  .withOpacity(
                      0.05),
              blurRadius:
                  20)
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            children: [
              Icon(
                  Icons
                      .radar_rounded,
                  size: 14,
                  color:
                      activeColor),
              const SizedBox(
                  width: 8),
              Text(
                  "CURRENT OPERATIONAL BLOCK",
                  style: TextStyle(
                      color:
                          activeColor,
                      fontWeight:
                          FontWeight
                              .w900,
                      fontSize:
                          10,
                      letterSpacing:
                          1.5)),
            ],
          ),
          const SizedBox(
              height: 12),
          Text(block.title,
              style:
                  const TextStyle(
                      fontSize:
                          24,
                      fontWeight:
                          FontWeight
                              .w900,
                      color: Colors
                          .white,
                      letterSpacing:
                          -0.5)),
          const SizedBox(
              height: 16),
          ClipRRect(
            borderRadius:
                BorderRadius
                    .circular(10),
            child:
                LinearProgressIndicator(
              value: block.progress
                  .clamp(
                      0.0,
                      1.0),
              backgroundColor:
                  Colors.white
                      .withOpacity(
                          0.05),
              color:
                  activeColor,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySchedule
    extends StatelessWidget {
  const _EmptySchedule();

  @override
  Widget build(
      BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment
                .center,
        children: [
          Icon(
              Icons
                  .inventory_2_outlined,
              size: 48,
              color: Colors
                  .white
                  .withOpacity(
                      0.05)),
          const SizedBox(
              height: 16),
          const Text(
              "NO OBJECTIVES DEFINED",
              style: TextStyle(
                  color:
                      Colors
                          .white12,
                  fontWeight:
                      FontWeight
                          .w900,
                  letterSpacing:
                      2,
                  fontSize:
                      10)),
        ],
      ),
    );
  }
}
