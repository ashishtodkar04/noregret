import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'schedule_store.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // Fallback logic without external package
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click here if needed
      },
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      // Permission for Android 13+
      await androidImplementation.requestNotificationsPermission();
      // Permission for Exact Alarms (Crucial for scheduled reminders)
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleScheduleReminders() async {
    // Prevent duplicate schedules
    await _notifications.cancelAll();

    final blocks = ScheduleStore.todayBlocks;
    final now = DateTime.now();

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      // Calculate start time: today at block's hour/min, minus 5 mins
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        block.start.hour,
        block.start.minute,
      ).subtract(const Duration(minutes: 5));

      // Only schedule if the time hasn't passed yet
      if (scheduledDateTime.isAfter(now)) {
        final tzScheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

        await _notifications.zonedSchedule(
          i,
          'NEXT MISSION: ${block.title.toUpperCase()}',
          'Initiating in 5 minutes. Prepare for deep work.',
          tzScheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'schedule_channel',
              'Tactical Reminders',
              channelDescription: 'Timetable block transitions',
              importance: Importance.max,
              priority: Priority.high,
              color: Colors.orange, // UI visual color in notification bar
              styleInformation: BigTextStyleInformation(
                '',
              ), // For longer titles
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  static Future<void> sendInactivityNudge() async {
    await _notifications.show(
      999,
      'STATUS CHECK',
      'No mission progress detected today. Re-engage immediately.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nudge_channel',
          'System Nudges',
          importance: Importance.defaultImportance,
          color: Colors.orange,
        ),
      ),
    );
  }
}
