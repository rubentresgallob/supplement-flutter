import 'package:equatable/equatable.dart';

/// Entidad de suplemento del usuario
class UserSupplement extends Equatable {
  final String id;
  final String userId;
  final String? supplementDatabaseId;
  final String name;
  final String form;
  final double dosageAmount;
  final String dosageUnit;
  final int timesPerDay;
  final List<String> schedules;
  final bool active;
  final DateTime createdAt;

  /// Pro: unidades que quedan (null = sin control de stock).
  final double? stockUnits;

  /// Unidades que se gastan en cada toma.
  final double unitsPerIntake;
  
  const UserSupplement({
    required this.id,
    required this.userId,
    this.supplementDatabaseId,
    required this.name,
    required this.form,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.timesPerDay,
    required this.schedules,
    required this.active,
    required this.createdAt,
    this.stockUnits,
    this.unitsPerIntake = 1,
  });

  bool get tracksStock => stockUnits != null;

  /// Días que quedan con el ritmo actual (null si no hay control de stock).
  int? get stockDaysLeft {
    final units = stockUnits;
    if (units == null) return null;
    final perDay = unitsPerIntake * timesPerDay;
    return perDay <= 0 ? null : (units / perDay).floor();
  }

  /// Avisar cuando quede una semana o menos.
  bool get isStockLow => (stockDaysLeft ?? 999) <= 7;
  
  @override
  List<Object?> get props => [
        id,
        userId,
        supplementDatabaseId,
        name,
        form,
        dosageAmount,
        dosageUnit,
        timesPerDay,
        schedules,
        active,
        createdAt,
        stockUnits,
        unitsPerIntake,
      ];
}
