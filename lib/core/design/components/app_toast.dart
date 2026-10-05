import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import '../../constants/app_constants.dart';
import '../../theme/app_tokens.dart';

enum AppToastType { success, error, info, warning }

/// Toast estilo coss: entra desde arriba, "rebote" en éxito y
/// "sacudida" horizontal en error. Respeta reducir movimiento.
///
/// Uso: `AppToast.show(context, 'Guardado', type: AppToastType.success);`
class AppToast {
  static OverlayEntry? _current;
  static Timer? _timer;

  static void success(BuildContext context, String message) =>
      show(context, message, type: AppToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: AppToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: AppToastType.info);

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(milliseconds: 3200),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _dismiss();
    if (type == AppToastType.error) {
      HapticFeedback.mediumImpact();
    } else if (type == AppToastType.success) {
      HapticFeedback.lightImpact();
    }

    final entry = OverlayEntry(
      builder: (_) => _ToastView(message: message, type: type, onDismiss: _dismiss),
    );
    _current = entry;
    overlay.insert(entry);
    _timer = Timer(duration, _dismiss);

    // Anuncio para lectores de pantalla
    SemanticsService.sendAnnouncement(
        View.of(context), message, Directionality.of(context));
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    _current?.remove();
    _current = null;
  }
}

class _ToastView extends StatefulWidget {
  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;

  const _ToastView({required this.message, required this.type, required this.onDismiss});

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.base,
  )..forward();

  late final AnimationController _feedback = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.type == AppToastType.error ? 280 : 320),
  );

  @override
  void initState() {
    super.initState();
    _enter.addStatusListener((s) {
      if (s == AnimationStatus.completed) _feedback.forward();
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    _feedback.dispose();
    super.dispose();
  }

  (Color, IconData) get _visual => switch (widget.type) {
        AppToastType.success => (AppColors.success, LucideIcons.circleCheck),
        AppToastType.error => (AppColors.error, LucideIcons.circleX),
        AppToastType.warning => (AppColors.warning, LucideIcons.triangleAlert),
        AppToastType.info => (AppColors.info, LucideIcons.info),
      };

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _visual;
    final reduced = AppMotion.reduced(context);
    final top = MediaQuery.paddingOf(context).top + AppSpacing.sm;

    return Positioned(
      top: top,
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _feedback]),
        builder: (context, child) {
          final e = reduced ? 1.0 : AppMotion.emphasized.transform(_enter.value);
          final f = reduced ? 0.0 : _feedback.value;
          final dx = widget.type == AppToastType.error ? math.sin(f * math.pi * 4) * 3 : 0.0;
          final scale = widget.type == AppToastType.success
              ? 1 + math.sin(f * math.pi) * 0.025
              : 1.0;
          return Opacity(
            opacity: _enter.value,
            child: Transform.translate(
              offset: Offset(dx, (1 - e) * -24),
              child: Transform.scale(scale: scale, child: child),
            ),
          );
        },
        child: Dismissible(
          key: const ValueKey('toast'),
          direction: DismissDirection.up,
          onDismissed: (_) => widget.onDismiss(),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCardElevated,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: color.withValues(alpha: 0.28)),
                boxShadow: AppShadows.md,
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: AppText.label,
                    ),
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
