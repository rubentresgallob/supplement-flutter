import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/core/widgets/mascot/capsu.dart';
import 'package:supplement_tracker/data/datasources/intakes_remote_datasource.dart';
import 'package:supplement_tracker/data/datasources/rewards_remote_datasource.dart';
import 'package:supplement_tracker/data/models/rewards_models.dart';
import 'package:supplement_tracker/presentation/rewards/bloc/rewards_cubit.dart';
import 'package:supplement_tracker/presentation/rewards/pages/shop_page.dart';
import 'package:supplement_tracker/data/datasources/pro_remote_datasource.dart';
import 'package:supplement_tracker/data/models/pro_models.dart';
import 'package:supplement_tracker/presentation/pro/bloc/pro_cubit.dart';

class _FakePro implements ProRemoteDataSource {
  @override
  Future<ProStatus> getStatus() async => ProStatus.free;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Respuestas con la misma forma que devuelve el backend
Map<String, dynamic> _summaryJson({int points = 200, Map<String, String> equipped = const {}}) => {
      'points': points,
      'newRewards': [],
      'streak': {
        'current': 0,
        'longest': 4,
        'repairedDays': [],
        'repair': {
          'missedDays': ['2026-09-30'],
          'protectorsNeeded': 1,
          'protectorsOwned': 0,
        },
      },
      'protectors': 0,
      'weeklyGoals': [
        {'code': 'weekly_5', 'title': 'Completa 5 días esta semana', 'progress': 2, 'target': 5, 'points': 30, 'completed': false},
      ],
      'achievements': [
        {'code': 'first_intake', 'title': 'Primer paso', 'description': 'Registra tu primera toma.', 'icon': '💊', 'points': 20, 'rewardItem': null, 'unlocked': true, 'unlockedAt': '2026-10-01T10:00:00.000Z'},
        {'code': 'streak_30', 'title': 'Un mes', 'description': 'Racha de 30 días.', 'icon': '🔥', 'points': 200, 'rewardItem': 'medal_streak_30', 'unlocked': false, 'unlockedAt': null},
      ],
      'equipped': equipped,
    };

List<ShopItem> _items({bool capOwned = false}) => [
      ShopItem.fromJson(const {
        'code': 'streak_freeze', 'name': 'Protector de racha', 'description': 'Protege tu racha.',
        'category': 'consumable', 'price': 150, 'icon': '🛡️', 'rarity': 'rare', 'maxOwned': 2,
        'owned': 0, 'equipped': false,
      }),
      ShopItem.fromJson({
        'code': 'capsu_head_cap', 'name': 'Gorra deportiva', 'description': 'Capsu listo para entrenar.',
        'category': 'capsu', 'slot': 'capsu_head', 'price': 120, 'icon': '🧢', 'rarity': 'common',
        'maxOwned': 1, 'owned': capOwned ? 1 : 0, 'equipped': false,
      }),
      ShopItem.fromJson(const {
        'code': 'banner_ocean', 'name': 'Océano', 'description': 'Hidratación ante todo.',
        'category': 'banner', 'slot': 'banner', 'price': 150, 'icon': '🌊', 'rarity': 'common',
        'maxOwned': 1, 'colors': ['#2193B0', '#6DD5ED'], 'owned': 0, 'equipped': false,
      }),
      ShopItem.fromJson(const {
        'code': 'medal_streak_30', 'name': 'Llama de 30 días', 'description': 'Exclusiva.',
        'category': 'medal', 'slot': 'medal', 'price': null, 'icon': '🔥', 'rarity': 'epic',
        'maxOwned': 1, 'owned': 0, 'equipped': false,
      }),
    ];

class _FakeRewards implements RewardsRemoteDataSource {
  int points = 200;
  bool capOwned = false;
  Map<String, String> equipped = {};
  final bought = <String>[];

  @override
  Future<RewardsSummary> getSummary() async =>
      RewardsSummary.fromJson(_summaryJson(points: points, equipped: equipped));

  @override
  Future<List<ShopItem>> getShopItems() async => _items(capOwned: capOwned);

  @override
  Future<List<GrantedReward>> buy(String itemCode) async {
    bought.add(itemCode);
    points -= 120;
    capOwned = true;
    return const [GrantedReward(ref: 'ach:first_item', reason: 'Logro: De compras', points: 10)];
  }

  @override
  Future<void> equip(String itemCode) async => equipped['capsu_head'] = itemCode;

  @override
  Future<void> unequip(String itemCode) async => equipped.remove('capsu_head');

  @override
  Future<List<PointsMovement>> getHistory() async => [];
}

class _FakeIntakes implements IntakesRemoteDataSource {
  final controller = StreamController<List<GrantedReward>>.broadcast();

