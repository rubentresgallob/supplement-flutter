import 'package:equatable/equatable.dart';

/// Entidad de usuario
class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
  });
  
  @override
  List<Object> get props => [id, email, username, createdAt];
}
