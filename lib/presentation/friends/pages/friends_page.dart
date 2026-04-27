import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/friends_remote_datasource.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ds = context.read<FriendsRemoteDataSource>();
      final results =
          await Future.wait([ds.getFriends(), ds.getPendingRequests()]);
      setState(() {
        _friends = results[0];
        _requests = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddFriendDialog() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Añadir amigo',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Introduce su usuario o email',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'usuario o email...',
                  prefixIcon: Icon(Icons.person_search_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.bgCardElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text('Cancelar',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: AppGradients.brand,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('Enviar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && ctrl.text.trim().isNotEmpty && mounted) {
      try {
        await context.read<FriendsRemoteDataSource>().sendRequest(ctrl.text.trim());
        if (mounted) {
          _showSnack('Solicitud enviada', isSuccess: true);
          _load();
        }
      } catch (e) {
        if (mounted) _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _accept(int requestId) async {
    try {
      await context.read<FriendsRemoteDataSource>().acceptRequest(requestId);
      _load();
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _reject(int requestId) async {
    try {
      await context.read<FriendsRemoteDataSource>().rejectRequest(requestId);
      _load();
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _remove(int friendId, String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.person_remove_rounded,
                    color: AppColors.error, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Eliminar amigo',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('¿Eliminar a $username de tus amigos?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Center(
                        child: Text('Cancelar',
                            style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4)),
                      ),
                      child: const Center(
                        child: Text('Eliminar',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (ok == true && mounted) {
      try {
        await context.read<FriendsRemoteDataSource>().removeFriend(friendId);
        _load();
      } catch (e) {
        if (mounted) _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _showFriendDetail(Map<String, dynamic> friendItem) async {
    final friend = friendItem['friend'] as Map<String, dynamic>;
    final username = friend['username'] as String;
    final email = friend['email'] as String;
    final friendId = friend['id'] as int;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FriendDetailSheet(
        username: username,
        email: email,
        onMotivate: () => _motivateFriend(username, friendId),
        onRemove: () => _remove(friendId, username),
      ),
    );
  }

  Future<void> _motivateFriend(String username, int friendId) async {
    final ds = context.read<FriendsRemoteDataSource>();
    try {
      await ds.sendMotivation(friendId);
    } catch (_) {
      // El endpoint puede no existir aún; la notificación local siempre se muestra
    }
    await NotificationService.showMotivationSent(username);
    if (mounted) _showSnack('¡Ánimos enviados a $username! 💪', isSuccess: true);
  }

  void _showSnack(String msg,
      {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError
          ? AppColors.error
          : isSuccess
              ? AppColors.success
              : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? _buildError()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    backgroundColor: AppColors.bgCard,
                    child: CustomScrollView(slivers: _buildContent()),
                  ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _load,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Reintentar',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      // Header
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu red',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Amigos',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showAddFriendDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.person_add_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Añadir',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Solicitudes pendientes
      if (_requests.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Row(children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '${_requests.length} solicitud${_requests.length > 1 ? 'es' : ''} pendiente${_requests.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final req = _requests[i];
              final from = req['from'] as Map<String, dynamic>;
              final username = from['username'] as String;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFF1A1000),
                      Color(0xFF0F1623)
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(children: [
                    _Avatar(username: username, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(username,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700)),
                            Text(from['email'] as String,
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                          ]),
                    ),
                    GestureDetector(
                      onTap: () => _accept(req['requestId'] as int),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: AppColors.success, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _reject(req['requestId'] as int),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: AppColors.error, size: 18),
                      ),
                    ),
                  ]),
                ),
              );
            },
            childCount: _requests.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Divider(color: AppColors.border),
          ),
        ),
      ],

      // Lista de amigos
      if (_friends.isEmpty)
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.bgCardElevated,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(Icons.people_outline_rounded,
                        size: 44, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  const Text('Sin amigos aún',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Añade amigos para comparar\ntu progreso y motivarte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        )
      else
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final item = _friends[i];
              final friend = item['friend'] as Map<String, dynamic>;
              final username = friend['username'] as String;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: GestureDetector(
                  onTap: () => _showFriendDetail(item),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppGradients.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(children: [
                      _Avatar(username: username, color: AppColors.gold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(username,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700)),
                              Text(friend['email'] as String,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12)),
                            ]),
                      ),
                      // Botón rápido "Motivar"
                      GestureDetector(
                        onTap: () => _motivateFriend(
                            username, friend['id'] as int),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: AppGradients.brand,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.emoji_emotions_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Motivar',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            },
            childCount: _friends.length,
          ),
        ),

      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ];
  }
}

// ─── Friend Detail Bottom Sheet ─────────────────────────────────────────────

class _FriendDetailSheet extends StatelessWidget {
  final String username;
  final String email;
  final VoidCallback onMotivate;
  final VoidCallback onRemove;

  const _FriendDetailSheet({
    required this.username,
    required this.email,
    required this.onMotivate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                )
              ],
            ),
            child: Center(
              child: Text(username[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 14),
          Text(username,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(email,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 28),
          // Motivar
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onMotivate();
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_emotions_rounded,
                      color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text('¡Motivar!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Eliminar
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onRemove();
            },
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_remove_rounded,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Text('Eliminar amigo',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar widget ───────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String username;
  final Color color;
  const _Avatar({required this.username, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(
        child: Text(
          username[0].toUpperCase(),
          style:
              TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
    );
  }
}
