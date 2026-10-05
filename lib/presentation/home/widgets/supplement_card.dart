import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../domain/entities/user_supplement.dart';
import '../../../core/widgets/ui/ui.dart';

class SupplementCard extends StatefulWidget {
  final UserSupplement supplement;
  final int taken;
  final int cardIndex;
  final VoidCallback onMarkTaken;
  final VoidCallback onMarkAllTaken;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SupplementCard({
    super.key,
    required this.supplement,
    required this.taken,
    required this.onMarkTaken,
    required this.onMarkAllTaken,
    this.cardIndex = 0,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<SupplementCard> createState() => _SupplementCardState();
}

class _SupplementCardState extends State<SupplementCard> {
  @override
  Widget build(BuildContext context) {
    final total = widget.supplement.timesPerDay;
    final isComplete = widget.taken >= total;

    // Lista de uso diario: sin animación de entrada.
    return Dismissible(
      key: ValueKey('supp_${widget.supplement.id}'),
      direction: widget.onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) => showAppConfirm(
        context,
        title: '¿Eliminar ${widget.supplement.name}?',
        body: 'Se borrará de tu stack junto con su historial de tomas '
            'y su recordatorio. No se puede deshacer.',
        confirmLabel: 'Eliminar',
        destructive: true,
      ),
      onDismissed: (_) => widget.onDelete?.call(),
      background: _buildDismissBackground(),
      child: _buildCard(isComplete, total),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpace.xl),
      child: const Icon(LucideIcons.trash2, color: AppColors.danger, size: 22),
    );
  }

  Widget _buildCard(bool isComplete, int total) {
    final s = widget.supplement;
    final dose = s.dosageAmount % 1 == 0 ? s.dosageAmount.toInt() : s.dosageAmount;
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.standard,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.surfaceSelected : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: isComplete
              ? AppColors.mint.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconChip(icon: _icon(s.form), size: 44, highlighted: isComplete),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        // deja sitio al botón de editar
                        padding: const EdgeInsets.only(right: AppSpace.sm),
                        child: Text(
                          s.name,
                          style: AppText.section,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dose ${s.dosageUnit} · ${s.form} · $total× al día',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                      if (s.stockDaysLeft != null) ...[
                        const SizedBox(height: AppSpace.xs),
                        _buildStockLabel(s.stockDaysLeft!),
                      ],
                      if (s.schedules.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.sm),
                        _buildScheduleChips(),
                      ],
                      const SizedBox(height: AppSpace.md),
                      FlowProgress(
                        value: total > 0 ? widget.taken / total : 0,
                        height: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                _buildCheckButton(isComplete, total),
              ],
            ),
          ),
          if (widget.onEdit != null)
            Positioned(
              top: 0,
              right: 0,
              child: Semantics(
                button: true,
                label: 'Editar ${s.name}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onEdit,
                  child: const SizedBox(
                    width: 36,
                    height: 32,
                    child: Icon(LucideIcons.ellipsis,
                        color: AppColors.textMuted, size: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Pro: días que quedan de stock (en ámbar si queda una semana o menos).
  Widget _buildStockLabel(int days) {
    final color =
        widget.supplement.isStockLow ? AppColors.warning : AppColors.textMuted;
    final text = days == 0
        ? 'Se ha acabado'
        : 'Quedan $days ${days == 1 ? 'día' : 'días'}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.package, size: 12, color: color),
        const SizedBox(width: AppSpace.xs),
        Text(text, style: AppText.micro.copyWith(color: color)),
      ],
    );
  }

  Widget _buildScheduleChips() {
    final schedules = widget.supplement.schedules;
    return Wrap(
      spacing: AppSpace.xs,
      runSpacing: AppSpace.xs,
      children: schedules.asMap().entries.map((entry) {
        final isTaken = entry.key < widget.taken;
        final label = entry.value;
        return AppPill(
          text: label,
          icon: isTaken ? LucideIcons.check : _scheduleIcon(label),
          color: isTaken ? AppColors.mint : AppColors.textSecondary,
        );
      }).toList(),
    );
  }

  Widget _buildCheckButton(bool isComplete, int total) {
    final started = widget.taken > 0;
    return Semantics(
      button: true,
      label: isComplete
          ? '${widget.supplement.name} completado'
          : 'Registrar toma de ${widget.supplement.name}, ${widget.taken} de $total',
      excludeSemantics: true,
      child: PressableScale(
        onTap: widget.onMarkTaken,
        scale: 0.92,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.standard,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isComplete ? AppColors.mint : Colors.transparent,
            border: Border.all(
              color: isComplete
                  ? AppColors.mint
                  : started
                      ? AppColors.accentStrong
                      : AppColors.textTertiary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isComplete
                ? const Icon(LucideIcons.check,
                    color: AppColors.background, size: 20)
                : Text(
                    '${widget.taken}/$total',
                    style: AppText.captionStrong.copyWith(
                        color: started
                            ? AppColors.textPrimary
                            : AppColors.textMuted),
                  ),
          ),
        ),
      ),
    );
  }

  IconData _icon(String form) {
    switch (form.toLowerCase()) {
      case 'pastilla':
      case 'tableta':
      case 'comprimido':
        return LucideIcons.tablets;
      case 'cápsula':
        return LucideIcons.pill;
      case 'polvo':
        return LucideIcons.flaskConical;
      case 'líquido':
        return LucideIcons.droplet;
      case 'gominola':
        return LucideIcons.heart;
      case 'gotas':
        return LucideIcons.droplets;
      default:
        return LucideIcons.stethoscope;
    }
  }

  IconData _scheduleIcon(String schedule) {
    switch (schedule.toLowerCase()) {
      case 'mañana':
        return LucideIcons.sun;
      case 'mediodía':
        return LucideIcons.cloudSun;
      case 'tarde':
        return LucideIcons.sunset;
      case 'noche':
        return LucideIcons.moon;
      default:
        return LucideIcons.clock;
    }
  }
}
