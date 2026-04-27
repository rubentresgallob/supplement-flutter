import 'package:equatable/equatable.dart';

/// Clase base para todos los fallos
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Fallo de servidor (5xx)
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Fallo de red (sin conexión)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Fallo de autenticación (401)
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Fallo de validación (400)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Fallo de no encontrado (404)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}
