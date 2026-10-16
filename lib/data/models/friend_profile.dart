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
/// Siempre: nombre, objetos equipados y mes de alta. El progreso y el stack de hoy
/// solo llegan si el amigo tiene activado el interruptor correspondiente.
class FriendProfile extends Equatable {
  final int id;
  final String username;

  /// Mes y año de alta (día 1 de ese mes).
  final DateTime? memberSince;

  /// Objetos equipados (slot → código): su Capsu, medalla y banner.
  final Map<String, String> equipped;

  final bool sharesProgress;
  final bool sharesSupplements;

  /// `null` si no comparte su progreso.
  final int? currentStreak;
  final int? longestStreak;
  final int? activeSupplements;
  final int? adherence30Days;

  /// Su stack de hoy; `null` si no comparte sus suplementos.
  final List<FriendSupplementToday>? today;

  const FriendProfile({
    required this.id,
    required this.username,
    required this.memberSince,
    required this.equipped,
    required this.sharesProgress,
    required this.sharesSupplements,
    this.currentStreak,
    this.longestStreak,
    this.activeSupplements,
    this.adherence30Days,
    this.today,
  });

  int get takenToday => (today ?? const []).fold(0, (a, s) => a + s.taken);
  int get expectedToday => (today ?? const []).fold(0, (a, s) => a + s.expected);

  /// Suplementos a los que hoy aún les falta alguna toma.
  List<FriendSupplementToday> get pendingToday =>
      (today ?? const []).where((s) => !s.complete).toList();

  /// "2026-10" → 1 de octubre de 2026.
  static DateTime? parseMonth(String? value) {
    final m = RegExp(r'^(\d{4})-(\d{2})').firstMatch(value ?? '');
    return m == null ? null : DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!));
  }

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final progress = json['progress'] as Map<String, dynamic>?;
    final streak = progress?['streak'] as Map<String, dynamic>?;
    final today = json['today'] as Map<String, dynamic>?;
    return FriendProfile(
      id: user['id'] as int? ?? 0,
      username: user['username'] as String? ?? '',
      memberSince: parseMonth(json['memberSince'] as String?),
      equipped: (json['equipped'] as Map<String, dynamic>? ?? const {})
          .map((k, v) => MapEntry(k, v.toString())),
      sharesProgress: json['sharesProgress'] as bool? ?? false,
      sharesSupplements: json['sharesSupplements'] as bool? ?? false,
      currentStreak: streak?['current'] as int?,
      longestStreak: streak?['longest'] as int?,
      activeSupplements: progress?['activeSupplements'] as int?,
      adherence30Days: (progress?['last30DaysAdherence'] as num?)?.round(),
      today: today == null
          ? null
          : (today['supplements'] as List<dynamic>? ?? [])
              .map((s) => FriendSupplementToday.fromJson(s as Map<String, dynamic>))
              .toList(),
    );
  }

  @override
  List<Object?> get props => [
        id, username, memberSince, equipped, sharesProgress, sharesSupplements,
        currentStreak, longestStreak, activeSupplements, adherence30Days, today,
      ];
}
