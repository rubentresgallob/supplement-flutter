import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/core/design/design.dart';
import 'package:supplement_tracker/data/datasources/friends_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/intakes_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/rewards_remote_datasource.dart';
import 'package:supplement_tracker/data/models/calendar_models.dart';
import 'package:supplement_tracker/data/models/friend_profile.dart';
import 'package:supplement_tracker/data/models/rewards_models.dart';
import 'package:supplement_tracker/presentation/friends/pages/friend_profile_page.dart';
import 'package:supplement_tracker/presentation/rewards/bloc/rewards_cubit.dart';
import 'calendar_test.dart' show monthJson;

/// Respuesta con la misma forma que devuelve el backend (`GET /friends/:id/profile`).
Map<String, dynamic> profileJson({bool progress = true, bool supplements = true}) => {
      'user': {'id': 2, 'username': 'laura'},
      'memberSince': '2026-03',
      'equipped': {'capsu_head': 'capsu_head_crown', 'banner': 'banner_galaxy'},
      'sharesProgress': progress,
      'sharesSupplements': supplements,
      'progress': progress
          ? {
              'streak': {'current': 12, 'longest': 30},
              'activeSupplements': 2,
              'last30DaysAdherence': 87,
            }
          : null,
      'today': supplements
          ? {
              'supplements': [
                {'id': 1, 'name': 'Creatina', 'form': 'polvo', 'dosageAmount': 5, 'dosageUnit': 'g', 'taken': 1, 'expected': 1},
                {'id': 2, 'name': 'Omega 3', 'form': 'cápsula', 'dosageAmount': 1.5, 'dosageUnit': 'g', 'taken': 1, 'expected': 2},
              ],
              'taken': 2,
              'expected': 3,
              'complete': false,
            }
          : null,
    };

class FakeFriends implements FriendsRemoteDataSource {
  final bool progress;
  final bool supplements;
  final calendarRequests = <String>[];
  FakeFriends({this.progress = true, this.supplements = true});

  @override
  Future<FriendProfile> getFriendProfile(int friendId) async =>
      FriendProfile.fromJson(profileJson(progress: progress, supplements: supplements));

  @override
  Future<CalendarMonth> getFriendCalendar(int friendId, int year, int month) async {
    calendarRequests.add('$friendId:$year-$month');
    final now = DateTime.now();
    return CalendarMonth.fromJson(
        monthJson(year, month, today: DateTime(now.year, now.month, now.day)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoRewards implements RewardsRemoteDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoIntakes implements IntakesRemoteDataSource {
  @override
  Stream<List<GrantedReward>> get rewards => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget friendApp(FriendsRemoteDataSource source,
        {VoidCallback? onMotivate, VoidCallback? onRemove}) =>
    MaterialApp(
      theme: buildAppTheme(),
      home: RepositoryProvider<FriendsRemoteDataSource>.value(
        value: source,
        child: BlocProvider(
          create: (_) => RewardsCubit(_NoRewards(), _NoIntakes()),
          child: FriendProfilePage(
            friendId: 2,
            username: 'laura',
            onMotivate: onMotivate ?? () {},
            onRemove: onRemove ?? () {},
          ),
        ),
      ),
    );

/// Capsu anima sin fin: avanzamos fotogramas en vez de pumpAndSettle.
Future<void> frames(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  test('lee el perfil de un amigo que devuelve el backend', () {
    final p = FriendProfile.fromJson(profileJson());
    expect(p.username, 'laura');
    expect(p.equipped['capsu_head'], 'capsu_head_crown');
    expect((p.currentStreak, p.longestStreak, p.adherence30Days), (12, 30, 87));
    expect((p.takenToday, p.expectedToday), (2, 3));
    expect(p.pendingToday.single.name, 'Omega 3');
    expect(p.today!.last.detail, '1,5 g · cápsula');

    expect(p.memberSince, DateTime(2026, 3));

    final hidden = FriendProfile.fromJson(profileJson(progress: false, supplements: false));
    expect(hidden.sharesProgress, isFalse);
    expect(hidden.currentStreak, isNull);
    expect(hidden.today, isNull);
  });

  testWidgets('muestra su racha, su stack de hoy y abre su calendario', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    var motivated = 0;
    final source = FakeFriends();
    await tester.pumpWidget(friendApp(source, onMotivate: () => motivated++));
    await frames(tester);

    expect(find.text('12'), findsOneWidget); // racha
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('Le falta Omega 3'), findsOneWidget);
    expect(find.text('2 de 3'), findsOneWidget);
    expect(find.text('Creatina'), findsOneWidget);

    await tester.tap(find.text('Motivar'));
    expect(motivated, 1);

    await tester.scrollUntilVisible(find.text('Ver su calendario'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Ver su calendario'));
    await frames(tester, 20);
    expect(find.text('Calendario de laura'), findsOneWidget);
    expect(source.calendarRequests.single, startsWith('2:'));
  });

  testWidgets('con los interruptores apagados no se ve su progreso, ni su stack, ni su calendario', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(friendApp(FakeFriends(progress: false, supplements: false)));
    await frames(tester);

    expect(find.text('laura no comparte su progreso'), findsOneWidget);
    expect(find.text('laura no comparte sus suplementos'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(find.text('Creatina'), findsNothing);
    expect(find.text('Ver su calendario'), findsNothing);
    expect(find.text('Motivar'), findsOneWidget);
  });

  testWidgets('solo con "Compartir mi progreso" se ve la racha pero no el stack', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(friendApp(FakeFriends(progress: true, supplements: false)));
    await frames(tester);

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Creatina'), findsNothing);
  });
}
