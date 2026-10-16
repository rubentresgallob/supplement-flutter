import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';

/// Eliminar cuenta (obligatorio en App Store y Google Play): confirmar + contraseña.
/// Se usa desde Perfil y desde la pantalla de reaceptación de los textos legales.
Future<void> confirmAndDeleteAccount(BuildContext context) async {
  final confirmed = await showAppConfirm(
    context,
    title: '¿Eliminar tu cuenta?',
    body: 'Se borrarán para siempre tus suplementos, tomas, rachas, amigos, puntos y objetos. '
        'No se puede deshacer.',
    confirmLabel: 'Continuar',
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;

  final password = await showAppPrompt(
    context,
    title: 'Confirma con tu contraseña',
    body: 'Escribe tu contraseña para eliminar la cuenta.',
    confirmLabel: 'Eliminar cuenta',
    hint: 'Contraseña',
    icon: LucideIcons.lock,
    obscureText: true,
    destructive: true,
  );
  if (password == null || password.isEmpty || !context.mounted) return;

  try {
    await context.read<AuthRemoteDataSource>().deleteAccount(password);
    await NotificationService.cancelAll();
    if (!context.mounted) return;
    AppToast.success(context, 'Tu cuenta se ha eliminado');
    context.read<AuthBloc>().add(AuthLogoutEvent());
  } catch (e) {
    if (context.mounted) AppToast.error(context, e.toString());
  }
}
