import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Recuperar contraseña en 2 pasos: 1) email → 2) código + contraseña nueva.
/// Al terminar, la sesión queda iniciada.
class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthRemoteDataSource>().forgotPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _codeSent = true);
      AppToast.success(context, 'Si el email está registrado, te llegará un código');
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthRemoteDataSource>().resetPassword(
            email: _emailCtrl.text.trim(),
            code: _codeCtrl.text.trim(),
            newPassword: _passwordCtrl.text,
          );
      if (!mounted) return;
      AppToast.success(context, '¡Contraseña cambiada! Ya estás dentro');
      final auth = context.read<AuthBloc>();
      Navigator.of(context).pop();
      auth.add(AuthCheckStatusEvent()); // el token ya está guardado
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        AppToast.error(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: AmbientBackground(
        child: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.screen),
            children: [
              Center(
                child: HeroGlow(
                  size: 180,
                  child: Floating(
                    amplitude: 4,
                    child: Capsu(
                      size: 90,
                      mood: _codeSent ? CapsuMood.happy : CapsuMood.thinking,
                      interactive: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                _codeSent
                    ? 'Revisa tu email (y la carpeta de spam). Escribe el código de 6 cifras y tu contraseña nueva.'
                    : 'Escribe el email de tu cuenta y te enviaremos un código para crear una contraseña nueva.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailCtrl,
                enabled: !_codeSent,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: AppText.input,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(LucideIcons.mail, size: 18),
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Email no válido' : null,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: AppText.display,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    prefixIcon: Icon(LucideIcons.keyRound),
                    counterText: '',
                  ),
                  validator: (v) => (v ?? '').length != 6 ? 'El código tiene 6 cifras' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: !_showPassword,
                  style: AppText.input,
                  decoration: InputDecoration(
                    labelText: 'Contraseña nueva',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      tooltip: _showPassword ? 'Ocultar' : 'Mostrar',
                      icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                  ),
                  validator: (v) =>
                      (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: !_showPassword,
                  style: AppText.input,
                  decoration: const InputDecoration(
                    labelText: 'Repite la contraseña',
                    prefixIcon: Icon(LucideIcons.lock, size: 18),
                  ),
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Las contraseñas no coinciden' : null,
                ),
              ],
              const SizedBox(height: 24),
              AppButton(
                label: _codeSent ? 'Cambiar contraseña' : 'Enviar código',
                size: AppButtonSize.lg,
                expand: true,
                loading: _loading,
                onPressed: _codeSent ? _reset : _sendCode,
              ),
              if (_codeSent) ...[
                const SizedBox(height: AppSpace.sm),
                AppButton(
                  label: '¿No te llega? Volver a enviar',
                  variant: AppButtonVariant.ghost,
                  expand: true,
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _codeCtrl.clear();
                          }),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
