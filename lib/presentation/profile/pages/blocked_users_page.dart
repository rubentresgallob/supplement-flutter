import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/friends_remote_datasource.dart';

/// Personas bloqueadas, con la opción de desbloquearlas.
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<({int id, String username})>? _blocked;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await context.read<FriendsRemoteDataSource>().getBlockedUsers();
      if (mounted) setState(() => _blocked = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _unblock(int id, String username) async {
    try {
      await context.read<FriendsRemoteDataSource>().unblockUser(id);
      if (!mounted) return;
      AppToast.success(context, 'Has desbloqueado a $username');
      _load();
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _blocked;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Usuarios bloqueados'),
      ),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: AppEmpty(
                  icon: LucideIcons.cloudOff,
                  title: 'No se pudo cargar',
                  description: _error!,
                  action: AppButton(label: 'Reintentar', variant: AppButtonVariant.outline, onPressed: _load),
                ),
              )
            : list == null
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(
                        child: AppEmpty(
                          icon: LucideIcons.userRoundCheck,
                          title: 'No has bloqueado a nadie',
                          description: 'Puedes bloquear a alguien desde su perfil o desde su solicitud.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpace.screen),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) => Row(
                          children: [
                            Expanded(child: Text(list[i].username, style: AppText.label)),
                            AppButton(
                              label: 'Desbloquear',
                              size: AppButtonSize.sm,
                              variant: AppButtonVariant.outline,
                              onPressed: () => _unblock(list[i].id, list[i].username),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }
}
