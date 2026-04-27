import '../../domain/entities/streak.dart';

/// Modelo de racha para serialización JSON
class StreakModel extends Streak {
  const StreakModel({
    required super.currentStreak,
    required super.longestStreak,
    super.lastCompletedDate,
  });
  
  /// Crea un StreakModel desde JSON
  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      lastCompletedDate: json['last_completed_date'] != null
          ? DateTime.parse(json['last_completed_date'] as String)
          : null,
    );
  }
  
  /// Convierte el StreakModel a JSON
  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_completed_date': lastCompletedDate?.toIso8601String(),
    };
  }
}
