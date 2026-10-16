import 'friend_profile_page.dart';
import 'social_privacy_page.dart';
import '../widgets/moderation_actions.dart';
import '../../../data/models/friend_profile.dart';
import '../../rewards/widgets/rewards_widgets.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/friends_remote_datasource.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../rewards/bloc/rewards_cubit.dart';

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
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 16, AppSpace.screen, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tu red', style: AppText.brandSubtitle),
                          SizedBox(height: 2),
                          Text('Amigos',
                              style: AppText.title),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    height: 44,
                    decoration: AppDecorations.frame(radius: AppRadii.button),
                    child: TabBar(
                      controller: _tabCtrl,
                      indicator: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadii.tile),
                      ),
                      indicatorPadding: const EdgeInsets.all(3),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: AppText.label,
                      tabs: const [
                        Tab(text: 'Amigos'),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
      // La primera vez: qué verán sus amigos y los interruptores
      if (!await ensureSocialPrivacyIntro(context) || !mounted) return;
      try {
        await context
            .read<FriendsRemoteDataSource>()
            .sendRequest(identifier);
        if (mounted) {
          // El servidor nunca confirma si la cuenta existe (privacidad)
          _showSnack(
            'Si existe una cuenta con ese dato, le llegará tu solicitud',
            isSuccess: true,
          );
          _load();
        }
      } catch (e) {
        if (mounted) _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _accept(int requestId) async {
    if (!await ensureSocialPrivacyIntro(context) || !mounted) return;
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
    final friendId = friend['id'] as int;

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FriendProfilePage(
        friendId: friendId,
        username: username,
        onMotivate: () => _motivateFriend(username, friendId),
        onRemove: () => _remove(friendId, username),
      ),
    ));
    if (mounted) _load(); // por si le ha bloqueado
  }

  Future<void> _motivateFriend(String username, int friendId) async {
    final ds = context.read<FriendsRemoteDataSource>();
    try {
      final delivered = await ds.sendMotivation(friendId);
      if (!mounted) return;
      if (delivered) {
        _showSnack('Ánimos enviados a $username', isSuccess: true);
      } else {
        // Le llegará cuando tenga la app con los avisos activados
        _showSnack('$username aún no tiene los avisos activados');
      }
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  /// "En la app desde oct. 2026" (a los amigos solo se les da el mes y el año)
  static String _since(String? month) {
    final d = FriendProfile.parseMonth(month);
    if (d == null) return 'Ver perfil';
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return 'En la app desde ${months[d.month - 1]}. ${d.year}';
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
            AppButton(
              label: 'Reintentar',
              variant: AppButtonVariant.outline,
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceRaised,
      child: CustomScrollView(
        slivers: [
          // Botón añadir amigo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.sm),
              child: AppButton(
                label: 'Añadir amigo',
                icon: LucideIcons.userRoundPlus,
                size: AppButtonSize.lg,
                expand: true,
                onPressed: _showAddFriendDialog,
              ),
            ),
          ),

          // Solicitudes pendientes
          if (_requests.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 8, AppSpace.screen, 8),
                child: Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_requests.length} solicitud${_requests.length > 1 ? 'es' : ''} pendiente${_requests.length > 1 ? 's' : ''}',
                    style: AppText.label.copyWith(color: AppColors.textSecondary),
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
                  final fromId = from['id'] as int;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppGradients.card,
                        borderRadius: BorderRadius.circular(AppRadii.button),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.25)),
                      ),
                      child: Row(children: [
                        _Avatar(username: username, color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(username,
                                    style: AppText.label),
                                Text('Quiere ser tu amigo',
                                    style: AppText.caption.copyWith(color: AppColors.textSecondary)),
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
                        ModerationMenuButton(
                          userId: fromId,
                          username: username,
                          onBlocked: _load,
                        ),
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
                        borderRadius: BorderRadius.circular(AppRadii.sheet),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(LucideIcons.usersRound,
                          size: 40, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    const Text('Sin amigos aún',
                        style: AppText.section),
                    const SizedBox(height: 8),
                    const Text(
                      'Añade amigos para competir\nen la clasificación',
                      textAlign: TextAlign.center,
                      style: AppText.body,
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
                          borderRadius: BorderRadius.circular(AppRadii.button),
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
                                      style: AppText.label),
                                  Text(_since(item['memberSince'] as String?),
                                      style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                                ]),
                          ),
                          AppButton(
                            label: 'Motivar',
                            icon: LucideIcons.smile,
                            size: AppButtonSize.sm,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => _motivateFriend(
                                username, friend['id'] as int),
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

/// No sale en la clasificación de sus amigos hasta que comparta su progreso.
const _notSharingHint =
    'Tú no apareces en la clasificación de tus amigos: activa "Compartir mi progreso" en Perfil si quieres salir.';

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
  bool _meSharing = true;
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
      _meSharing = results[0]['meSharing'] as bool? ?? true;
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
            AppButton(
              label: 'Reintentar',
              variant: AppButtonVariant.outline,
              onPressed: _load,
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
                  borderRadius: BorderRadius.circular(AppRadii.sheet),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(LucideIcons.trophy,
                    size: 40, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              const Text('Sin clasificación aún',
                  style: AppText.section),
              const SizedBox(height: 8),
              const Text(
                'Aquí salen tus amigos que comparten su progreso',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              if (!_meSharing) ...[
                const SizedBox(height: AppSpace.md),
                const Text(_notSharingHint, textAlign: TextAlign.center, style: AppText.caption),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceRaised,
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
                  borderRadius: BorderRadius.circular(AppRadii.tile),
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

          if (!_meSharing)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.md),
                child: Text(_notSharingHint, style: AppText.caption),
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
                padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, 8),
                child: Text(
                  board.length > 3 ? 'Resto de clasificación' : '',
                  style: AppText.captionStrong.copyWith(color: AppColors.textSecondary),
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
          duration: AppMotion.medium,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.tile),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: selected ? AppColors.accent : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.label.copyWith(color: selected ? AppColors.textPrimary : AppColors.textMuted),
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
        gradient: AppGradients.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
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
                color: AppColors.silver,
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
              color: AppColors.accent,
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
                color: AppColors.bronze,
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
                    style: AppText.label.copyWith(color: color),
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
                  ? AppColors.accent
                  : color.withValues(alpha: 0.5),
              width: isMe ? 2 : 1.5,
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                        color: AppColors.background.withValues(alpha: 0.3),
                        blurRadius: 12)
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              username[0].toUpperCase(),
              style: AppText.section.copyWith(color: isMe ? AppColors.accent : color),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Username
        _NameWithMedal(
          entry: entry,
          name: isMe ? 'Tú' : username,
          style: AppText.captionStrong.copyWith(
              color: isMe ? AppColors.accent : AppColors.textPrimary),
          centered: true,
        ),
        const SizedBox(height: 4),
        // Metric
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadii.chip),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            metric,
            style: AppText.micro.copyWith(color: color),
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
                AppColors.accent.withValues(alpha: 0.12),
                AppColors.accent.withValues(alpha: 0.04),
              ])
            : AppGradients.card,
        borderRadius: BorderRadius.circular(AppRadii.button),
        border: Border.all(
          color: isMe
              ? AppColors.accent.withValues(alpha: 0.4)
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
            style: AppText.section.copyWith(color: isMe ? AppColors.accent : AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 12),
        // Avatar
        _Avatar(
          username: username,
          color: isMe ? AppColors.accent : AppColors.textSecondary,
        ),
        const SizedBox(width: 12),
        // Nombre
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NameWithMedal(
                entry: entry,
                name: isMe ? 'Tú ($username)' : username,
                style: AppText.label.copyWith(
                    color: isMe ? AppColors.accent : AppColors.textPrimary),
              ),
              Text(
                subMetric,
                style: AppText.micro,
              ),
            ],
          ),
        ),
        // Métrica principal
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.bgCardElevated,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(
              color: isMe
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : AppColors.border,
            ),
          ),
          child: Text(
            mainMetric,
            style: AppText.label.copyWith(color: isMe ? AppColors.accent : AppColors.textPrimary),
          ),
        ),
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
          style: AppText.section.copyWith(color: color),
        ),
      ),
    );
  }
}

/// Nombre con la medalla que el usuario lleva equipada (si tiene).
class _NameWithMedal extends StatelessWidget {
  final Map<String, dynamic> entry;
  final String name;
  final TextStyle style;
  final bool centered;

  const _NameWithMedal({
    required this.entry,
    required this.name,
    required this.style,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final equipped = entry['equipped'];
    final medal = equipped is Map
        ? context
            .read<RewardsCubit>()
            .state
            .item(equipped['medal'] as String?)
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          centered ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(name,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (medal != null) ...[
          const SizedBox(width: AppSpace.xs),
          MedalIcon(medal: medal, size: 18),
        ],
      ],
    );
  }
}
