import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/friends_remote_datasource.dart';

/// Qué ven tus amigos (los mismos textos en Perfil y en la pantalla de la 1.ª solicitud).
abstract final class SharingTexts {
  static const always =
      'Siempre: tu nombre de usuario, tu Capsu con sus objetos y el mes y año en que te diste de alta.';
  static const progressTitle = 'Compartir mi progreso';
  static const progressBody =
      'Tu racha, tu cumplimiento de los últimos 30 días, cuántos suplementos tienes activos '
      'y tu puesto en su clasificación. Si está apagado, no sales en su clasificación '
      '(tú sí ves la de quienes la comparten).';
  static const supplementsTitle = 'Compartir mis suplementos';
  static const supplementsBody =
      'El nombre, la dosis y la forma de cada suplemento, lo que has tomado hoy y tu calendario de cada mes.';
}

/// Fila con interruptor (texto + pastilla on/off).
class SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool? value; // null = cargando
  final ValueChanged<bool> onChanged;

  const SwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final on = value;
    return Semantics(
      button: true,
      toggled: on ?? false,
      enabled: on != null,
      label: title,
      child: PressableScale(
        onTap: on == null ? null : () => onChanged(!on),
        scale: 0.98,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconChip(icon: icon),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.label),
                    const SizedBox(height: 2),
                    Text(body, style: AppText.micro),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SwitchPill(on: on ?? false, loading: on == null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwitchPill extends StatelessWidget {
  final bool on;
  final bool loading;
  const SwitchPill({super.key, required this.on, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: loading ? 0.4 : 1,
      child: AnimatedContainer(
        duration: AppMotion.of(context, AppMotion.medium),
        curve: AppMotion.standard,
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: on ? AppColors.accentStrong : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: on ? AppColors.accentStrong : AppColors.border),
        ),
        child: AnimatedAlign(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.standard,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: AppColors.textPrimary, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

/// Los dos interruptores de Perfil. El cambio se guarda al momento en el servidor.
class FriendSharingSwitches extends StatefulWidget {
  const FriendSharingSwitches({super.key});

  @override
  State<FriendSharingSwitches> createState() => _FriendSharingSwitchesState();
}

class _FriendSharingSwitchesState extends State<FriendSharingSwitches> {
  SharingSettings? _settings;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await context.read<FriendsRemoteDataSource>().getSharing();
      if (mounted) setState(() => _settings = s);
    } catch (_) {
      // Sin conexión: se quedan deshabilitados hasta que se puedan leer
    }
  }

  Future<void> _set({bool? progress, bool? supplements}) async {
    final before = _settings;
    if (before == null) return;
    setState(() => _settings = before.copyWith(progress: progress, supplements: supplements));
    try {
      final saved = await context
          .read<FriendsRemoteDataSource>()
          .setSharing(progress: progress, supplements: supplements);
      if (mounted) setState(() => _settings = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _settings = before);
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    return Column(
      children: [
        SwitchTile(
          icon: LucideIcons.flame,
          title: SharingTexts.progressTitle,
          body: SharingTexts.progressBody,
          value: s?.progress,
          onChanged: (v) => _set(progress: v),
        ),
        const Divider(indent: 64),
        SwitchTile(
          icon: LucideIcons.pill,
          title: SharingTexts.supplementsTitle,
          body: SharingTexts.supplementsBody,
          value: s?.supplements,
          onChanged: (v) => _set(supplements: v),
        ),
      ],
    );
  }
}
