import 'package:flutter/material.dart';
import '../../../domain/entities/streak.dart';
import '../../../core/constants/app_constants.dart';

class StreakBadge extends StatelessWidget {
  final Streak streak;
  const StreakBadge({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    final current = streak.currentStreak;
    final longest = streak.longestStreak;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1200), Color(0xFF0F1623)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: current > 0
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: current > 0
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: current > 0
                  ? AppGradients.brand
                  : const LinearGradient(colors: [
                      AppColors.bgCardElevated,
                      AppColors.bgCardElevated
                    ]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: current > 0
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                      )
                    ]
                  : [],
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: current > 0 ? Colors.white : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$current',
                      style: TextStyle(
                        color: current > 0 ? AppColors.primary : AppColors.textMuted,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'días seguidos',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  current == 0
                      ? 'Empieza tu racha hoy'
                      : current == 1
                          ? '¡Buen comienzo!'
                          : current >= 7
                              ? '¡Racha increíble!'
                              : '¡Sigue así!',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Mejor racha',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded,
                      color: AppColors.gold, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$longest días',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
