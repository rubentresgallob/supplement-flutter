import '../../domain/entities/user_supplement.dart';

/// Modelo de suplemento del usuario para serialización JSON
class UserSupplementModel extends UserSupplement {
  const UserSupplementModel({
    required super.id,
    required super.userId,
    super.supplementDatabaseId,
    required super.name,
    required super.form,
    required super.dosageAmount,
    required super.dosageUnit,
    required super.timesPerDay,
    required super.schedules,
    required super.active,
    required super.createdAt,
  });
  
  /// Crea un UserSupplementModel desde JSON
  factory UserSupplementModel.fromJson(Map<String, dynamic> json) {
    final dbId = json['supplement_database_id'] ?? json['supplementDatabaseId'];
    final nameFromDb = json['supplement_database']?['name'] as String?;
    final customName = (json['custom_name'] ?? json['customName']) as String?;
    return UserSupplementModel(
      id: json['id'].toString(),
      userId: (json['user_id'] ?? json['userId']).toString(),
      supplementDatabaseId: dbId?.toString(),
      name: (customName?.isNotEmpty == true ? customName : nameFromDb) ?? '',
      form: json['form'] as String,
      dosageAmount: (json['dosage_amount'] ?? json['dosageAmount'] as num).toDouble(),
      dosageUnit: (json['dosage_unit'] ?? json['dosageUnit']) as String,
      timesPerDay: (json['times_per_day'] ?? json['timesPerDay']) as int,
      schedules: (json['schedules'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      active: json['active'] as bool,
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
    );
  }
  
  /// Convierte el UserSupplementModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'supplementDatabaseId': supplementDatabaseId,
      'customName': name,
      'form': form,
      'dosageAmount': dosageAmount,
      'dosageUnit': dosageUnit,
      'timesPerDay': timesPerDay,
      'schedules': schedules,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
