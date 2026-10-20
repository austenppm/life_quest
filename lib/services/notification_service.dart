import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/alarm.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const String _alarmChannelId = 'life_quest_alarms';
  static const String _reminderChannelId = 'life_quest_reminders';
  static const String _achievementChannelId = 'life_quest_achievements';

  // Initialize notification service
  static Future<void> initialize(
      FlutterLocalNotificationsPlugin plugin) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels(plugin);
  }

  static Future<void> _createNotificationChannels(
      FlutterLocalNotificationsPlugin plugin) async {
    const alarmChannel = AndroidNotificationChannel(
      _alarmChannelId,
      'Alarms',
      description: 'Alarm notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      _reminderChannelId,
      'Reminders',
      description: 'Task and quest reminders',
      importance: Importance.high,
    );

    const achievementChannel = AndroidNotificationChannel(
      _achievementChannelId,
      'Achievements',
      description: 'Achievement unlock notifications',
      importance: Importance.defaultImportance,
    );

    final androidPlugin =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(achievementChannel);
  }

  // Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate accordingly
      // This would typically be handled by a navigation service
      debugPrint('Notification tapped: $payload');
    }
  }

  // Request permissions
  static Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  // Schedule an alarm
  static Future<void> scheduleAlarm(Alarm alarm) async {
    if (!alarm.isEnabled) {
      await cancelAlarm(alarm.id);
      return;
    }

    final scheduledDate = _nextInstanceOfTime(
      alarm.hour,
      alarm.minute,
      alarm.days,
    );

    await _notifications.zonedSchedule(
      alarm.id.hashCode,
      'Life Quest',
      alarm.label,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alarmChannelId,
          'Alarms',
          channelDescription: 'Alarm notifications',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: alarm.isRepeating && alarm.days.isNotEmpty
          ? DateTimeComponents.dayOfWeekAndTime
          : null,
      payload: 'alarm:${alarm.id}',
    );
  }

  // Cancel an alarm
  static Future<void> cancelAlarm(String alarmId) async {
    await _notifications.cancel(alarmId.hashCode);
  }

  // Schedule task reminder
  static Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime reminderTime,
  }) async {
    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return; // Don't schedule past reminders
    }

    await _notifications.zonedSchedule(
      taskId.hashCode,
      'Task Reminder',
      taskTitle,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Reminders',
          channelDescription: 'Task and quest reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:$taskId',
    );
  }

  // Cancel task reminder
  static Future<void> cancelTaskReminder(String taskId) async {
    await _notifications.cancel(taskId.hashCode);
  }

  // Show achievement notification
  static Future<void> showAchievementNotification({
    required String achievementTitle,
    required String achievementDescription,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🏆 Achievement Unlocked!',
      achievementTitle,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _achievementChannelId,
          'Achievements',
          channelDescription: 'Achievement unlock notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          styleInformation: BigTextStyleInformation(
            '$achievementTitle\n$achievementDescription',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Show level up notification
  static Future<void> showLevelUpNotification(int newLevel) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '⬆️ Level Up!',
      'Congratulations! You reached level $newLevel!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _achievementChannelId,
          'Achievements',
          channelDescription: 'Achievement unlock notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // Daily reminder
  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    final scheduledDate = _nextInstanceOfTime(hour, minute, [1, 2, 3, 4, 5, 6, 7]);

    await _notifications.zonedSchedule(
      0, // Fixed ID for daily reminder
      'Daily Check-in',
      'Time to check your quests and complete some tasks!',
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _reminderChannelId,
          'Reminders',
          channelDescription: 'Task and quest reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
  }

  // Cancel daily reminder
  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(0);
  }

  // Helper to get next instance of a time
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute, List<int> days) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (days.isEmpty) {
      // One-time alarm
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      return scheduledDate;
    }

    // Find next matching day
    while (!days.contains(scheduledDate.weekday) ||
        scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel all notifications
  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
