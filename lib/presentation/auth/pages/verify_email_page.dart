import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/auth_remote_datasource.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';

/// Verificar el email con el código de 6 cifras que llega al registrarse
/// (o al intentar entrar sin haberlo verificado). Al terminar, la sesión queda iniciada.
class VerifyEmailPage extends StatefulWidget {
  final String email;
  const VerifyEmailPage({super.key, required this.email});

  /// Segundos de espera entre reenvíos (el servidor tampoco envía más de 1 por minuto).
  static const resendSeconds = 60;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  int _wait = VerifyEmailPage.resendSeconds; // acaba de enviarse un código
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _wait = VerifyEmailPage.resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _wait--);
      if (_wait <= 0) t.cancel();
    });
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AuthRemoteDataSource>().verifyEmail(
            email: widget.email,
            code: _codeCtrl.text.trim(),
          );
      if (!mounted) return;
      AppToast.success(context, '¡Email verificado! Bienvenido');
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

  Future<void> _resend() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthRemoteDataSource>().resendVerification(widget.email);
      if (!mounted) return;
      _codeCtrl.clear();
      _startCountdown();
      AppToast.success(context, 'Te hemos enviado un código nuevo');
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(title: const Text('Verifica tu email')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Center(
                child: Capsu(size: 90, mood: CapsuMood.happy, interactive: false),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Te hemos enviado un código de 6 cifras a\n'),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: '\nRevisa también la carpeta de spam.'),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _codeCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  letterSpacing: 8,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  labelText: 'Código',
                  prefixIcon: Icon(LucideIcons.keyRound),
                  counterText: '',
                ),
                validator: (v) => (v ?? '').length != 6 ? 'El código tiene 6 cifras' : null,
                onFieldSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Verificar',
                size: AppButtonSize.lg,
                expand: true,
                loading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading || _wait > 0 ? null : _resend,
                child: Text(
                  _wait > 0 ? '¿No te llega? Reenviar en $_wait s' : '¿No te llega? Reenviar código',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
