import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens.dart';
import '../typography.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

enum AppButtonSize { sm, md, lg }

/// Botón del design system: color plano (azul solo en el primario), radio 16,
/// estado de carga (spinner sobre texto transparente), feedback háptico
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
        AppButtonSize.lg => 52,
      };

  TextStyle get _textStyle =>
      widget.size == AppButtonSize.sm ? AppText.buttonSmall : AppText.button;

  ({Color bg, Color fg, Color border}) get _style {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return (
          bg: _enabled || widget.loading
              ? AppColors.primary
              : AppColors.primaryDisabled,
          fg: AppColors.onPrimary,
          border: Colors.transparent,
        );
      case AppButtonVariant.destructive:
        return (
          bg: AppColors.danger.withValues(alpha: 0.14),
          fg: AppColors.danger,
          border: AppColors.danger.withValues(alpha: 0.5),
        );
      case AppButtonVariant.secondary:
        return (
          bg: AppColors.surfaceRaised,
          fg: AppColors.textPrimary,
          border: Colors.transparent,
        );
      case AppButtonVariant.outline:
        return (
          bg: AppColors.background,
          fg: AppColors.textPrimary,
          border: AppColors.borderStrong,
        );
      case AppButtonVariant.ghost:
        return (
          bg: _pressed ? AppColors.surfaceMuted : Colors.transparent,
          fg: AppColors.textPrimary,
          border: Colors.transparent,
        );
    }
  }

  void _setPressed(bool v) {
    if (_enabled && _pressed != v) setState(() => _pressed = v);
  }

  void _handleTap() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;
    final fg = widget.loading ? Colors.transparent : s.fg;
    final textStyle = _textStyle.copyWith(color: fg);

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: fg),
          const SizedBox(width: AppSpace.sm),
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
      child: Opacity(
        opacity: widget.onPressed == null &&
                !widget.loading &&
                widget.variant != AppButtonVariant.primary
            ? 0.5
            : 1,
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
              duration: AppMotion.medium,
              curve: AppMotion.standard,
              height: _height,
              constraints: const BoxConstraints(minWidth: AppSpacing.minTouch),
              padding: EdgeInsets.symmetric(
                  horizontal:
                      widget.size == AppButtonSize.sm ? AppSpace.md : AppSpace.xl),
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(AppRadii.button),
                border: Border.all(color: s.border),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  content,
                  if (widget.loading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: s.fg),
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
