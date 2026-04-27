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
  });
  
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
      ];
}
