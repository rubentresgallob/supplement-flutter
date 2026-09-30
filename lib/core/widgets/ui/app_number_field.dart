import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

/// Stepper numérico basado en `NumberField` de coss (− valor +).
class AppNumberField extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String Function(int value)? format;

  const AppNumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    final text = format?.call(value) ?? '$value';
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _StepButton(
            icon: LucideIcons.minus,
            label: 'Disminuir',
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: Semantics(
              value: text,
              liveRegion: true,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.fast),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  text,
                  key: ValueKey(value),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          Container(width: 1, color: AppColors.border),
          _StepButton(
            icon: LucideIcons.plus,
            label: 'Aumentar',
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _StepButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: SizedBox(
          width: 52,
          height: double.infinity,
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
