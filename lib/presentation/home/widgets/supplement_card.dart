import 'package:flutter/material.dart';
import '../../../domain/entities/user_supplement.dart';
import '../../../core/constants/app_constants.dart';

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

class _SupplementCardState extends State<SupplementCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  static const _accentColors = [
    Color(0xFFFF6B35),
    Color(0xFFFF3D00),
    Color(0xFFFFD166),
    Color(0xFF4ADE80),
    Color(0xFF38BDF8),
    Color(0xFFE879F9),
    Color(0xFFFB923C),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFF818CF8),
  ];

  Color get _accent =>
      _accentColors[widget.supplement.name.hashCode.abs() % _accentColors.length];

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.25, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: 80 * widget.cardIndex), () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.supplement.timesPerDay;
    final isComplete = widget.taken >= total;
    final accent = _accent;

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Dismissible(
          key: ValueKey('supp_${widget.supplement.id}'),
          direction: widget.onDelete != null
              ? DismissDirection.endToStart
              : DismissDirection.none,
          onDismissed: (_) => widget.onDelete?.call(),
          background: _buildDismissBackground(),
          child: _buildCard(isComplete, accent, total),
        ),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF3D00), Color(0xFFFF4444)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.white, size: 26),
    );
  }

  Widget _buildCard(bool isComplete, Color accent, int total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isComplete
            ? const Color(0xFF0D1E15)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isComplete
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isComplete
                ? AppColors.success.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Left accent bar
            Positioned(
              left: 0,
              top: 12,
              bottom: 12,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isComplete
                        ? [AppColors.success, const Color(0xFF22C55E)]
                        : [accent, _darken(accent)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (isComplete ? AppColors.success : accent)
                          .withValues(alpha: 0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.28),
                          accent.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Icon(_icon(widget.supplement.form),
                        color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Name / dose / chips / progress
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNameRow(accent),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.supplement.dosageAmount % 1 == 0 ? widget.supplement.dosageAmount.toInt() : widget.supplement.dosageAmount} ${widget.supplement.dosageUnit} · $total× al día',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (widget.supplement.schedules.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildScheduleChips(),
                        ],
                        const SizedBox(height: 10),
                        _buildProgressBar(isComplete, accent, total),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Circular check button
                  _buildCheckButton(isComplete, total),
                ],
              ),
            ),
            // Edit button top-right
            if (widget.onEdit != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: widget.onEdit,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.bgCardElevated.withValues(alpha: 0.0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textMuted, size: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameRow(Color accent) {
    return Row(
      children: [
        Flexible(
          child: Text(
            widget.supplement.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            widget.supplement.form,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleChips() {
    final schedules = widget.supplement.schedules;
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: schedules.asMap().entries.map((entry) {
        final isTaken = entry.key < widget.taken;
        final s = entry.value;
        return Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isTaken
                ? AppColors.success.withValues(alpha: 0.18)
                : AppColors.bgCardElevated.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isTaken
                  ? AppColors.success.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isTaken ? Icons.check_rounded : _scheduleIcon(s),
                size: 10,
                color: isTaken
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                s,
                style: TextStyle(
                  color: isTaken
                      ? AppColors.success
                      : AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar(bool isComplete, Color accent, int total) {
    final targetProgress =
        total > 0 ? (widget.taken / total).clamp(0.0, 1.0) : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: targetProgress),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, progress, __) => ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Stack(
          children: [
            Container(
              height: 3,
              color: AppColors.bgCardElevated,
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isComplete
                        ? [AppColors.success, const Color(0xFF22C55E)]
                        : [accent, AppColors.gold],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: (isComplete ? AppColors.success : accent)
                          .withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckButton(bool isComplete, int total) {
    return GestureDetector(
      onTap: widget.onMarkTaken,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isComplete
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                )
              : widget.taken > 0
                  ? LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: 0.18),
                      AppColors.primary.withValues(alpha: 0.08),
                    ])
                  : null,
          border: Border.all(
            color: isComplete
                ? Colors.transparent
                : widget.taken > 0
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.border,
            width: 2,
          ),
          boxShadow: isComplete
              ? [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.5),
                    blurRadius: 18,
                  )
                ]
              : null,
        ),
        child: Center(
          child: isComplete
              ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 20)
              : Text(
                  '${widget.taken}/$total',
                  style: TextStyle(
                    color: widget.taken > 0
                        ? AppColors.primary
                        : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Syne',
                  ),
                ),
        ),
      ),
    );
  }

  Color _darken(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - 0.25).clamp(0.0, 1.0))
        .toColor();
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
