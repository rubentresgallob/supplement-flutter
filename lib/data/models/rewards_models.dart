import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';

/// Premio recién ganado (día completo, logro, objetivo semanal...).
class GrantedReward extends Equatable {
  final String ref;
  final String reason;
  final int points;
  final String? item;

  const GrantedReward({
    required this.ref,
    required this.reason,
    required this.points,
    this.item,
  });

  factory GrantedReward.fromJson(Map<String, dynamic> json) => GrantedReward(
        ref: json['ref'] as String,
        reason: json['reason'] as String,
        points: json['points'] as int,
        item: json['item'] as String?,
      );

  static List<GrantedReward> listFrom(dynamic json) => (json as List<dynamic>? ?? [])
      .map((e) => GrantedReward.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  List<Object?> get props => [ref];
}

/// Objeto de la tienda (el catálogo lo manda el backend).
class ShopItem extends Equatable {
  final String code;
  final String name;
  final String description;
  final String category; // consumable · medal · banner · capsu
  final String? slot;
  final int? price; // null = exclusivo (se gana con un logro)
  final String icon;
  final String rarity; // common · rare · epic · legendary
  final int maxOwned;
  final List<Color> colors;
  final int owned;
  final bool equipped;

  /// Solo se puede comprar con el plan Pro.
  final bool proOnly;

  const ShopItem({
    required this.code,
    required this.name,
    required this.description,
    required this.category,
    required this.slot,
    required this.price,
    required this.icon,
    required this.rarity,
    required this.maxOwned,
    required this.colors,
    required this.owned,
    required this.equipped,
    this.proOnly = false,
  });

  bool get exclusive => price == null;
  bool get isOwned => owned > 0;
  bool get isConsumable => category == 'consumable';
  bool get isMaxed => owned >= maxOwned;

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        code: json['code'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String,
        slot: json['slot'] as String?,
        price: json['price'] as int?,
        icon: json['icon'] as String? ?? '🎁',
        rarity: json['rarity'] as String? ?? 'common',
        maxOwned: json['maxOwned'] as int? ?? 1,
        colors: (json['colors'] as List<dynamic>? ?? [])
            .map((c) => parseHexColor(c as String))
            .toList(),
        owned: json['owned'] as int? ?? 0,
        equipped: json['equipped'] as bool? ?? false,
        proOnly: json['proOnly'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [code, owned, equipped, price];
}

class WeeklyGoal extends Equatable {
  final String code;
  final String title;
  final int progress;
  final int target;
  final int points;
  final bool completed;

  const WeeklyGoal({
    required this.code,
    required this.title,
    required this.progress,
    required this.target,
    required this.points,
    required this.completed,
  });

  factory WeeklyGoal.fromJson(Map<String, dynamic> json) => WeeklyGoal(
        code: json['code'] as String,
        title: json['title'] as String,
        progress: json['progress'] as int,
        target: json['target'] as int,
        points: json['points'] as int,
        completed: json['completed'] as bool,
      );

  @override
  List<Object?> get props => [code, progress, completed];
}

class Achievement extends Equatable {
  final String code;
  final String title;
  final String description;
  final String icon;
  final int points;
  final String? rewardItem;
  final bool unlocked;

  const Achievement({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.rewardItem,
    required this.unlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        code: json['code'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String,
        points: json['points'] as int,
        rewardItem: json['rewardItem'] as String?,
        unlocked: json['unlocked'] as bool,
      );

  @override
  List<Object?> get props => [code, unlocked];
}

/// Racha perdida que aún se puede recuperar con protectores (ventana de 48 h).
class StreakRepair extends Equatable {
  final List<String> missedDays;
  final int protectorsNeeded;
  final int protectorsOwned;

  const StreakRepair({
    required this.missedDays,
    required this.protectorsNeeded,
    required this.protectorsOwned,
  });

  int get missingProtectors => protectorsNeeded - protectorsOwned;

  factory StreakRepair.fromJson(Map<String, dynamic> json) => StreakRepair(
        missedDays: (json['missedDays'] as List<dynamic>).cast<String>(),
        protectorsNeeded: json['protectorsNeeded'] as int,
        protectorsOwned: json['protectorsOwned'] as int,
      );

  @override
  List<Object?> get props => [missedDays, protectorsOwned];
}

class RewardsSummary extends Equatable {
  final int points;
  final List<GrantedReward> newRewards;
  final int currentStreak;
  final int longestStreak;
  final List<String> repairedDays;
  final StreakRepair? repair;
  final int protectors;
  final List<WeeklyGoal> weeklyGoals;
  final List<Achievement> achievements;

  /// slot → código del objeto equipado
  final Map<String, String> equipped;

  const RewardsSummary({
    required this.points,
    required this.newRewards,
    required this.currentStreak,
    required this.longestStreak,
    required this.repairedDays,
    required this.repair,
    required this.protectors,
    required this.weeklyGoals,
    required this.achievements,
    required this.equipped,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    final streak = json['streak'] as Map<String, dynamic>;
    return RewardsSummary(
      points: json['points'] as int,
      newRewards: GrantedReward.listFrom(json['newRewards']),
      currentStreak: streak['current'] as int,
      longestStreak: streak['longest'] as int,
      repairedDays: (streak['repairedDays'] as List<dynamic>? ?? []).cast<String>(),
      repair: streak['repair'] == null
          ? null
          : StreakRepair.fromJson(streak['repair'] as Map<String, dynamic>),
      protectors: json['protectors'] as int? ?? 0,
      weeklyGoals: (json['weeklyGoals'] as List<dynamic>)
          .map((e) => WeeklyGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      achievements: (json['achievements'] as List<dynamic>)
          .map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList(),
      equipped: (json['equipped'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v as String)),
    );
  }

  @override
  List<Object?> get props =>
      [points, currentStreak, repair, protectors, weeklyGoals, achievements, equipped];
}

class PointsMovement {
  final int amount;
  final String reason;
  final DateTime createdAt;

  const PointsMovement({
    required this.amount,
    required this.reason,
    required this.createdAt,
  });

  factory PointsMovement.fromJson(Map<String, dynamic> json) => PointsMovement(
        amount: json['amount'] as int,
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

/// "#FF6B35" → Color
Color parseHexColor(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse(clean.length == 6 ? 'FF$clean' : clean, radix: 16));
}
