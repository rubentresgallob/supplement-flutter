import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/supplements_remote_datasource.dart';
import '../../../data/datasources/intakes_remote_datasource.dart';
import '../../../data/datasources/local_storage_datasource.dart';
import '../../../core/services/notification_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final SupplementsRemoteDataSource _supplementsDataSource;
  final IntakesRemoteDataSource _intakesDataSource;
  final LocalStorageDataSource _localStorage;

  HomeBloc(this._supplementsDataSource, this._intakesDataSource, this._localStorage)
      : super(HomeInitialState()) {
    on<HomeLoadSupplementsEvent>(_onLoadSupplements);
    on<HomeRefreshEvent>(_onRefresh);
    on<HomeMarkIntakeTakenEvent>(_onMarkIntakeTaken);
    on<HomeMarkAllIntakesTakenEvent>(_onMarkAllIntakesTaken);
    on<HomeDeleteSupplementEvent>(_onDeleteSupplement);
  }

  Future<void> _onLoadSupplements(
    HomeLoadSupplementsEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(HomeLoadingState());

      final supplements = await _supplementsDataSource.getUserSupplements();

      if (supplements.isEmpty) {
        emit(HomeEmptyState());
        return;
      }

      final progressData = await _intakesDataSource.getProgressToday();
      final progress = <String, int>{};

      for (final supplement in supplements) {
        final supplementProgress = progressData[supplement.id];
        progress[supplement.id] = supplementProgress != null
            ? supplementProgress['taken'] as int
            : 0;
      }

      final userStreak = await _intakesDataSource.getUserStreak();

      // Sincronizar notificaciones: cancelar si completo, reprogramar si pendiente
      for (final s in supplements) {
        final taken = progress[s.id] ?? 0;
        final savedTime = _localStorage.getNotificationTime(s.id);
        if (savedTime == null) continue;

        final notifId = NotificationService.idFromSupplementId(s.id);
        if (taken >= s.timesPerDay) {
          await NotificationService.cancelReminder(notifId);
        } else {
          await NotificationService.scheduleReminder(
            id: notifId,
            supplementName: s.name,
            time: savedTime,
          );
        }
      }

      emit(HomeLoadedState(
        supplements: supplements,
        progress: progress,
        userStreak: userStreak,
      ));
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }

  Future<void> _onRefresh(
    HomeRefreshEvent event,
    Emitter<HomeState> emit,
  ) async {
    add(HomeLoadSupplementsEvent());
  }

  Future<void> _onMarkIntakeTaken(
    HomeMarkIntakeTakenEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _intakesDataSource.createIntake(userSupplementId: event.supplementId);
      add(HomeLoadSupplementsEvent());
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }

  Future<void> _onMarkAllIntakesTaken(
    HomeMarkAllIntakesTakenEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      for (int i = 0; i < event.remaining; i++) {
        await _intakesDataSource.createIntake(userSupplementId: event.supplementId);
      }
      add(HomeLoadSupplementsEvent());
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteSupplement(
    HomeDeleteSupplementEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _supplementsDataSource.deleteUserSupplement(event.supplementId);
      await NotificationService.cancelReminder(
        NotificationService.idFromSupplementId(event.supplementId),
      );
      add(HomeLoadSupplementsEvent());
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }
}
