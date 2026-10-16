import '../../domain/entities/user.dart';

/// Modelo de usuario para serialización JSON
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.createdAt,
    super.needsLegalAcceptance,
    super.legalChanges,
  });
  
  /// Crea un UserModel desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String,
      username: json['username'] as String,
      createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
      needsLegalAcceptance: json['legal']?['needsAcceptance'] as bool? ?? false,
      legalChanges: (json['legal']?['changes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
  
  /// Convierte el UserModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
