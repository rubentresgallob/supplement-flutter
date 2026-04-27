import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Programa una notificación diaria a la hora indicada.
  // Si el suplemento ya fue completado hoy, llama a cancelReminder en su lugar.
  static Future<void> scheduleReminder({
    required int id,
    required String supplementName,
    required TimeOfDay time,
  }) async {
    await _plugin.cancel(id);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      'Recordatorio: $supplementName 💊',
      'No olvides registrar tu toma de hoy',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'supplement_reminders',
          'Recordatorios de suplementos',
          channelDescription: 'Recuérdame registrar mis tomas diarias',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  static Future<void> showMotivationSent(String friendName) async {
    await _plugin.show(
      99998,
      '¡Ánimos enviados! 💪',
      'Has motivado a $friendName. ¡Seguid así!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation',
          'Motivaciones',
          channelDescription: 'Motivaciones entre amigos',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  // Convierte el ID de suplemento (String) a int para la notificación
  static int idFromSupplementId(String supplementId) {
    return supplementId.hashCode.abs() % 100000;
  }
}
