class ServerException implements Exception {
  final String message;
  ServerException(this.message);
  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
  @override
  String toString() => message;
}

/// El servidor responde 403 con code "EMAIL_NOT_VERIFIED": hay que meter el código del email.
class EmailNotVerifiedException implements Exception {
  final String message;
  EmailNotVerifiedException([this.message = 'Verifica tu email con el código que te hemos enviado']);
  @override
  String toString() => message;
}

/// El servidor responde 403 con code "PRO_REQUIRED": la función es del plan Pro.
class ProRequiredException implements Exception {
  final String message;
  ProRequiredException([this.message = 'Esta función es del plan Pro']);
  @override
  String toString() => message;
}
