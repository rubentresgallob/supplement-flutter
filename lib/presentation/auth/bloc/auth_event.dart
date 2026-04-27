import 'package:equatable/equatable.dart';

/// Eventos del AuthBloc
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object> get props => [];
}

/// Evento para verificar el estado de autenticación
class AuthCheckStatusEvent extends AuthEvent {}

/// Evento para registrar un nuevo usuario
class AuthRegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String username;
  
  const AuthRegisterEvent({
    required this.email,
    required this.password,
    required this.username,
  });
  
  @override
  List<Object> get props => [email, password, username];
}

/// Evento para iniciar sesión
class AuthLoginEvent extends AuthEvent {
  final String email;
  final String password;
  
  const AuthLoginEvent({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

/// Evento para cerrar sesión
class AuthLogoutEvent extends AuthEvent {}