  @override
  Stream<List<GrantedReward>> get rewards => controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Capsu anima sin fin: avanzamos fotogramas en vez de pumpAndSettle.
Future<void> _frames(WidgetTester tester, [int n = 15]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('Modelos', () {
    test('lee el resumen de recompensas del backend', () {
      final s = RewardsSummary.fromJson(_summaryJson(equipped: {'capsu_head': 'capsu_head_cap'}));
      expect(s.points, 200);
      expect(s.repair!.missingProtectors, 1);
      expect(s.weeklyGoals.single.progress, 2);
      expect(s.achievements.where((a) => a.unlocked).length, 1);
      expect(s.equipped['capsu_head'], 'capsu_head_cap');
    });

    test('lee objetos de la tienda: exclusivos y colores de banner', () {
      final items = _items();
      expect(items[3].exclusive, isTrue);
      expect(items[2].colors.first, const Color(0xFF2193B0));
      expect(items[0].isConsumable, isTrue);
    });
  });

  group('CapsuOutfit', () {
    test('se construye desde lo equipado y permite probar objetos', () {
      final outfit = CapsuOutfit.fromEquipped(const {'capsu_head': 'capsu_head_cap', 'medal': 'medal_gold'});
      expect(outfit.head, 'capsu_head_cap');
      final probando = outfit.withSlot('capsu_face', 'capsu_face_sunglasses');
      expect(probando.face, 'capsu_face_sunglasses');
      expect(probando.head, 'capsu_head_cap');
    });

    testWidgets('Capsu se dibuja con todos los accesorios sin errores', (tester) async {
      const outfits = [
        CapsuOutfit(head: 'capsu_head_cap', face: 'capsu_face_sunglasses', neck: 'capsu_neck_scarf', skin: 'capsu_skin_mint'),
        CapsuOutfit(head: 'capsu_head_party', face: 'capsu_face_glasses', neck: 'capsu_neck_medal', skin: 'capsu_skin_gold'),
        CapsuOutfit(head: 'capsu_head_crown', face: 'desconocido'),
      ];
      for (final outfit in outfits) {
        for (final mood in [CapsuMood.idle, CapsuMood.celebrate, CapsuMood.shy]) {
          await tester.pumpWidget(MaterialApp(home: Center(child: Capsu(mood: mood, outfit: outfit))));
          await tester.pump(const Duration(milliseconds: 300));
          expect(tester.takeException(), isNull);
        }
      }
    });
  });

  group('RewardsCubit', () {
    test('carga saldo y tienda, y celebra los premios de las tomas', () async {
      final intakes = _FakeIntakes();
      final cubit = RewardsCubit(_FakeRewards(), intakes);
      final celebrations = <RewardsCelebration>[];
      cubit.celebrations.listen(celebrations.add);

      await cubit.load();
      expect(cubit.state.points, 200);
      expect(cubit.state.items, hasLength(4));

      intakes.controller.add(const [GrantedReward(ref: 'day:2026-10-01', reason: 'Día completo', points: 10)]);
      await Future<void>.delayed(Duration.zero);
      expect(celebrations.single.totalPoints, 10);
      await cubit.close();
    });

    test('comprar descuenta puntos y celebra el logro', () async {
      final fake = _FakeRewards();
      final cubit = RewardsCubit(fake, _FakeIntakes());
      final celebrations = <RewardsCelebration>[];
      cubit.celebrations.listen(celebrations.add);
      await cubit.load();

      expect(await cubit.buy('capsu_head_cap'), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(fake.bought, ['capsu_head_cap']);
      expect(cubit.state.points, 80);
      expect(cubit.state.item('capsu_head_cap')!.isOwned, isTrue);
      expect(celebrations.last.rewards.single.ref, 'ach:first_item');
      await cubit.close();
    });
  });

  group('Tienda', () {
    testWidgets('muestra objetos y permite comprar y equipar la gorra', (tester) async {
      // Pantalla de móvil (360 x 800) para detectar desbordes
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final fake = _FakeRewards();
      final cubit = RewardsCubit(fake, _FakeIntakes());
      await tester.runAsync(cubit.load);

      await tester.pumpWidget(MaterialApp(
        home: RepositoryProvider<RewardsRemoteDataSource>.value(
          value: fake,
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider(create: (_) => ProCubit(_FakePro())),
            ],
            child: const ShopPage(),
          ),
        ),
      ));
      await _frames(tester);

      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Gorra deportiva'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('🔒 Exclusivo'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('Primer paso'), findsNothing); // logros más abajo
      await tester.scrollUntilVisible(find.text('Primer paso'), 200,
          scrollable: find.byType(Scrollable).first);
      await tester.scrollUntilVisible(find.text('Gorra deportiva'), -200,
          scrollable: find.byType(Scrollable).first);
      await _frames(tester, 5);

      await tester.tap(find.text('Gorra deportiva'));
      await _frames(tester);
      expect(find.text('Comprar · 💎 120'), findsOneWidget);

      await tester.tap(find.text('Comprar · 💎 120'));
      await _frames(tester, 30);
      expect(fake.bought, ['capsu_head_cap']);
      // Se equipa sola al comprarla
      expect(fake.equipped['capsu_head'], 'capsu_head_cap');

      // Capsu sigue probándose la gorra en el probador
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 1500));
      await _frames(tester);
      expect(find.text('Probando:\nGorra deportiva'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      await cubit.close();
    });
  });
}
