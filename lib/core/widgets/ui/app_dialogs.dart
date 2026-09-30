import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

/// Diálogo de confirmación (forui `FDialog`). Devuelve `true` si se confirma.
///
/// ```dart
/// if (await showAppConfirm(context, title: '¿Eliminar?', body: '...', confirmLabel: 'Eliminar', destructive: true)) { ... }
/// ```
Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) async {
  if (destructive) HapticFeedback.mediumImpact();
  final result = await showFDialog<bool>(
    context: context,
    builder: (ctx, style, animation) => _AppDialog(
      style: style,
      animation: animation,
      title: Text(title),
      body: Text(body),
      actions: [
        FButton(
          variant: destructive ? FButtonVariant.destructive : FButtonVariant.primary,
          onPress: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Diálogo con un campo de texto (forui `FDialog`). Devuelve el texto o `null`.
Future<String?> showAppPrompt(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String hint = '',
  IconData? icon,
  String initialValue = '',
  int maxLines = 1,
}) async {
  return showFDialog<String>(
    context: context,
    builder: (ctx, style, animation) => _PromptDialog(
      style: style,
      animation: animation,
      title: title,
      body: body,
      confirmLabel: confirmLabel,
      hint: hint,
      icon: icon,
      initialValue: initialValue,
      maxLines: maxLines,
    ),
  );
}

/// El diálogo es dueño de su controlador: se libera cuando el diálogo
/// desaparece del todo (tras la animación de salida), no antes.
class _PromptDialog extends StatefulWidget {
  final FDialogStyleDelta style;
  final Animation<double> animation;
  final String title;
  final String body;
  final String confirmLabel;
  final String hint;
  final IconData? icon;
  final String initialValue;
  final int maxLines;

  const _PromptDialog({
    required this.style,
    required this.animation,
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.hint,
    required this.icon,
    required this.initialValue,
    required this.maxLines,
  });

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _ctrl = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(_ctrl.text.trim());

  @override
  Widget build(BuildContext context) {
    return _AppDialog(
      style: widget.style,
      animation: widget.animation,
      title: Text(widget.title),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.body),
          const SizedBox(height: AppSpacing.lg),
          Material(
            type: MaterialType.transparency,
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: widget.maxLines,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: widget.icon != null ? Icon(widget.icon) : null,
              ),
              onSubmitted: widget.maxLines == 1 ? (_) => _submit() : null,
            ),
          ),
        ],
      ),
      actions: [
        FButton(onPress: _submit, child: Text(widget.confirmLabel)),
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

/// Selector de hora tipo rueda (forui `FTimePicker`, 24 h) en un panel inferior.
/// Devuelve la hora elegida o `null` si se cancela.
Future<TimeOfDay?> showReminderTimePicker(
  BuildContext context, {
  TimeOfDay? initial,
}) {
  final start = initial ?? const TimeOfDay(hour: 9, minute: 0);
  // La rueda va de 5 en 5 minutos: partimos de la hora ya redondeada
  final initialTime = FTime(start.hour, start.minute - start.minute % 5);
  var selected = initialTime;

  return showFSheet<TimeOfDay>(
    context: context,
    side: FLayout.btt,
    mainAxisMaxRatio: null,
    builder: (ctx) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 20 + MediaQuery.paddingOf(ctx).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Hora del recordatorio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Te avisaremos cada día a esta hora',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: FTimePicker(
              hour24: true,
              minuteInterval: 5,
              control: FTimePickerControl.managed(
                initial: initialTime,
                onChange: (t) {
                  HapticFeedback.selectionClick();
                  selected = t;
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          FButton(
            onPress: () => Navigator.of(ctx)
                .pop(TimeOfDay(hour: selected.hour, minute: selected.minute)),
            child: const Text('Guardar hora'),
          ),
          const SizedBox(height: 8),
          FButton(
            variant: FButtonVariant.ghost,
            onPress: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    ),
  );
}

/// Contenido de diálogo vertical (móvil) sobre `FDialog` de forui 0.27,
/// siguiendo el ejemplo oficial: título, cuerpo y acciones apiladas.
class _AppDialog extends StatelessWidget {
  final FDialogStyleDelta style;
  final Animation<double>? animation;
  final Widget title;
  final Widget body;
  final List<Widget> actions;

  const _AppDialog({
    required this.style,
    required this.animation,
    required this.title,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) => FDialog(
        style: style,
        animation: animation,
        builder: (context, style) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 9),
                child: DefaultTextStyle.merge(style: style.titleTextStyle, child: title),
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                  child: DefaultTextStyle.merge(style: style.bodyTextStyle, child: body),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 10,
                children: actions,
              ),
            ],
          ),
        ),
      );
}
