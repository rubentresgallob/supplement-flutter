import 'package:flutter/material.dart';
import '../../../domain/entities/user_supplement.dart';
import '../../../core/constants/app_constants.dart';

class SupplementCard extends StatelessWidget {
  final UserSupplement supplement;
  final int taken;
  final VoidCallback onMarkTaken;
  final VoidCallback onMarkAllTaken;

  const SupplementCard({
    super.key,
    required this.supplement,
    required this.taken,
    required this.onMarkTaken,
    required this.onMarkAllTaken,
  });

  @override
  Widget build(BuildContext context) {
    final total = supplement.timesPerDay;
    final progress = total > 0 ? (taken / total).clamp(0.0, 1.0) : 0.0;
    final isComplete = taken >= total;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: AppGradients.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: isComplete
            ? [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isComplete),
            const SizedBox(height: 16),
            _buildProgressBar(progress, isComplete),
            const SizedBox(height: 12),
            _buildFooter(taken, total, isComplete),
            if (supplement.schedules.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildScheduleChips(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isComplete) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isComplete
                  ? [
                      AppColors.success.withValues(alpha: 0.2),
                      AppColors.success.withValues(alpha: 0.1)
                    ]
                  : [
                      AppColors.primary.withValues(alpha: 0.2),
                      AppColors.primary.withValues(alpha: 0.05)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isComplete
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            _icon(supplement.form),
            color: isComplete ? AppColors.success : AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                supplement.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '${supplement.dosageAmount % 1 == 0 ? supplement.dosageAmount.toInt() : supplement.dosageAmount} ${supplement.dosageUnit} · ${supplement.form}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isComplete)
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 18),
          ),
      ],
    );
  }

  Widget _buildProgressBar(double progress, bool isComplete) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isComplete
                      ? [AppColors.success, AppColors.success]
                      : AppColors.brandGradient,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: (isComplete ? AppColors.success : AppColors.primary)
                        .withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(int taken, int total, bool isComplete) {
    final remaining = total - taken;
    final showBothButtons = !isComplete && remaining > 1;

    final counter = RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$taken',
            style: TextStyle(
              color: isComplete ? AppColors.success : AppColors.primary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' / $total tomas',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    if (isComplete) {
      return Row(
        children: [
          counter,
          const Spacer(),
          const Text(
            '¡Completado!',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    if (!showBothButtons) {
      // Solo queda 1 toma
      return Row(
        children: [
          counter,
          const Spacer(),
          _GradientButton(label: 'Tomar', onTap: onMarkTaken),
        ],
      );
    }

    // Quedan 2+ tomas: contador arriba, dos botones abajo a ancho completo
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        counter,
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onMarkTaken,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '+1 toma',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onMarkAllTaken,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Tomar todas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: supplement.schedules.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_scheduleIcon(s), size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                s,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _icon(String form) {
    switch (form.toLowerCase()) {
      case 'pastilla':
      case 'tableta':
      case 'comprimido':
        return Icons.medication_rounded;
      case 'cápsula':
        return Icons.vaccines_rounded;
      case 'polvo':
        return Icons.science_rounded;
      case 'líquido':
        return Icons.water_drop_rounded;
      case 'gominola':
        return Icons.favorite_rounded;
      case 'gotas':
        return Icons.opacity_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  IconData _scheduleIcon(String schedule) {
    switch (schedule.toLowerCase()) {
      case 'mañana':
        return Icons.wb_sunny_outlined;
      case 'mediodía':
        return Icons.wb_cloudy_outlined;
      case 'tarde':
        return Icons.cloud_outlined;
      case 'noche':
        return Icons.nightlight_outlined;
      default:
        return Icons.schedule;
    }
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _GradientButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: AppGradients.brand,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
