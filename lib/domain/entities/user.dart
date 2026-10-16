import 'package:equatable/equatable.dart';

/// Entidad de usuario
class User extends Equatable {
  final String id;
  final String email;
  final String username;
  final DateTime createdAt;

  /// La versión vigente de los Términos o la Política es más nueva que la aceptada
  /// (o faltan consentimientos): hay que mostrar la pantalla de reaceptación.
  final bool needsLegalAcceptance;

  /// Resumen de los cambios que tiene que volver a aceptar.
  final List<String> legalChanges;

  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.createdAt,
    this.needsLegalAcceptance = false,
    this.legalChanges = const [],
  });

  User copyWith({bool? needsLegalAcceptance}) => User(
        id: id,
        email: email,
        username: username,
        createdAt: createdAt,
        needsLegalAcceptance: needsLegalAcceptance ?? this.needsLegalAcceptance,
        legalChanges: legalChanges,
      );

  @override
  List<Object> get props => [id, email, username, createdAt, needsLegalAcceptance, legalChanges];
}
