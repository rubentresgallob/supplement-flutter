import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/friends_remote_datasource.dart';
import '../widgets/privacy_switches.dart';

/// Antes de la primera solicitud (enviada o aceptada): explica qué verán los amigos
/// y deja activar los interruptores. Devuelve `true` si puede seguir.
Future<bool> ensureSocialPrivacyIntro(BuildContext context) async {
  final ds = context.read<FriendsRemoteDataSource>();
  try {
    final settings = await ds.getSharing();
    if (settings.introSeen || !context.mounted) return settings.introSeen;
  } catch (e) {
    if (context.mounted) AppToast.error(context, e.toString());
    return false;
  }
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const SocialPrivacyPage()),
  );
  return ok == true;
}

class SocialPrivacyPage extends StatefulWidget {
  const SocialPrivacyPage({super.key});

  @override
  State<SocialPrivacyPage> createState() => _SocialPrivacyPageState();
}

class _SocialPrivacyPageState extends State<SocialPrivacyPage> {
  // Privacidad por defecto: los dos apagados hasta que el usuario decida
  bool _progress = false;
  bool _supplements = false;
  bool _saving = false;

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      await context.read<FriendsRemoteDataSource>().setSharing(
            progress: _progress,
            supplements: _supplements,
            introSeen: true,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        title: const Text('Qué verán tus amigos'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: AppSpace.lg),
                children: [
                  const Text(
                    'Tú decides qué compartes. Puedes cambiarlo cuando quieras en Perfil y el cambio es inmediato.',
                    style: AppText.body,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.lg),
                    decoration: AppDecorations.frame(),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconChip(icon: LucideIcons.eye),
                        SizedBox(width: AppSpace.md),
                        Expanded(child: Text(SharingTexts.always, style: AppText.caption)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    decoration: AppDecorations.frame(),
                    child: Column(
                      children: [
                        SwitchTile(
                          icon: LucideIcons.flame,
                          title: SharingTexts.progressTitle,
                          body: SharingTexts.progressBody,
                          value: _progress,
                          onChanged: (v) => setState(() => _progress = v),
                        ),
                        const Divider(indent: 64),
                        SwitchTile(
                          icon: LucideIcons.pill,
                          title: SharingTexts.supplementsTitle,
                          body: SharingTexts.supplementsBody,
                          value: _supplements,
                          onChanged: (v) => setState(() => _supplements = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  const Text(
                    'Lo que tomas son datos de salud: solo se comparten si activas el interruptor.',
                    style: AppText.micro,
                  ),
                ],
              ),
            ),
            BottomActions(
              children: [
                AppButton(
                  label: 'Continuar',
                  size: AppButtonSize.lg,
                  expand: true,
                  loading: _saving,
                  onPressed: _saving ? null : _continue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
