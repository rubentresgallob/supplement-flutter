import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

/// Chip seleccionable basado en `Toggle` / `ToggleGroup` de coss.
/// Seleccionado: tinte de marca + borde; no seleccionado: superficie `input`.
class AppToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const AppToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimary : AppColors.textSecondary;
    return Semantics(
      button: true,
      toggled: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!selected);
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: AnimatedContainer(
            duration: AppMotion.of(context, AppMotion.fast),
            curve: AppMotion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.input,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 15, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
