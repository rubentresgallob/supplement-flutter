import '../../domain/entities/intake.dart';

/// Modelo de toma para serialización JSON
class IntakeModel extends Intake {
  const IntakeModel({
    required super.id,
    required super.userId,
    required super.userSupplementId,
    required super.takenAt,
    required super.createdAt,
  });
  
  /// Crea un IntakeModel desde JSON
  factory IntakeModel.fromJson(Map<String, dynamic> json) {
    return IntakeModel(
      id: json['id'].toString(),
      userId: (json['user_id'] ?? json['userId']).toString(),
      userSupplementId: (json['user_supplement_id'] ?? json['userSupplementId']).toString(),
      takenAt: DateTime.parse((json['taken_at'] ?? json['takenAt']) as String),
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
    );
  }
  
  /// Convierte el IntakeModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userSupplementId': userSupplementId,
      'takenAt': takenAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
