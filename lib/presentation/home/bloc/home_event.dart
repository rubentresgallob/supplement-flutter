import 'package:equatable/equatable.dart';

/// Eventos del HomeBloc
abstract class HomeEvent extends Equatable {
  const HomeEvent();
  
  @override
  List<Object> get props => [];
}

/// Evento para cargar los suplementos
class HomeLoadSupplementsEvent extends HomeEvent {}

/// Evento para refrescar los datos
class HomeRefreshEvent extends HomeEvent {}

/// Evento para marcar una toma como realizada (+1)
class HomeMarkIntakeTakenEvent extends HomeEvent {
  final String supplementId;

  const HomeMarkIntakeTakenEvent(this.supplementId);

  @override
  List<Object> get props => [supplementId];
}

/// Evento para registrar todas las tomas restantes de golpe
class HomeMarkAllIntakesTakenEvent extends HomeEvent {
  final String supplementId;
  final int remaining;

  const HomeMarkAllIntakesTakenEvent(this.supplementId, this.remaining);

  @override
  List<Object> get props => [supplementId, remaining];
}

/// Evento para deshacer la última toma de hoy de un suplemento
class HomeUndoIntakeEvent extends HomeEvent {
  final String supplementId;

  const HomeUndoIntakeEvent(this.supplementId);

  @override
  List<Object> get props => [supplementId];
}

/// Evento para registrar de golpe todo lo que falta hoy, de todos los suplementos
class HomeMarkEverythingTakenEvent extends HomeEvent {}

/// Evento para eliminar un suplemento de la rutina
class HomeDeleteSupplementEvent extends HomeEvent {
  final String supplementId;

  const HomeDeleteSupplementEvent(this.supplementId);

  @override
  List<Object> get props => [supplementId];
}
