import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/core/design/design.dart';
import 'package:supplement_tracker/data/datasources/intakes_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/local_storage_datasource.dart';
import 'package:supplement_tracker/data/datasources/supplements_remote_datasource.dart';
import 'package:supplement_tracker/data/models/intake_model.dart';
import 'package:supplement_tracker/data/models/streak_model.dart';
import 'package:supplement_tracker/data/models/user_supplement_model.dart';
import 'package:supplement_tracker/presentation/home/bloc/home_bloc.dart';
import 'package:supplement_tracker/presentation/home/bloc/home_event.dart';
import 'package:supplement_tracker/presentation/home/bloc/home_state.dart';
import 'package:supplement_tracker/presentation/home/widgets/supplement_card.dart';

UserSupplementModel _sup(String id, String name, int times) => UserSupplementModel(
      id: id,
      userId: 'u',
      name: name,
      form: 'cápsula',
      dosageAmount: 1,
      dosageUnit: 'g',
      timesPerDay: times,
      schedules: const [],
      active: true,
      createdAt: DateTime(2026),
    );

class _FakeSupplements implements SupplementsRemoteDataSource {
  @override
  Future<List<UserSupplementModel>> getUserSupplements() async =>
      [_sup('a', 'Omega 3', 3), _sup('b', 'Magnesio', 1)];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIntakes implements IntakesRemoteDataSource {
  final taken = <String, int>{'a': 1};
  final created = <String>[];

  /// Si se asigna, cada registro espera a que se complete (simula la red).
  Completer<void>? gate;

  @override
  Future<IntakeModel> createIntake({required String userSupplementId, DateTime? takenAt}) async {
    await gate?.future;
    created.add(userSupplementId);
    taken[userSupplementId] = (taken[userSupplementId] ?? 0) + 1;
    return IntakeModel(
      id: 'i${created.length}',
      userId: 'u',
      userSupplementId: userSupplementId,
      takenAt: DateTime(2026),
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<Map<String, dynamic>> getProgressToday() async =>
      {for (final e in taken.entries) e.key: {'taken': e.value}};

  @override
  Future<StreakModel> getUserStreak() async =>
      const StreakModel(currentStreak: 2, longestStreak: 5);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStorage implements LocalStorageDataSource {
  @override
  TimeOfDay? getNotificationTime(String supplementId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<HomeLoadedState> _loaded(HomeBloc bloc) async =>
    (bloc.state is HomeLoadedState
        ? bloc.state
        : await bloc.stream.firstWhere((s) => s is HomeLoadedState)) as HomeLoadedState;

void main() {
  group('HomeBloc: registrar tomas', () {
    test('"registrar todo" apunta solo lo que falta de cada suplemento', () async {
      final intakes = _FakeIntakes();
      final bloc = HomeBloc(_FakeSupplements(), intakes, _FakeStorage());
      bloc.add(HomeLoadSupplementsEvent());
      await _loaded(bloc);

      bloc.add(HomeMarkEverythingTakenEvent());
      final done = await bloc.stream.firstWhere((s) =>
          s is HomeLoadedState && s.progress['a'] == 3 && s.progress['b'] == 1);

      expect(done, isA<HomeLoadedState>());
      // Omega 3 llevaba 1 de 3 → 2 tomas; Magnesio 0 de 1 → 1 toma
      expect(intakes.created, ['a', 'a', 'b']);
      await bloc.close();
    });

    test('pulsar dos veces seguidas no duplica las tomas', () async {
      final intakes = _FakeIntakes();
      final bloc = HomeBloc(_FakeSupplements(), intakes, _FakeStorage());
      bloc.add(HomeLoadSupplementsEvent());
      await _loaded(bloc);

      intakes.gate = Completer<void>();
      bloc.add(const HomeMarkAllIntakesTakenEvent('a', 2));
      bloc.add(const HomeMarkAllIntakesTakenEvent('a', 2));
      bloc.add(HomeMarkEverythingTakenEvent());
      await Future<void>.delayed(Duration.zero);
      intakes.gate!.complete();
      await bloc.stream.firstWhere((s) => s is HomeLoadedState && s.progress['a'] == 3);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(intakes.created.where((id) => id == 'a').length, 2);
      await bloc.close();
    });
  });

  group('SupplementCard', () {
    Future<void> pump(WidgetTester tester, {required int taken, required int times,
        VoidCallback? one, VoidCallback? all}) {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      return tester.pumpWidget(MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SupplementCard(
            supplement: _sup('a', 'Omega 3', times),
            taken: taken,
            onMarkTaken: one ?? () {},
            onMarkAllTaken: all ?? () {},
          ),
        ),
      ));
    }

    testWidgets('con varias tomas pendientes ofrece una o todas', (tester) async {
      var one = 0, all = 0;
      await pump(tester, taken: 1, times: 3, one: () => one++, all: () => all++);

      expect(find.text('1 de 3'), findsOneWidget);
      await tester.tap(find.text('Una toma'));
      await tester.tap(find.text('Todas (2)'));
      expect((one, all), (1, 1));
    });

    testWidgets('si solo falta una, no aparece "Todas"', (tester) async {
      await pump(tester, taken: 0, times: 1);
      expect(find.text('Registrar toma'), findsOneWidget);
      expect(find.textContaining('Todas'), findsNothing);
    });

    testWidgets('completado: sin botones', (tester) async {
      await pump(tester, taken: 2, times: 2);
      expect(find.text('Completado por hoy'), findsOneWidget);
      expect(find.text('Registrar toma'), findsNothing);
    });
  });
}
