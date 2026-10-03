import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

/// Estados del AuthBloc
abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AuthInitialState extends AuthState {}

/// Estado de carga
class AuthLoadingState extends AuthState {}

/// Estado de autenticado
class AuthAuthenticatedState extends AuthState {
  final User user;
  
  const AuthAuthenticatedState(this.user);
  
  @override
  List<Object> get props => [user];
}

/// Estado de no autenticado
class AuthUnauthenticatedState extends AuthState {}

/// Falta verificar el email: la pantalla de login/registro abre la del código
class AuthNeedsVerificationState extends AuthState {
  final String email;

  const AuthNeedsVerificationState(this.email);

  @override
  List<Object> get props => [email];
}

/// Estado de error
class AuthErrorState extends AuthState {
  final String message;
  
  const AuthErrorState(this.message);
  
  @override
  List<Object> get props => [message];
}
