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
    on<HomeMarkEverythingTakenEvent>(_onMarkEverythingTaken);
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

      // Sincronizar recordatorios. Si hoy ya está completo, el aviso de hoy
      // se salta pero el recordatorio diario SIGUE activo (antes se cancelaba
      // y al día siguiente no llegaba nada si no se abría la app).
      final withReminder = supplements
          .where((s) => _localStorage.getNotificationTime(s.id) != null)
          .length;
      final daysAhead = NotificationService.daysAheadFor(withReminder);
      for (final s in supplements) {
        final savedTime = _localStorage.getNotificationTime(s.id);
        if (savedTime == null) continue;
        final taken = progress[s.id] ?? 0;
        await NotificationService.scheduleReminder(
          id: NotificationService.idFromSupplementId(s.id),
          supplementName: s.name,
          time: savedTime,
          skipToday: taken >= s.timesPerDay,
          daysAhead: daysAhead,
        );
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

  /// Suplementos con un registro en curso: evita tomas duplicadas si se pulsa
  /// dos veces antes de que la lista se recargue.
  final _registering = <String>{};

  /// Registra [count] tomas de cada suplemento de [intakes] y recarga.
  Future<void> _register(Map<String, int> intakes, Emitter<HomeState> emit) async {
    final pending = {
      for (final e in intakes.entries)
        if (e.value > 0 && !_registering.contains(e.key)) e.key: e.value,
    };
    if (pending.isEmpty) return;
    _registering.addAll(pending.keys);
    try {
      for (final e in pending.entries) {
        for (var i = 0; i < e.value; i++) {
          await _intakesDataSource.createIntake(userSupplementId: e.key);
        }
      }
      add(HomeLoadSupplementsEvent());
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    } finally {
      _registering.removeAll(pending.keys);
    }
  }

  Future<void> _onMarkIntakeTaken(
    HomeMarkIntakeTakenEvent event,
    Emitter<HomeState> emit,
  ) =>
      _register({event.supplementId: 1}, emit);

  Future<void> _onMarkAllIntakesTaken(
    HomeMarkAllIntakesTakenEvent event,
    Emitter<HomeState> emit,
  ) =>
      _register({event.supplementId: event.remaining}, emit);

  /// Todo lo que falta hoy, de todos los suplementos.
  Future<void> _onMarkEverythingTaken(
    HomeMarkEverythingTakenEvent event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeLoadedState) return;
    await _register({
      for (final s in current.supplements)
        s.id: s.timesPerDay - (current.progress[s.id] ?? 0),
    }, emit);
  }

  Future<void> _onDeleteSupplement(
    HomeDeleteSupplementEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      await _supplementsDataSource.deleteUserSupplement(event.supplementId);
      await _localStorage.removeNotificationTime(event.supplementId);
      await NotificationService.cancelReminder(
        NotificationService.idFromSupplementId(event.supplementId),
      );
      add(HomeLoadSupplementsEvent());
    } catch (e) {
      emit(HomeErrorState(e.toString()));
    }
  }
}
