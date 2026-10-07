import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supplement_tracker/core/design/design.dart';
import 'package:supplement_tracker/data/datasources/intakes_remote_datasource.dart';
import 'package:supplement_tracker/data/models/calendar_models.dart';
import 'package:supplement_tracker/presentation/calendar/pages/calendar_page.dart';

/// Respuesta con la misma forma que devuelve el backend (`GET /calendar`).
Map<String, dynamic> monthJson(int year, int month, {required DateTime today}) {
  String key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  final last = DateTime(year, month + 1, 0).day;
  final days = <Map<String, dynamic>>[];
  for (var n = 1; n <= last; n++) {
    final date = DateTime(year, month, n);
    final future = date.isAfter(today);
    // Patrón fijo: día 2 sin tomar, día 3 a medias, el resto completo
    final status = future
        ? 'future'
        : n == 2
            ? 'missed'
            : n == 3
                ? 'partial'
                : 'complete';
    final omega = status == 'complete' ? 2 : status == 'partial' ? 1 : 0;
    final creatina = status == 'missed' || future ? 0 : 1;
    days.add({
      'date': key(date),
      'status': status,
      'taken': omega + creatina,
      'expected': future ? 0 : 3,
      'protected': n == 2,
      'supplements': future
          ? []
          : [
              {'id': 1, 'name': 'Creatina', 'taken': creatina, 'expected': 1},
              {'id': 2, 'name': 'Omega 3', 'taken': omega, 'expected': 2, 'retired': true},
            ],
    });
  }
  int count(String s) => days.where((d) => d['status'] == s).length;
  return {
    'month': '$year-${month.toString().padLeft(2, '0')}',
    'today': key(today),
    'firstTracked': key(DateTime(today.year, today.month - 1, 10)),
    'days': days,
    'summary': {
      'complete': count('complete'),
      'partial': count('partial'),
      'missed': count('missed'),
      'protected': 1,
    },
  };
}

class FakeCalendarSource implements IntakesRemoteDataSource {
  final requested = <String>[];
  final DateTime today;
  FakeCalendarSource(this.today);

  @override
  Future<CalendarMonth> getCalendar(int year, int month) async {
    requested.add('$year-$month');
    return CalendarMonth.fromJson(monthJson(year, month, today: today));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget calendarApp(IntakesRemoteDataSource source) => MaterialApp(
      theme: buildAppTheme(),
      home: RepositoryProvider<IntakesRemoteDataSource>.value(
        value: source,
        child: const CalendarPage(),
      ),
    );

void main() {
  test('lee el mes que devuelve el backend', () {
    final month = CalendarMonth.fromJson(monthJson(2026, 10, today: DateTime(2026, 10, 7)));
    expect(month.days, hasLength(31));
    expect(month.days[1].status, CalendarDayStatus.missed);
    expect(month.days[1].isProtected, isTrue);
    expect(month.days[2].missing.single.name, 'Omega 3');
    expect(month.days[7].status, CalendarDayStatus.future);
    expect((month.completeDays, month.partialDays, month.missedDays), (5, 1, 1));
  });

  testWidgets('muestra el mes, el detalle de un día y navega al mes anterior', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // El calendario usa la fecha real para saber cuál es el mes actual
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final source = FakeCalendarSource(today);
    await tester.pumpWidget(calendarApp(source));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Calendario'), findsOneWidget);
    expect(find.text('completos'), findsOneWidget);
    expect(source.requested, ['${now.year}-${now.month}']);
    // No se puede ir al futuro
    expect(
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, LucideIcons.chevronRight)).onPressed,
        isNull);

    // Mes anterior: ya ha pasado entero, así que el día 3 está a medias
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final previous = DateTime(now.year, now.month - 1);
    expect(source.requested.last, '${previous.year}-${previous.month}');
    expect(find.text('Toca un día para ver qué tomaste y qué te faltó.'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Te faltó Omega 3'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    // Un suplemento que se quitó sigue en el historial, marcado como tal
    expect(find.text('Ya no está en tu rutina'), findsOneWidget);

    await tester.tap(find.text('2'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No registraste ninguna toma'), findsOneWidget);
    expect(find.text('Un protector salvó tu racha este día'), findsOneWidget);
  });
}
