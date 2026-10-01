import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/data/datasources/intakes_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/pro_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/rewards_remote_datasource.dart';
import 'package:supplement_tracker/data/models/pro_models.dart';
import 'package:supplement_tracker/data/models/rewards_models.dart';
import 'package:supplement_tracker/domain/entities/user_supplement.dart';
import 'package:supplement_tracker/presentation/pro/bloc/pro_cubit.dart';
import 'package:supplement_tracker/presentation/pro/pages/pro_page.dart';
import 'package:supplement_tracker/presentation/pro/pages/stats_page.dart';
import 'package:supplement_tracker/presentation/rewards/bloc/rewards_cubit.dart';

// Respuestas con la misma forma que el backend
const _statusJson = {
  'isPro': false,
  'proUntil': null,
  'source': null,
  'testMode': true,
  'trialDays': 7,
  'prices': [
    {'id': 'monthly', 'label': 'Mensual', 'price': '2,99 €', 'period': 'al mes', 'highlight': false},
    {'id': 'yearly', 'label': 'Anual', 'price': '19,99 €', 'period': 'al año', 'note': 'ahorras un 44 %', 'highlight': true},
  ],
  'features': [
    {'code': 'stock', 'icon': '📦', 'title': 'Control de stock', 'description': 'Te avisa.'},
  ],
};

final _statsJson = {
  'from': '2026-09-29',
  'to': '2026-10-01',
  'days': [
    {'date': '2026-09-29', 'taken': 1, 'expected': 2, 'complete': false},
    {'date': '2026-09-30', 'taken': 2, 'expected': 2, 'complete': true},
    {'date': '2026-10-01', 'taken': 2, 'expected': 2, 'complete': true},
  ],
  'supplements': [
    {'id': 1, 'name': 'Creatina', 'taken': 5, 'expected': 6, 'adherence': 83},
  ],
  'weekdays': [
    for (final d in ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'])
      {'weekday': d, 'completionRate': d == 'Martes' ? 0 : 100, 'days': d == 'Martes' || d == 'Miércoles' ? 1 : 0},
  ],
  'summary': {
    'adherence': 83, 'completeDays': 2, 'totalDays': 3, 'intakes': 5,
    'bestWeekday': 'Miércoles', 'worstWeekday': 'Martes', 'currentStreak': 2, 'longestStreak': 2,
  },
};

class _FakePro implements ProRemoteDataSource {
  bool isPro;
  int activations = 0;
  _FakePro({this.isPro = false});

  ProStatus get _status => ProStatus.fromJson({..._statusJson, 'isPro': isPro});

  @override
  Future<ProStatus> getStatus() async => _status;

  @override
  Future<ProStatus> activateTest() async {
    activations++;
    isPro = true;
    return _status;
  }

  @override
  Future<ProStatus> deactivateTest() async {
    isPro = false;
    return _status;
  }

  @override
  Future<StatsReport> getStats(int days) async => StatsReport.fromJson(_statsJson, days);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRewards implements RewardsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeIntakes implements IntakesRemoteDataSource {
  final _controller = StreamController<List<GrantedReward>>.broadcast();
  @override
  Stream<List<GrantedReward>> get rewards => _controller.stream;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserSupplement _supplement({double? stock, double perIntake = 1, int timesPerDay = 2}) =>
    UserSupplement(
      id: '1',
      userId: '1',
      name: 'Creatina',
      form: 'polvo',
      dosageAmount: 5,
      dosageUnit: 'g',
      timesPerDay: timesPerDay,
      schedules: const ['mañana'],
      active: true,
      createdAt: DateTime(2026, 9, 1),
      stockUnits: stock,
      unitsPerIntake: perIntake,
    );

Widget _app(Widget child, {required _FakePro fake, required ProCubit pro}) {
  final rewards = RewardsCubit(_FakeRewards(), _FakeIntakes());
  return MaterialApp(
    home: RepositoryProvider<ProRemoteDataSource>.value(
      value: fake,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: pro),
          BlocProvider.value(value: rewards),
        ],
        child: child,
      ),
    ),
  );
}

Future<void> _frames(WidgetTester tester, [int n = 15]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('Modelos Pro', () {
    test('lee el estado del plan', () {
      final s = ProStatus.fromJson(_statusJson);
      expect(s.isPro, isFalse);
      expect(s.testMode, isTrue);
      expect(s.prices.last.highlight, isTrue);
      expect(s.features.single.title, 'Control de stock');
    });

    test('lee las estadísticas', () {
      final r = StatsReport.fromJson(_statsJson, 7);
      expect(r.days, hasLength(3));
      expect(r.days.first.ratio, 0.5);
      expect(r.supplements.single.adherence, 83);
      expect(r.worstWeekday, 'Martes');
    });
  });

  group('Stock', () {
    test('calcula los días que quedan', () {
      expect(_supplement().stockDaysLeft, isNull);
      expect(_supplement(stock: 60).stockDaysLeft, 30); // 2 tomas/día
      expect(_supplement(stock: 60, perIntake: 2).stockDaysLeft, 15);
      expect(_supplement(stock: 60).isStockLow, isFalse);
      expect(_supplement(stock: 10).isStockLow, isTrue); // 5 días
      expect(_supplement(stock: 0).stockDaysLeft, 0);
    });
  });

  group('Pantallas Pro', () {
    testWidgets('sin Pro, las estadísticas piden desbloquear', (tester) async {
      final fake = _FakePro();
      final pro = ProCubit(fake);
      await tester.pumpWidget(_app(const StatsPage(), fake: fake, pro: pro));
      await _frames(tester);
      expect(find.text('Desbloquear con Pro'), findsOneWidget);
    });

    testWidgets('con Pro, se ven las estadísticas reales', (tester) async {
      final fake = _FakePro(isPro: true);
      final pro = ProCubit(fake);
      await tester.runAsync(pro.load);
      await tester.pumpWidget(_app(const StatsPage(), fake: fake, pro: pro));
      await _frames(tester);
      expect(find.text('83%'), findsWidgets);
      expect(find.text('Creatina'), findsOneWidget);
      expect(find.textContaining('martes'), findsOneWidget); // consejo del peor día
    });

    testWidgets('"Hazte Pro" en modo de prueba activa Pro', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final fake = _FakePro();
      final pro = ProCubit(fake);
      await tester.runAsync(pro.load);
      await tester.pumpWidget(_app(const ProPage(), fake: fake, pro: pro));
      await _frames(tester);

      expect(find.text('19,99 €'), findsOneWidget);
      expect(find.textContaining('Modo de prueba'), findsOneWidget);
      await tester.tap(find.text('Empezar 7 días gratis'));
      await _frames(tester, 20);
      expect(fake.activations, 1);
      expect(pro.state.isPro, isTrue);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
