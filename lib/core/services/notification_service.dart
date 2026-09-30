import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  /// Icono monocromo de la barra de estado (android/app/src/main/res/drawable).
  /// El icono de la app es a color y Android lo pintaría como un cuadrado gris.
  static const _smallIcon = 'ic_stat_capsu';
  static const _accent = Color(0xFFFF6B35);

  /// ID fijo para la notificación de "ánimos enviados" (fuera del rango de IDs
  /// de suplementos, que son los IDs numéricos del backend).
  static const _motivationId = 2147480000;

  /// Los IDs base de suplemento son < 100 M para que los avisos sueltos
  /// (1.000.000.000 + id·10 + día) quepan en un entero de 32 bits.
  static const _maxBaseId = 100000000;

  static const _reminderDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'supplement_reminders',
      'Recordatorios de suplementos',
      channelDescription: 'Recuérdame registrar mis tomas diarias',
      importance: Importance.high,
      priority: Priority.high,
      icon: _smallIcon,
      color: _accent,
      category: AndroidNotificationCategory.reminder,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: false,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    ),
  );

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings(_smallIcon);
    // Los permisos NO se piden al arrancar: se piden cuando el usuario
    // configura su primer recordatorio (ver [ensurePermissions]).
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  static IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  static bool _askedExactThisSession = false;

  /// Pide los permisos necesarios para los recordatorios.
  /// Devuelve `true` si las notificaciones se podrán mostrar.
  ///
  /// Si ya estaban concedidos, no muestra ningún diálogo.
  static Future<bool> ensurePermissions() async {
    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      // Alarmas exactas (Android 12+): si no están permitidas, abrimos los
      // ajustes UNA vez por sesión. Si el usuario no las concede, los
      // recordatorios siguen funcionando en modo inexacto (unos minutos de margen).
      final canExact = await android.canScheduleExactNotifications() ?? true;
      if (granted && !canExact && !_askedExactThisSession) {
        _askedExactThisSession = true;
        await android.requestExactAlarmsPermission();
      }
      return granted;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: false, sound: true) ??
          false;
    }
    return false;
  }

  /// Días máximos de avisos sueltos cuando hoy ya está completo.
  static const maxDaysAhead = 6;

  /// Presupuesto de notificaciones pendientes (iOS permite 64 en total).
  static const _pendingBudget = 56;

  /// Cuántos días de avisos sueltos caben por suplemento según cuántos
  /// suplementos tienen recordatorio (para no pasar el límite de iOS).
  static int daysAheadFor(int supplementsWithReminder) {
    if (supplementsWithReminder <= 0) return maxDaysAhead;
    return (_pendingBudget ~/ supplementsWithReminder).clamp(1, maxDaysAhead);
  }

  /// Programa el recordatorio diario de un suplemento.
  ///
  /// - Tomas de hoy pendientes → recordatorio diario REPETIDO (funciona
  ///   indefinidamente aunque no se abra la app).
  /// - Tomas de hoy completas ([skipToday]) → avisos sueltos desde mañana
  ///   durante [daysAhead] días. Los recordatorios repetidos de Android/iOS
  ///   ignoran la fecha de inicio y sonarían hoy igualmente (comprobado en el
  ///   emulador), por eso no se pueden usar para "saltar hoy".
  static Future<void> scheduleReminder({
    required int id,
    required String supplementName,
    required TimeOfDay time,
    bool skipToday = false,
    int daysAhead = maxDaysAhead,
  }) async {
    await cancelReminder(id);

    final canExact = await _android?.canScheduleExactNotifications() ?? true;
    final scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final plan = reminderPlan(
      id: id,
      time: time,
      now: tz.TZDateTime.now(tz.local),
      skipToday: skipToday,
      daysAhead: daysAhead,
    );
    for (final slot in plan) {
      await _plugin.zonedSchedule(
        slot.id,
        'Hora de tu $supplementName 💊',
        'Toca para registrar la toma de hoy',
        slot.when,
        _reminderDetails,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: slot.repeatsDaily ? DateTimeComponents.time : null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  /// Qué notificaciones hay que programar (función pura, testeable).
  @visibleForTesting
  static List<ReminderSlot> reminderPlan({
    required int id,
    required TimeOfDay time,
    required tz.TZDateTime now,
    required bool skipToday,
    int daysAhead = maxDaysAhead,
  }) {
    if (!skipToday) {
      return [ReminderSlot(id, nextOccurrence(time, now), repeatsDaily: true)];
    }
    final days = daysAhead.clamp(1, maxDaysAhead);
    return [
      for (var k = 1; k <= days; k++)
        ReminderSlot(
          _oneShotId(id, k),
          // Día de calendario (no +24 h) para respetar los cambios de hora
          tz.TZDateTime(now.location, now.year, now.month, now.day + k,
              time.hour, time.minute),
          repeatsDaily: false,
        ),
    ];
  }

  /// Próximo momento en que debe sonar el recordatorio.
  @visibleForTesting
  static tz.TZDateTime nextOccurrence(
    TimeOfDay time,
    tz.TZDateTime now, {
    bool skipToday = false,
  }) {
    var scheduled = tz.TZDateTime(
        now.location, now.year, now.month, now.day, time.hour, time.minute);
    if (skipToday || !scheduled.isAfter(now)) {
      // Sumamos un día de calendario (no 24 h) para respetar cambios de hora
      scheduled = tz.TZDateTime(now.location, now.year, now.month, now.day + 1,
          time.hour, time.minute);
    }
    return scheduled;
  }

  /// IDs de los avisos sueltos: rango propio para no chocar con los diarios.
  static int _oneShotId(int id, int day) => 1000000000 + id * 10 + day;

  /// Cancela el recordatorio diario y sus avisos sueltos.
  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
    for (var k = 1; k <= 9; k++) {
      await _plugin.cancel(_oneShotId(id, k));
    }
  }

  /// Cancela todos los recordatorios (p. ej. al cerrar sesión).
  static Future<void> cancelAll() => _plugin.cancelAll();

  /// Recordatorios programados actualmente (útil para depurar).
  static Future<List<PendingNotificationRequest>> pending() =>
      _plugin.pendingNotificationRequests();

  static Future<void> showMotivationSent(String friendName) async {
    await _plugin.show(
      _motivationId,
      '¡Ánimos enviados!',
      'Has motivado a $friendName. ¡Seguid así!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation',
          'Motivaciones',
          channelDescription: 'Motivaciones entre amigos',
          importance: Importance.defaultImportance,
          icon: _smallIcon,
          color: _accent,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  /// ID ESTABLE de notificación para un suplemento.
  ///
  /// Antes se usaba `String.hashCode`, que no está garantizado entre versiones
  /// de Dart: tras actualizar Flutter los IDs cambiaban y los recordatorios
  /// antiguos quedaban huérfanos (imposibles de cancelar). Los IDs del backend
  /// son numéricos, así que se usan tal cual; si no, hash FNV-1a determinista.
  static int idFromSupplementId(String supplementId) {
    final numeric = int.tryParse(supplementId);
    if (numeric != null && numeric >= 0 && numeric < _maxBaseId) {
      return numeric;
    }
    var hash = 0x811c9dc5;
    for (final unit in supplementId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash % _maxBaseId;
  }
}

/// Una notificación a programar.
@immutable
class ReminderSlot {
  final int id;
  final tz.TZDateTime when;
  final bool repeatsDaily;
  const ReminderSlot(this.id, this.when, {required this.repeatsDaily});
}
