import 'package:equatable/equatable.dart';

/// Entidad de racha
class Streak extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastCompletedDate;
  
  const Streak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastCompletedDate,
  });
  
  @override
  List<Object?> get props => [currentStreak, longestStreak, lastCompletedDate];
}
