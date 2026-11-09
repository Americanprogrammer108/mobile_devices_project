import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class PantryReminder {
  const PantryReminder({
    required this.id,
    required this.name,
    required this.remindAt,
  });

  final String id;
  final String name;
  final DateTime remindAt;
}

class NotificationService {
  NotificationService._(this._plugin);

  static const _channel = AndroidNotificationChannel(
    'expiry_reminders',
    'Expiry reminders',
    description: 'Reminders for pantry items approaching expiry.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<NotificationService> create() async {
    tz.initializeTimeZones();

    final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTimeZone.identifier));

    final plugin = FlutterLocalNotificationsPlugin();

    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    final androidPlugin = plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();

    return NotificationService._(plugin);
  }

  Future<void> scheduleTestNotification() async {
    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: 5));
    await _plugin.cancel(id: 999999);
    debugPrint('Dart local time: ${DateTime.now()}');
    debugPrint('Dart UTC time: ${DateTime.now().toUtc()}');
    debugPrint('Timezone location: ${tz.local.name}');
    debugPrint('TZ current time: ${tz.TZDateTime.now(tz.local)}');
    debugPrint('Scheduled time: $scheduledTime');
    debugPrint(
      'Minutes until notification: '
      '${scheduledTime.difference(tz.TZDateTime.now(tz.local)).inMinutes}',
    );
    await _plugin.zonedSchedule(
      id: 999999,
      title: 'Smart Pantry Test',
      body: 'Your expiration reminders are working!',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_reminders',
          'Expiry reminders',
          channelDescription: 'Reminders for pantry items approaching expiry.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'test:expiry',
    );

    final pending = await _plugin.pendingNotificationRequests();

    debugPrint(
      'Test notification pending: '
      '${pending.any((notification) => notification.id == 999999)}',
    );

    debugPrint('Scheduled for: $scheduledTime');
    debugPrint('Test pending: ${pending.any((n) => n.id == 999999)}');
  }

  Future<void> checkPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();

    debugPrint('Pending notifications: ${pending.length}');

    for (final notification in pending) {
      debugPrint(
        'ID: ${notification.id}, '
        'Title: ${notification.title}, '
        'Body: ${notification.body}',
      );
    }
  }

  Future<void> showTestNotificationNow() async {
    await _plugin.show(
      id: 999998,
      title: 'Smart Pantry Immediate Test',
      body: 'Android notification delivery is working!',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'expiry_reminders',
          'Expiry reminders',
          channelDescription: 'Reminders for pantry items approaching expiry.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> debugPendingNotifications() async {
    final pending = await _plugin.pendingNotificationRequests();

    debugPrint('Pending Android notifications: ${pending.length}');

    for (final notification in pending) {
      debugPrint(
        'Pending notification: '
        'id=${notification.id}, '
        'title=${notification.title}, '
        'payload=${notification.payload}',
      );
    }
  }

  Future<bool> requestExactAlarmPermission() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return false;

    final granted = await androidPlugin.requestExactAlarmsPermission();

    return granted ?? false;
  }

  Future<bool> canScheduleExactNotifications() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  Future<void> reconcile(Iterable<PantryReminder> reminders) async {
    final now = DateTime.now();

    final desired = {
      for (final reminder in reminders)
        if (reminder.remindAt.isAfter(now)) reminder.id: reminder,
    };

    final desiredNotificationIds = desired.keys.map(_notificationId).toSet();

    final pending = await _plugin.pendingNotificationRequests();

    // Cancel local expiry notifications for deleted or expired Firestore items.
    for (final notification in pending) {
      final isExpiryNotification =
          notification.payload?.startsWith('expiry:') ?? false;

      if (isExpiryNotification &&
          !desiredNotificationIds.contains(notification.id)) {
        await _plugin.cancel(id: notification.id);
      }
    }

    // Replace notifications when a Firestore reminder time changes.
    for (final reminder in desired.values) {
      final id = _notificationId(reminder.id);

      await _plugin.cancel(id: id);

      await _plugin.zonedSchedule(
        id: id,
        title: 'Expiry reminder',
        body: '${reminder.name} is approaching its expiry date.',
        scheduledDate: tz.TZDateTime.from(reminder.remindAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'expiry_reminders',
            'Expiry reminders',
            channelDescription:
                'Reminders for pantry items approaching expiry.',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'expiry:${reminder.id}',
      );
    }
  }

  int _notificationId(String pantryItemId) {
    var hash = 0x811C9DC5;

    for (final codeUnit in pantryItemId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }

    return hash;
  }
}
