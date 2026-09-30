import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/friends_remote_datasource.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../core/services/notification_service.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Header + TabBar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tu red',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                          SizedBox(height: 2),
                          Text('Amigos',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        gradient: AppGradients.brand,
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.onPrimary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      tabs: const [
                        const Tab(text: 'Amigos'),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(LucideIcons.chartColumn, size: 14),
                              SizedBox(width: 6),
                              Text('Clasificación'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _FriendsTab(),
                  _LeaderboardTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Amigos ──────────────────────────────────────────────────────────────

class _FriendsTab extends StatefulWidget {
  const _FriendsTab();

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
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
    setState(() { _isLoading = true; _error = null; });
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
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _showAddFriendDialog() async {
    final identifier = await showAppPrompt(
      context,
      title: 'Añadir amigo',
      body: 'Introduce su nombre de usuario o su email.',
      confirmLabel: 'Enviar solicitud',
      hint: 'usuario o email',
      icon: LucideIcons.userRoundSearch,
    );
    if (identifier != null && identifier.isNotEmpty && mounted) {
      try {
        await context
            .read<FriendsRemoteDataSource>()
            .sendRequest(identifier);
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
    final ok = await showAppConfirm(
      context,
      title: '¿Eliminar a $username?',
      body: 'Dejaréis de ver vuestras rachas y no podréis enviaros ánimos.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (ok && mounted) {
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
        friendId: friendId,
        onMotivate: () => _motivateFriend(username, friendId),
        onRemove: () => _remove(friendId, username),
      ),
    );
  }

  Future<void> _motivateFriend(String username, int friendId) async {
    final ds = context.read<FriendsRemoteDataSource>();
    try {
      await ds.sendMotivation(friendId);
    } catch (_) {}
    await NotificationService.showMotivationSent(username);
    if (mounted) _showSnack('¡Ánimos enviados a $username!', isSuccess: true);
  }

  void _showSnack(String msg, {bool isError = false, bool isSuccess = false}) {
    AppToast.show(
      context,
      msg,
      type: isError
          ? AppToastType.error
          : isSuccess
              ? AppToastType.success
              : AppToastType.warning,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppListSkeleton(circleLeading: true);
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.cloudOff,
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
                        color: AppColors.onPrimary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.bgCard,
      child: CustomScrollView(
        slivers: [
          // Botón añadir amigo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GestureDetector(
                onTap: _showAddFriendDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppGradients.brand,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.userRoundPlus,
                          color: AppColors.onPrimary, size: 18),
                      SizedBox(width: 8),
                      Text('Añadir amigo',
                          style: TextStyle(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Solicitudes pendientes
          if (_requests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1C1C1C), Color(0xFF171717)]),
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
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.success.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(LucideIcons.check,
                                color: AppColors.success, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _reject(req['requestId'] as int),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.4)),
                            ),
                            child: const Icon(LucideIcons.x,
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Divider(color: AppColors.border),
              ),
            ),
          ],

          // Lista de amigos
          if (_friends.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.bgCardElevated,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(LucideIcons.usersRound,
                          size: 40, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    const Text('Sin amigos aún',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    const Text(
                      'Añade amigos para competir\nen la clasificación',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5),
                    ),
                  ],
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
                                  Icon(LucideIcons.smile,
                                      color: AppColors.onPrimary, size: 16),
                                  SizedBox(width: 4),
                                  Text('Motivar',
                                      style: TextStyle(
                                          color: AppColors.onPrimary,
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
        ],
      ),
    );
  }
}

// ─── Tab Clasificación ───────────────────────────────────────────────────────

class _LeaderboardTab extends StatefulWidget {
  const _LeaderboardTab();

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  bool _showStreaks = true;
  List<Map<String, dynamic>> _streakBoard = [];
  List<Map<String, dynamic>> _adherenceBoard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final ds = context.read<FriendsRemoteDataSource>();
      final results = await Future.wait([
        ds.getLeaderboardStreaks(),
        ds.getLeaderboardAdherence(),
      ]);
      final streakData = results[0]['leaderboard'] as List<dynamic>;
      final adherenceData = results[1]['leaderboard'] as List<dynamic>;
      setState(() {
        _streakBoard =
            streakData.map((e) => e as Map<String, dynamic>).toList();
        _adherenceBoard =
            adherenceData.map((e) => e as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppListSkeleton(circleLeading: true);
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.chartColumn,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('No se pudo cargar\nla clasificación',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
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
                        color: AppColors.onPrimary, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

    final board = _showStreaks ? _streakBoard : _adherenceBoard;

    if (board.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.bgCardElevated,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(LucideIcons.trophy,
                    size: 40, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              const Text('Sin clasificación aún',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Añade amigos para ver\nquién lleva la racha más larga',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      backgroundColor: AppColors.bgCard,
      child: CustomScrollView(
        slivers: [
          // Toggle Rachas / Adherencia
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  _ToggleChip(
                    icon: LucideIcons.flame,
                    label: 'Rachas',
                    selected: _showStreaks,
                    onTap: () => setState(() => _showStreaks = true),
                  ),
                  _ToggleChip(
                    icon: LucideIcons.chartBar,
                    label: 'Adherencia',
                    selected: !_showStreaks,
                    onTap: () => setState(() => _showStreaks = false),
                  ),
                ]),
              ),
            ),
          ),

          // Podio top 3
          if (board.length >= 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _Podium(
                  entries: board.take(3).toList(),
                  isStreaks: _showStreaks,
                ),
              ),
            ),

          // Lista del resto
          if (board.length > 3) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  board.length > 3 ? 'Resto de clasificación' : '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final entry = board[i + 3];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _LeaderboardRow(
                      entry: entry,
                      isStreaks: _showStreaks,
                    ),
                  );
                },
                childCount: board.length - 3,
              ),
            ),
          ] else if (board.length <= 3 && board.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox.shrink()),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ─── Toggle chip ─────────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: selected ? AppGradients.brand : null,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8)
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.onPrimary : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.onPrimary : AppColors.textMuted,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Podio top 3 ─────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  final bool isStreaks;

  const _Podium({required this.entries, required this.isStreaks});

  @override
  Widget build(BuildContext context) {
    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1C1C), Color(0xFF171717)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.06),
            blurRadius: 24,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2º puesto
          if (second != null)
            Expanded(
              child: _PodiumSlot(
                entry: second,
                rank: 2,
                height: 90,
                color: const Color(0xFFC0C0C0),
                isStreaks: isStreaks,
              ),
            )
          else
            const Expanded(child: SizedBox()),
          const SizedBox(width: 8),
          // 1º puesto (más alto)
          Expanded(
            child: _PodiumSlot(
              entry: first,
              rank: 1,
              height: 120,
              color: AppColors.gold,
              isStreaks: isStreaks,
            ),
          ),
          const SizedBox(width: 8),
          // 3º puesto
          if (third != null)
            Expanded(
              child: _PodiumSlot(
                entry: third,
                rank: 3,
                height: 72,
                color: const Color(0xFFCD7F32),
                isStreaks: isStreaks,
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final Map<String, dynamic> entry;
  final int rank;
  final double height;
  final Color color;
  final bool isStreaks;

  const _PodiumSlot({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    required this.isStreaks,
  });

  @override
  Widget build(BuildContext context) {
    final username = entry['username'] as String? ?? '?';
    final isMe = entry['isCurrentUser'] as bool? ?? false;

    final String metric;
    if (isStreaks) {
      final streak = entry['currentStreak'] as int? ?? 0;
      metric = '$streak días';
    } else {
      final pct = (entry['adherencePercent'] as num?)?.toDouble() ?? 0;
      metric = '${pct.toStringAsFixed(0)}%';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Badge de posición
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: rank == 1
              ? Icon(LucideIcons.trophy, color: color, size: 16)
              : Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        // Avatar
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ]),
            shape: BoxShape.circle,
            border: Border.all(
              color: isMe
                  ? AppColors.primary
                  : color.withValues(alpha: 0.5),
              width: isMe ? 2 : 1.5,
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              username[0].toUpperCase(),
              style: TextStyle(
                color: isMe ? AppColors.primary : color,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Username
        Text(
          isMe ? 'Tú' : username,
          style: TextStyle(
            color: isMe ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Metric
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            metric,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Barra del podio
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.08),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }
}

// ─── Fila del leaderboard (posiciones 4+) ────────────────────────────────────

class _LeaderboardRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isStreaks;

  const _LeaderboardRow({required this.entry, required this.isStreaks});

  @override
  Widget build(BuildContext context) {
    final rank = entry['rank'] as int? ?? 0;
    final username = entry['username'] as String? ?? '?';
    final isMe = entry['isCurrentUser'] as bool? ?? false;

    final String mainMetric;
    final String subMetric;
    if (isStreaks) {
      final current = entry['currentStreak'] as int? ?? 0;
      final longest = entry['longestStreak'] as int? ?? 0;
      mainMetric = '$current días';
      subMetric = 'Mejor: $longest días';
    } else {
      final pct = (entry['adherencePercent'] as num?)?.toDouble() ?? 0;
      final taken = entry['intakesTaken'] as int? ?? 0;
      final expected = entry['intakesExpected'] as int? ?? 0;
      mainMetric = '${pct.toStringAsFixed(0)}%';
      subMetric = '$taken / $expected tomas';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: isMe
            ? LinearGradient(colors: [
                AppColors.primary.withValues(alpha: 0.12),
                AppColors.primary.withValues(alpha: 0.04),
              ])
            : AppGradients.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        // Posición
        SizedBox(
          width: 28,
          child: Text(
            '$rank',
            style: TextStyle(
              color: isMe ? AppColors.primary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        // Avatar
        _Avatar(
          username: username,
          color: isMe ? AppColors.primary : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        // Nombre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isMe ? 'Tú ($username)' : username,
                style: TextStyle(
                  color: isMe ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                subMetric,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        // Métrica principal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMe
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Text(
            mainMetric,
            style: TextStyle(
              color: isMe ? AppColors.primary : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Friend Detail Bottom Sheet ──────────────────────────────────────────────

class _FriendDetailSheet extends StatefulWidget {
  final String username;
  final String email;
  final int friendId;
  final VoidCallback onMotivate;
  final VoidCallback onRemove;

  const _FriendDetailSheet({
    required this.username,
    required this.email,
    required this.friendId,
    required this.onMotivate,
    required this.onRemove,
  });

  @override
  State<_FriendDetailSheet> createState() => _FriendDetailSheetState();
}

class _FriendDetailSheetState extends State<_FriendDetailSheet> {
  Map<String, dynamic>? _progress;
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final data = await context
          .read<FriendsRemoteDataSource>()
          .getFriendProgress(widget.friendId);
      if (mounted) setState(() { _progress = data; _loadingProgress = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Avatar
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: AppGradients.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 18,
                )
              ],
            ),
            child: Center(
              child: Text(widget.username[0].toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 14),
          Text(widget.username,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(widget.email,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),

          // Stats del amigo
          if (_loadingProgress)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            )
          else if (_progress != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCardElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                _StatChip(
                  icon: '🔥',
                  label: 'Racha',
                  value:
                      '${(_progress!['streak'] as Map?)?['current'] ?? 0} días',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: '📊',
                  label: '30 días',
                  value:
                      '${((_progress!['last30DaysAdherence'] as num?)?.toStringAsFixed(0)) ?? '0'}%',
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: '💊',
                  label: 'Activos',
                  value: '${_progress!['activeSupplements'] ?? 0}',
                ),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Motivar
          GestureDetector(
            onTap: () { Navigator.pop(context); widget.onMotivate(); },
            child: Container(
              width: double.infinity, height: 52,
              decoration: BoxDecoration(
                gradient: AppGradients.brand,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.smile,
                      color: AppColors.onPrimary, size: 22),
                  SizedBox(width: 10),
                  Text('¡Motivar!',
                      style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Eliminar
          GestureDetector(
            onTap: () { Navigator.pop(context); widget.onRemove(); },
            child: Container(
              width: double.infinity, height: 46,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.userRoundMinus,
                      color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Text('Eliminar amigo',
                      style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  const _StatChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15)),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
      ]),
    );
  }
}

// ─── Avatar widget ────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String username;
  final Color color;
  const _Avatar({required this.username, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.25),
            color.withValues(alpha: 0.1),
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
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
    );
  }
}
