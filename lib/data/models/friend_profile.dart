import 'package:equatable/equatable.dart';

/// Lo que un amigo lleva tomado hoy de un suplemento.
class FriendSupplementToday extends Equatable {
  final String name;
  final String form;
  final num dosageAmount;
  final String dosageUnit;
  final int taken;
  final int expected;

  const FriendSupplementToday({
    required this.name,
    required this.form,
    required this.dosageAmount,
    required this.dosageUnit,
    required this.taken,
    required this.expected,
  });

  bool get complete => taken >= expected;

  /// "5 g · polvo"
  String get detail {
    final amount = dosageAmount % 1 == 0 ? dosageAmount.toInt() : dosageAmount;
    return '${'$amount'.replaceAll('.', ',')} $dosageUnit · $form';
  }

  factory FriendSupplementToday.fromJson(Map<String, dynamic> json) =>
      FriendSupplementToday(
        name: json['name'] as String? ?? 'Suplemento',
        form: json['form'] as String? ?? '',
        dosageAmount: json['dosageAmount'] as num? ?? 0,
        dosageUnit: json['dosageUnit'] as String? ?? '',
        taken: json['taken'] as int? ?? 0,
        expected: json['expected'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [name, form, dosageAmount, dosageUnit, taken, expected];
}

/// Perfil de un amigo (`GET /friends/:id/profile`).
class FriendProfile extends Equatable {
  final int id;
  final String username;
  final DateTime? memberSince;

  /// Objetos equipados (slot → código): su Capsu, medalla y banner.
  final Map<String, String> equipped;
  final int currentStreak;
  final int longestStreak;
  final int activeSupplements;
  final int adherence30Days;

  /// Si comparte su stack y su calendario con sus amigos.
  final bool sharing;

  /// Su stack de hoy; `null` si no lo comparte.
  final List<FriendSupplementToday>? today;

  const FriendProfile({
    required this.id,
    required this.username,
    required this.memberSince,
    required this.equipped,
    required this.currentStreak,
    required this.longestStreak,
    required this.activeSupplements,
    required this.adherence30Days,
    required this.sharing,
    required this.today,
  });

  int get takenToday => (today ?? const []).fold(0, (a, s) => a + s.taken);
  int get expectedToday => (today ?? const []).fold(0, (a, s) => a + s.expected);

  /// Suplementos a los que hoy aún les falta alguna toma.
  List<FriendSupplementToday> get pendingToday =>
      (today ?? const []).where((s) => !s.complete).toList();

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final streak = json['streak'] as Map<String, dynamic>? ?? const {};
    final today = json['today'] as Map<String, dynamic>?;
    final since = json['memberSince'] as String?;
    return FriendProfile(
      id: user['id'] as int? ?? 0,
      username: user['username'] as String? ?? '',
      memberSince: since == null ? null : DateTime.tryParse(since),
      equipped: (json['equipped'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v.toString())),
      currentStreak: streak['current'] as int? ?? 0,
      longestStreak: streak['longest'] as int? ?? 0,
      activeSupplements: json['activeSupplements'] as int? ?? 0,
      adherence30Days: (json['last30DaysAdherence'] as num? ?? 0).round(),
      sharing: json['sharing'] as bool? ?? false,
      today: today == null
          ? null
          : (today['supplements'] as List<dynamic>? ?? [])
              .map((s) => FriendSupplementToday.fromJson(s as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id, username, memberSince, equipped, currentStreak, longestStreak,
        activeSupplements, adherence30Days, sharing, today,
      ];
}
