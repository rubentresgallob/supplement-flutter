import 'package:equatable/equatable.dart';

/// Estado de un día del calendario (lo calcula el backend).
enum CalendarDayStatus {
  /// Todo tomado.
  complete,

  /// Algo tomado, pero no todo.
  partial,

  /// Nada tomado.
  missed,

  /// Hoy, todavía sin empezar.
  pending,

  /// No había nada que tomar (aún no tenía suplementos).
  none,

  /// Día que no ha llegado.
  future;

  static CalendarDayStatus parse(String? value) => CalendarDayStatus.values
      .firstWhere((s) => s.name == value, orElse: () => CalendarDayStatus.none);
}

/// Lo que se tomó de un suplemento en un día.
class CalendarSupplementDay extends Equatable {
  final String id;
  final String name;
  final int taken;
  final int expected;

  /// El usuario ya lo quitó de su rutina; se conserva en el historial.
  final bool retired;

  const CalendarSupplementDay({
    required this.id,
    required this.name,
    required this.taken,
    required this.expected,
    this.retired = false,
  });

  bool get complete => taken >= expected;

  factory CalendarSupplementDay.fromJson(Map<String, dynamic> json) =>
      CalendarSupplementDay(
        id: json['id'].toString(),
        name: json['name'] as String? ?? 'Suplemento',
        taken: json['taken'] as int? ?? 0,
        expected: json['expected'] as int? ?? 0,
        retired: json['retired'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, name, taken, expected, retired];
}

class CalendarDay extends Equatable {
  final DateTime date;
  final CalendarDayStatus status;
  final int taken;
  final int expected;

  /// Día salvado por un protector de racha.
  final bool isProtected;
  final List<CalendarSupplementDay> supplements;

  const CalendarDay({
    required this.date,
    required this.status,
    required this.taken,
    required this.expected,
    required this.isProtected,
    required this.supplements,
  });

  /// Suplementos a los que les faltó alguna toma ese día.
  List<CalendarSupplementDay> get missing =>
      supplements.where((s) => !s.complete).toList();

  factory CalendarDay.fromJson(Map<String, dynamic> json) => CalendarDay(
        date: DateTime.parse(json['date'] as String),
        status: CalendarDayStatus.parse(json['status'] as String?),
        taken: json['taken'] as int? ?? 0,
        expected: json['expected'] as int? ?? 0,
        isProtected: json['protected'] as bool? ?? false,
        supplements: (json['supplements'] as List<dynamic>? ?? [])
            .map((s) => CalendarSupplementDay.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [date, status, taken, expected, isProtected, supplements];
}

/// Un mes del calendario de progreso.
class CalendarMonth extends Equatable {
  final int year;
  final int month;
  final DateTime today;

  /// Primer día con algún suplemento; antes no hay nada que mostrar.
  final DateTime? firstTracked;
  final List<CalendarDay> days;
  final int completeDays;
  final int partialDays;
  final int missedDays;
  final int protectedDays;

  const CalendarMonth({
    required this.year,
    required this.month,
    required this.today,
    required this.firstTracked,
    required this.days,
    required this.completeDays,
    required this.partialDays,
    required this.missedDays,
    required this.protectedDays,
  });

  factory CalendarMonth.fromJson(Map<String, dynamic> json) {
    final parts = (json['month'] as String).split('-');
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final first = json['firstTracked'] as String?;
    return CalendarMonth(
      year: int.parse(parts[0]),
      month: int.parse(parts[1]),
      today: DateTime.parse(json['today'] as String),
      firstTracked: first == null ? null : DateTime.parse(first),
      days: (json['days'] as List<dynamic>? ?? [])
          .map((d) => CalendarDay.fromJson(d as Map<String, dynamic>))
          .toList(),
      completeDays: summary['complete'] as int? ?? 0,
      partialDays: summary['partial'] as int? ?? 0,
      missedDays: summary['missed'] as int? ?? 0,
      protectedDays: summary['protected'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [year, month, today, firstTracked, days, completeDays, partialDays, missedDays, protectedDays];
}
