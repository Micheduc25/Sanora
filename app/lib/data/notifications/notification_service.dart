import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/reminder.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    _initialized = true;
  }

  static const _channel = NotificationDetails(
    android: AndroidNotificationDetails(
      'bodi_reminders',
      'Reminders',
      channelDescription: 'Health habit and wellness reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Reminder ids are hashed with the weekday so one reminder maps to up to
  /// seven scheduled notifications.
  Future<void> schedule(Reminder reminder) async {
    await init();
    await cancel(reminder);
    if (!reminder.enabled) return;

    final parts = reminder.time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final weekdays = reminder.weekdays.isEmpty
        ? [1, 2, 3, 4, 5, 6, 7]
        : reminder.weekdays;

    for (final weekday in weekdays) {
      await _plugin.zonedSchedule(
        _notificationId(reminder.id, weekday),
        '${reminder.kind.emoji} ${reminder.title}',
        reminder.body.isEmpty ? _defaultBody(reminder.kind) : reminder.body,
        _nextInstanceOf(weekday, hour, minute),
        _channel,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancel(Reminder reminder) async {
    await init();
    for (var weekday = 1; weekday <= 7; weekday++) {
      await _plugin.cancel(_notificationId(reminder.id, weekday));
    }
  }

  static String _defaultBody(ReminderKind kind) => switch (kind) {
        ReminderKind.water => 'A glass now keeps energy up all afternoon.',
        ReminderKind.stand => 'Two minutes of movement resets your body.',
        ReminderKind.meal => 'Log it in seconds with a photo.',
        ReminderKind.exercise => 'Your future self says thank you.',
        ReminderKind.medication => 'Time for your medication.',
        ReminderKind.sleep => 'Winding down now protects tomorrow.',
        ReminderKind.walk => 'A short walk counts. Every step does.',
        ReminderKind.custom => '',
      };

  static int _notificationId(String reminderId, int weekday) =>
      (reminderId.hashCode & 0x7ffffff) * 10 + weekday;

  static tz.TZDateTime _nextInstanceOf(int weekday, int hour, int minute) {
    var scheduled = tz.TZDateTime.now(tz.local);
    scheduled = tz.TZDateTime(
        tz.local, scheduled.year, scheduled.month, scheduled.day, hour, minute);
    while (scheduled.weekday != weekday ||
        scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
