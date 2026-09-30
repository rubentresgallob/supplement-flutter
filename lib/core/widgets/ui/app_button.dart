import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

enum AppButtonSize { sm, md, lg }

/// Botón basado en el `Button` de coss:
/// variantes, estado de carga (spinner sobre texto transparente),
/// opacidad 64% deshabilitado, brillo interior superior, feedback háptico
/// y zona táctil mínima de 44pt.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool expand;
  final String? semanticLabel;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.semanticLabel,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  double get _height => switch (widget.size) {
        AppButtonSize.sm => 36,
        AppButtonSize.md => 48,
        AppButtonSize.lg => 56,
      };

  double get _fontSize => switch (widget.size) {
        AppButtonSize.sm => 13,
        AppButtonSize.md => 15,
        AppButtonSize.lg => 16,
      };

  ({Gradient? gradient, Color? bg, Color fg, Color border, List<BoxShadow> shadow})
      get _style {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (
          gradient: null,
          bg: AppColors.primary,
          fg: AppColors.onPrimary,
          border: AppColors.primary,
          shadow: _enabled ? AppShadows.md : const [],
        );
      case AppButtonVariant.destructive:
        return (
          gradient: null,
          bg: AppColors.error,
          fg: AppColors.onPrimary,
          border: AppColors.error,
          shadow: _enabled ? AppShadows.glow(AppColors.error, strength: 0.24) : const [],
        );
      case AppButtonVariant.secondary:
        return (
          gradient: null,
          bg: AppColors.bgCardElevated,
          fg: AppColors.textPrimary,
          border: Colors.transparent,
          shadow: const [],
        );
      case AppButtonVariant.outline:
        return (
          gradient: null,
          bg: AppColors.input,
          fg: AppColors.textPrimary,
          border: AppColors.border,
          shadow: AppShadows.xs,
        );
      case AppButtonVariant.ghost:
        return (
          gradient: null,
          bg: _pressed ? AppColors.surfaceMuted : Colors.transparent,
          fg: AppColors.textPrimary,
          border: Colors.transparent,
          shadow: const [],
        );
    }
  }

  void _setPressed(bool v) {
    if (_enabled && _pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final hasFill = widget.variant == AppButtonVariant.primary ||
        widget.variant == AppButtonVariant.destructive;
    final textStyle = TextStyle(
      color: widget.loading ? Colors.transparent : s.fg,
      fontSize: _fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon,
              size: _fontSize + 3,
              color: widget.loading ? Colors.transparent : s.fg.withValues(alpha: 0.85)),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(widget.label,
              style: textStyle, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: widget.onPressed == null && !widget.loading ? 0.64 : 1,
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: _handleTap,
          child: AnimatedScale(
            scale: _pressed && !AppMotion.reduced(context) ? 0.97 : 1,
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              height: _height,
              constraints: const BoxConstraints(minWidth: AppSpacing.minTouch),
              padding: EdgeInsets.symmetric(
                  horizontal: widget.size == AppButtonSize.sm ? 14 : 20),
              decoration: BoxDecoration(
                gradient: s.gradient,
                color: s.bg,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: s.border),
                boxShadow: _pressed ? const [] : s.shadow,
              ),
              foregroundDecoration: hasFill
                  // Brillo interior superior (inset-shadow white/16% de coss)
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: _pressed ? 0 : 0.16),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    )
                  : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  content,
                  if (widget.loading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: s.fg),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
