import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location madrid;

  setUpAll(() {
    tzdata.initializeTimeZones();
    madrid = tz.getLocation('Europe/Madrid');
  });

  tz.TZDateTime at(int y, int m, int d, int h, int min) =>
      tz.TZDateTime(madrid, y, m, d, h, min);

  group('nextOccurrence', () {
    test('si la hora aún no ha llegado, suena hoy', () {
      final next = NotificationService.nextOccurrence(
          const TimeOfDay(hour: 21, minute: 0), at(2026, 9, 29, 10, 0));
      expect(next, at(2026, 9, 29, 21, 0));
    });

    test('si la hora ya pasó, suena mañana', () {
      final next = NotificationService.nextOccurrence(
          const TimeOfDay(hour: 9, minute: 0), at(2026, 9, 29, 10, 0));
      expect(next, at(2026, 9, 30, 9, 0));
    });

    test('justo a la misma hora no se programa en el pasado', () {
      final next = NotificationService.nextOccurrence(
          const TimeOfDay(hour: 10, minute: 0), at(2026, 9, 29, 10, 0));
      expect(next, at(2026, 9, 30, 10, 0));
    });

    test('con skipToday (tomas completadas) el primer aviso es mañana', () {
      final next = NotificationService.nextOccurrence(
          const TimeOfDay(hour: 21, minute: 0), at(2026, 9, 29, 10, 0),
          skipToday: true);
      expect(next, at(2026, 9, 30, 21, 0));
    });

    test('respeta el cambio de hora de octubre (sigue sonando a las 9:00)', () {
      // En 2026 el horario de invierno empieza el domingo 25 de octubre
      final next = NotificationService.nextOccurrence(
          const TimeOfDay(hour: 9, minute: 0), at(2026, 10, 24, 22, 0));
      expect(next.day, 25);
      expect(next.hour, 9);
      expect(next.minute, 0);
    });

    test('fin de mes pasa al día 1 del mes siguiente', () {
      final next = NotificationService.nextOccurrence(
          const TimeOfDay(hour: 8, minute: 0), at(2026, 9, 30, 23, 0));
      expect(next, at(2026, 10, 1, 8, 0));
    });
  });

  group('idFromSupplementId', () {
    test('usa el ID numérico del backend tal cual (estable)', () {
      expect(NotificationService.idFromSupplementId('42'), 42);
      expect(NotificationService.idFromSupplementId('1'), 1);
    });

    test('IDs no numéricos dan siempre el mismo resultado', () {
      final a = NotificationService.idFromSupplementId('abc-123');
      expect(NotificationService.idFromSupplementId('abc-123'), a);
      // Valor fijo: si cambia, los recordatorios existentes quedarían huérfanos
      expect(a, isNonNegative);
      expect(a, lessThan(100000000));
    });

    test('suplementos distintos no comparten ID', () {
      final ids = {for (var i = 1; i <= 500; i++) NotificationService.idFromSupplementId('$i')};
      expect(ids.length, 500);
    });
  });

  group('reminderPlan', () {
    test('tomas pendientes: UN recordatorio diario repetido', () {
      final plan = NotificationService.reminderPlan(
          id: 7, time: const TimeOfDay(hour: 21, minute: 0),
          now: at(2026, 9, 29, 10, 0), skipToday: false);
      expect(plan, hasLength(1));
      expect(plan.single.id, 7);
      expect(plan.single.repeatsDaily, isTrue);
      expect(plan.single.when, at(2026, 9, 29, 21, 0));
    });

    test('tomas completas: NADA hoy y avisos sueltos desde mañana', () {
      final plan = NotificationService.reminderPlan(
          id: 7, time: const TimeOfDay(hour: 21, minute: 0),
          now: at(2026, 9, 29, 10, 0), skipToday: true);
      expect(plan, hasLength(NotificationService.maxDaysAhead));
      expect(plan.every((s) => !s.repeatsDaily), isTrue);
      expect(plan.any((s) => s.when.day == 29), isFalse, reason: 'no debe sonar hoy');
      expect(plan.first.when, at(2026, 9, 30, 21, 0));
      expect(plan.last.when, at(2026, 10, 5, 21, 0));
      // IDs propios, sin chocar con el diario ni entre sí
      final ids = plan.map((s) => s.id).toSet();
      expect(ids.length, plan.length);
      expect(ids.contains(7), isFalse);
    });

    test('respeta el límite de 64 notificaciones pendientes de iOS', () {
      for (final n in [1, 5, 9, 10, 20, 56, 80]) {
        final days = NotificationService.daysAheadFor(n);
        expect(days * n <= 64 || days == 1, isTrue, reason: '$n suplementos -> $days días');
        expect(days, greaterThanOrEqualTo(1));
      }
      expect(NotificationService.daysAheadFor(3), NotificationService.maxDaysAhead);
    });

    test('los IDs de avisos sueltos caben en 32 bits', () {
      final plan = NotificationService.reminderPlan(
          id: NotificationService.idFromSupplementId('99999999'),
          time: const TimeOfDay(hour: 8, minute: 0),
          now: at(2026, 9, 29, 10, 0), skipToday: true);
      expect(plan.every((s) => s.id < 2147483647), isTrue);
    });
  });
}
