import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart'; // NEW: 2026 Standard for auto-timezone
import 'schedule_store.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    // AUTO-DETECT Timezone (No more hardcoding Asia/Kolkata)
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone().toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint("TZ Error: Falling back to UTC. $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Trigger logic when user taps the "Mission Prepare" notification
      },
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    // Android 13+ Notification Permission
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (android != null) {
      await android.requestNotificationsPermission();
      // Required for 2026 Android versions to prevent "Alarm silences"
      await android.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleScheduleReminders() async {
    // 1. Clear previous schedules to prevent "notification ghosting"
    await _notifications.cancelAll();

    final blocks = ScheduleStore.todayBlocks;
    final now = DateTime.now();

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      // 2. Tactical Logic: 5 mins before start
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        block.start.hour,
        block.start.minute,
      ).subtract(const Duration(minutes: 5));

      // 3. Only schedule if the window is still open
      if (scheduledDateTime.isAfter(now)) {
        final tzScheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

        await _notifications.zonedSchedule(
          i,
          'MISSION STARTING: ${block.title.toUpperCase()}',
          'Deep work initiates in 5 minutes. Clear your terminal.',
          tzScheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'schedule_channel_v2',
              'Tactical Reminders',
              channelDescription: 'High-priority transition alerts',
              importance: Importance.max,
              priority: Priority.high,
              color: Colors.orange,
              // Enables the "Big Text" style for impact
              styleInformation: BigTextStyleInformation(''),
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
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
      'SYSTEM AUDIT',
      'No focus detected. Your future self is losing ground. Act now.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'nudge_channel',
          'System Nudges',
          importance: Importance.high,
          priority: Priority.high,
          color: Colors.orange,
        ),
      ),
    );
  }
}