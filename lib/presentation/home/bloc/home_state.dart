import 'package:equatable/equatable.dart';
import '../../../domain/entities/user_supplement.dart';
import '../../../domain/entities/streak.dart';

/// Estados del HomeBloc
abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

/// Estado inicial
class HomeInitialState extends HomeState {}

/// Estado de carga
class HomeLoadingState extends HomeState {}

/// Estado de cargado con éxito
class HomeLoadedState extends HomeState {
  final List<UserSupplement> supplements;
  final Map<String, int> progress; // supplementId -> tomas realizadas hoy
  final Streak userStreak;
  
  const HomeLoadedState({
    required this.supplements,
    required this.progress,
    required this.userStreak,
  });
  
  @override
  List<Object> get props => [supplements, progress, userStreak];
}

/// Estado de error
class HomeErrorState extends HomeState {
  final String message;
  
  const HomeErrorState(this.message);
  
  @override
  List<Object> get props => [message];
}

/// Estado vacío (sin suplementos)
class HomeEmptyState extends HomeState {}
