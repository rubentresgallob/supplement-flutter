import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../../../domain/entities/user.dart';
import '../../profile/widgets/delete_account.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/legal_consents.dart';

/// Se muestra al iniciar sesión si la versión vigente de los Términos o de la
/// Política es más nueva que la aceptada (o si faltan consentimientos).
/// Resume los cambios y pide aceptar de nuevo; también deja eliminar la cuenta.
class LegalAcceptPage extends StatefulWidget {
  final User user;
  const LegalAcceptPage({super.key, required this.user});

  @override
  State<LegalAcceptPage> createState() => _LegalAcceptPageState();
}

class _LegalAcceptPageState extends State<LegalAcceptPage> {
  var _consents = const LegalConsentsValue();
  bool _saving = false;

  Future<void> _accept() async {
    setState(() => _saving = true);
    try {
      await context.read<AuthRemoteDataSource>().acceptLegal();
      if (mounted) context.read<AuthBloc>().add(AuthLegalAcceptedEvent());
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpace.xl),
                      const Icon(LucideIcons.fileText, size: 32, color: AppColors.textSecondary),
                      const SizedBox(height: AppSpace.lg),
                      const Text('Hemos actualizado nuestros textos',
                          textAlign: TextAlign.center, style: AppText.title),
                      const SizedBox(height: AppSpace.sm),
                      const Text(
                        'Para seguir usando la app, revisa los cambios y acéptalos.',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: AppSpace.xl),
                      const Text('Qué cambia', style: AppText.captionStrong),
                      const SizedBox(height: AppSpace.sm),
                      for (final change in widget.user.legalChanges)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Icon(LucideIcons.dot, size: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Expanded(child: Text(change, style: AppText.body)),
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpace.lg),
                      LegalConsents(
                        value: _consents,
                        enabled: !_saving,
                        onChanged: (v) => setState(() => _consents = v),
                      ),
                      const SizedBox(height: AppSpace.lg),
                    ],
                  ),
                ),
              ),
              BottomActions(
                children: [
                  AppButton(
                    label: 'Aceptar y continuar',
                    size: AppButtonSize.lg,
                    expand: true,
                    loading: _saving,
                    onPressed: _consents.all && !_saving ? _accept : null,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  AppButton(
                    label: 'No acepto: eliminar mi cuenta',
                    variant: AppButtonVariant.outline,
                    expand: true,
                    onPressed: _saving ? null : () => confirmAndDeleteAccount(context),
                  ),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.read<AuthBloc>().add(AuthLogoutEvent()),
                    child: const Text('Cerrar sesión', style: AppText.label),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
