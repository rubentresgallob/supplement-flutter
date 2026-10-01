import 'package:equatable/equatable.dart';

class ProFeature {
  final String code;
  final String icon;
  final String title;
  final String description;

  const ProFeature({
    required this.code,
    required this.icon,
    required this.title,
    required this.description,
  });

  factory ProFeature.fromJson(Map<String, dynamic> json) => ProFeature(
        code: json['code'] as String,
        icon: json['icon'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
      );
}

class ProPrice {
  final String id;
  final String label;
  final String price;
  final String period;
  final String? note;
  final bool highlight;

  const ProPrice({
    required this.id,
    required this.label,
    required this.price,
    required this.period,
    this.note,
    this.highlight = false,
  });

  factory ProPrice.fromJson(Map<String, dynamic> json) => ProPrice(
        id: json['id'] as String,
        label: json['label'] as String,
        price: json['price'] as String,
        period: json['period'] as String,
        note: json['note'] as String?,
        highlight: json['highlight'] as bool? ?? false,
      );
}

/// Estado del plan Pro del usuario.
class ProStatus extends Equatable {
  final bool isPro;
  final DateTime? proUntil;
  final String? source; // test · revenuecat
  final bool testMode;
  final int trialDays;
  final List<ProPrice> prices;
  final List<ProFeature> features;

  const ProStatus({
    required this.isPro,
    this.proUntil,
    this.source,
    this.testMode = false,
    this.trialDays = 7,
    this.prices = const [],
    this.features = const [],
  });

  static const free = ProStatus(isPro: false);

  factory ProStatus.fromJson(Map<String, dynamic> json) => ProStatus(
        isPro: json['isPro'] as bool,
        proUntil: json['proUntil'] == null
            ? null
            : DateTime.parse(json['proUntil'] as String).toLocal(),
        source: json['source'] as String?,
        testMode: json['testMode'] as bool? ?? false,
        trialDays: json['trialDays'] as int? ?? 7,
        prices: (json['prices'] as List<dynamic>? ?? [])
            .map((e) => ProPrice.fromJson(e as Map<String, dynamic>))
            .toList(),
        features: (json['features'] as List<dynamic>? ?? [])
            .map((e) => ProFeature.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [isPro, proUntil, source, testMode];
}

// ─── Estadísticas ───────────────────────────────────────────────────────────

class StatsDay {
  final DateTime date;
  final int taken;
  final int expected;
  final bool complete;

  const StatsDay({
    required this.date,
    required this.taken,
    required this.expected,
    required this.complete,
  });

  double get ratio => expected == 0 ? 0 : (taken / expected).clamp(0, 1).toDouble();

  factory StatsDay.fromJson(Map<String, dynamic> json) => StatsDay(
        date: DateTime.parse(json['date'] as String),
        taken: json['taken'] as int,
        expected: json['expected'] as int,
        complete: json['complete'] as bool,
      );
}

class StatsSupplement {
  final String name;
  final int taken;
  final int expected;
  final int adherence;

  const StatsSupplement({
    required this.name,
    required this.taken,
    required this.expected,
    required this.adherence,
  });

  factory StatsSupplement.fromJson(Map<String, dynamic> json) => StatsSupplement(
        name: json['name'] as String? ?? 'Suplemento',
        taken: json['taken'] as int,
        expected: json['expected'] as int,
        adherence: json['adherence'] as int,
      );
}

class StatsWeekday {
  final String weekday;
  final int completionRate;
  final int days;

  const StatsWeekday({
    required this.weekday,
    required this.completionRate,
    required this.days,
  });

  factory StatsWeekday.fromJson(Map<String, dynamic> json) => StatsWeekday(
        weekday: json['weekday'] as String,
        completionRate: json['completionRate'] as int,
        days: json['days'] as int,
      );
}

class StatsReport {
  final int periodDays;
  final DateTime from;
  final DateTime to;
  final List<StatsDay> days;
  final List<StatsSupplement> supplements;
  final List<StatsWeekday> weekdays;
  final int adherence;
  final int completeDays;
  final int totalDays;
  final int intakes;
  final int currentStreak;
  final int longestStreak;
  final String? bestWeekday;
  final String? worstWeekday;

  const StatsReport({
    required this.periodDays,
    required this.from,
    required this.to,
    required this.days,
    required this.supplements,
    required this.weekdays,
    required this.adherence,
    required this.completeDays,
    required this.totalDays,
    required this.intakes,
    required this.currentStreak,
    required this.longestStreak,
    this.bestWeekday,
    this.worstWeekday,
  });

  factory StatsReport.fromJson(Map<String, dynamic> json, int periodDays) {
    final s = json['summary'] as Map<String, dynamic>;
    return StatsReport(
      periodDays: periodDays,
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      days: (json['days'] as List<dynamic>)
          .map((e) => StatsDay.fromJson(e as Map<String, dynamic>))
          .toList(),
      supplements: (json['supplements'] as List<dynamic>)
          .map((e) => StatsSupplement.fromJson(e as Map<String, dynamic>))
          .toList(),
      weekdays: (json['weekdays'] as List<dynamic>)
          .map((e) => StatsWeekday.fromJson(e as Map<String, dynamic>))
          .toList(),
      adherence: s['adherence'] as int,
      completeDays: s['completeDays'] as int,
      totalDays: s['totalDays'] as int,
      intakes: s['intakes'] as int,
      currentStreak: s['currentStreak'] as int? ?? 0,
      longestStreak: s['longestStreak'] as int? ?? 0,
      bestWeekday: s['bestWeekday'] as String?,
      worstWeekday: s['worstWeekday'] as String?,
    );
  }
}
