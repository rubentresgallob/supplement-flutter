import 'package:equatable/equatable.dart';

/// Entidad de toma de suplemento
class Intake extends Equatable {
  final String id;
  final String userId;
  final String userSupplementId;
  final DateTime takenAt;
  final DateTime createdAt;
  
  const Intake({
    required this.id,
    required this.userId,
    required this.userSupplementId,
    required this.takenAt,
    required this.createdAt,
  });
  
  @override
  List<Object> get props => [id, userId, userSupplementId, takenAt, createdAt];
}
