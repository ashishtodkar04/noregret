import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'schedule_store.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ---------------- INIT ----------------

  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();

      tz.setLocalLocation(tz.getLocation(timezoneInfo.toString()));
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

    await _notifications.initialize(settings);

    await _createChannels();

    await _requestPermissions();
  }

  // ---------------- CHANNELS ----------------

  static Future<void> _createChannels() async {
    const AndroidNotificationChannel scheduleChannel =
        AndroidNotificationChannel(
          'schedule_channel_v2',
          'Tactical Reminders',
          description: 'High priority schedule alerts',
          importance: Importance.max,
        );

    const AndroidNotificationChannel nudgeChannel = AndroidNotificationChannel(
      'nudge_channel',
      'System Nudges',
      description: 'Productivity nudges',
      importance: Importance.high,
    );

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.createNotificationChannel(scheduleChannel);
      await android.createNotificationChannel(nudgeChannel);
    }
  }

  // ---------------- PERMISSIONS ----------------

  static Future<void> _requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.requestNotificationsPermission();

      await android.requestExactAlarmsPermission();
    }
  }

  // ---------------- SCHEDULE REMINDERS ----------------

  static Future<void> scheduleScheduleReminders() async {
    // Cancel only schedule notifications
    for (int i = 0; i < 100; i++) {
      await _notifications.cancel(i);
    }

    final blocks = ScheduleStore.todayBlocks;

    final now = DateTime.now();

    for (int i = 0; i < blocks.length; i++) {
      final block = blocks[i];

      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        block.start.hour,
        block.start.minute,
      ).subtract(const Duration(minutes: 5));

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

  // ---------------- INACTIVITY NUDGE ----------------

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
