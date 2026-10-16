import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/friends_remote_datasource.dart';

/// Bloquear: confirma y bloquea. Devuelve `true` si se ha bloqueado.
Future<bool> confirmBlockUser(BuildContext context, int userId, String username) async {
  final ok = await showAppConfirm(
    context,
    title: '¿Bloquear a $username?',
    body: 'Dejaréis de ser amigos, no podrá enviarte solicitudes y ninguno verá el perfil del otro. '
        'Puedes desbloquearlo desde Perfil.',
    confirmLabel: 'Bloquear',
    destructive: true,
  );
  if (!ok || !context.mounted) return false;
  try {
    await context.read<FriendsRemoteDataSource>().blockUser(userId);
    if (context.mounted) AppToast.success(context, '$username está bloqueado');
    return true;
  } catch (e) {
    if (context.mounted) AppToast.error(context, e.toString());
    return false;
  }
}

/// Denunciar: motivo + texto opcional. Se guarda y nos llega un aviso.
Future<void> showReportSheet(BuildContext context, int userId, String username) async {
  final ds = context.read<FriendsRemoteDataSource>();
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgCard,
    builder: (_) => _ReportSheet(username: username, onSend: (reason, details) => ds.reportUser(userId, reason, details)),
  );
  if (sent == true && context.mounted) {
    AppToast.success(context, 'Gracias. Revisaremos tu denuncia');
  }
}

class _ReportSheet extends StatefulWidget {
  final String username;
  final Future<void> Function(String reason, String? details) onSend;
  const _ReportSheet({required this.username, required this.onSend});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = [
    ('offensive_name', 'Nombre ofensivo'),
    ('impersonation', 'Suplantación'),
    ('harassment', 'Acoso'),
    ('other', 'Otro'),
  ];
  String? _reason;
  final _details = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      final text = _details.text.trim();
      await widget.onSend(_reason!, text.isEmpty ? null : text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.lg + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Denunciar a ${widget.username}', style: AppText.section),
            const SizedBox(height: AppSpace.sm),
            const Text('¿Qué ocurre?', style: AppText.caption),
            const SizedBox(height: AppSpace.md),
            for (final (code, label) in _reasons) ...[
              OptionTile(
                label: label,
                selected: _reason == code,
                onTap: () => setState(() => _reason = code),
              ),
              const SizedBox(height: AppSpace.sm),
            ],
            const SizedBox(height: AppSpace.sm),
            TextField(
              controller: _details,
              maxLength: 500,
              maxLines: 3,
              style: AppText.input,
              decoration: const InputDecoration(labelText: 'Cuéntanos más (opcional)'),
            ),
            const SizedBox(height: AppSpace.md),
            AppButton(
              label: 'Enviar denuncia',
              icon: LucideIcons.flag,
              expand: true,
              loading: _sending,
              onPressed: _reason == null || _sending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}

/// Menú "…" con Bloquear y Denunciar. [onBlocked] se llama tras bloquear.
class ModerationMenuButton extends StatelessWidget {
  final int userId;
  final String username;
  final VoidCallback onBlocked;
  const ModerationMenuButton({super.key, required this.userId, required this.username, required this.onBlocked});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Más opciones',
      icon: const Icon(LucideIcons.ellipsisVertical, color: AppColors.textSecondary),
      color: AppColors.surfaceRaised,
      onSelected: (value) async {
        if (value == 'block') {
          if (await confirmBlockUser(context, userId, username)) onBlocked();
        } else {
          await showReportSheet(context, userId, username);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'block', child: Text('Bloquear', style: AppText.label)),
        PopupMenuItem(value: 'report', child: Text('Denunciar', style: AppText.label)),
      ],
    );
  }
}
