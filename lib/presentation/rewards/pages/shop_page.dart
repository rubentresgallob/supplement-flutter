import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/rewards_remote_datasource.dart';
import '../../../data/models/rewards_models.dart';
import '../bloc/rewards_cubit.dart';
import '../widgets/rewards_widgets.dart';

/// Tienda: probador de Capsu, objetivos semanales, objetos y logros.
class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  static const _filters = [
    ('all', 'Todo', LucideIcons.store),
    ('capsu', 'Capsu', LucideIcons.sparkles),
    ('medal', 'Medallas', LucideIcons.medal),
    ('banner', 'Banners', LucideIcons.image),
    ('consumable', 'Protectores', LucideIcons.shield),
  ];

  String _filter = 'all';

  /// Objeto que Capsu se está "probando" en el probador.
  ShopItem? _preview;

  void _openItem(ShopItem item) {
    if (item.slot != null) setState(() => _preview = item);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<RewardsCubit>(),
        child: _ItemSheet(code: item.code),
      ),
    );
  }

  void _openHistory() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HistorySheet(
        dataSource: context.read<RewardsRemoteDataSource>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<RewardsCubit, RewardsState>(
          builder: (context, state) {
            if (state.loading && state.summary == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }
            // Error dentro de la pestaña (no toast: la tienda está montada aunque no se vea)
            if (state.summary == null && state.error != null) {
              return Center(
                child: AppEmpty(
                  media: const Capsu(size: 90, mood: CapsuMood.sad),
                  icon: LucideIcons.store,
                  title: 'No se pudo abrir la tienda',
                  description: state.error!,
                  action: AppButton(
                    label: 'Reintentar',
                    icon: LucideIcons.refreshCw,
                    onPressed: context.read<RewardsCubit>().load,
                  ),
                ),
              );
            }
            final items = state.items
                .where((i) => _filter == 'all' || i.category == _filter)
                .toList();

            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: context.read<RewardsCubit>().load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(state)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _FittingRoom(
                        state: state,
                        preview: _preview,
                        onClearPreview: () => setState(() => _preview = null),
                      ),
                    ),
                  ),
                  if (state.summary != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _WeeklyGoalsCard(goals: state.summary!.weeklyGoals),
                      ),
                    ),
                  SliverToBoxAdapter(child: _filterChips()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _ItemCard(
                          item: items[i],
                          points: state.points,
                          outfit: state.outfit,
                          onTap: () => _openItem(items[i]),
                        ),
                        childCount: items.length,
                      ),
                    ),
                  ),
                  if (state.summary != null) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                        child: _SectionTitle('Logros'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.92,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => _AchievementTile(
                              achievement: state.summary!.achievements[i]),
                          childCount: state.summary!.achievements.length,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(RewardsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gasta tus puntos',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                SizedBox(height: 2),
                Text('Tienda',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          PointsChip(points: state.points),
          IconButton(
            tooltip: 'Historial de puntos',
            onPressed: _openHistory,
            icon: const Icon(LucideIcons.history, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (code, label, icon) = _filters[i];
          return AppToggleChip(
            label: label,
            icon: icon,
            selected: _filter == code,
            onChanged: (_) => setState(() => _filter = code),
          );
        },
      ),
    );
  }
}

// ─── Probador de Capsu ──────────────────────────────────────────────────────

class _FittingRoom extends StatelessWidget {
  final RewardsState state;
  final ShopItem? preview;
  final VoidCallback onClearPreview;

  const _FittingRoom({
    required this.state,
    required this.preview,
    required this.onClearPreview,
  });

  @override
  Widget build(BuildContext context) {
    final equipped = state.equipped;
    var outfit = state.outfit;
    var banner = state.item(equipped['banner']);
    var medal = state.item(equipped['medal']);

    final p = preview;
    if (p != null && p.slot != null) {
      if (p.category == 'capsu') outfit = outfit.withSlot(p.slot!, p.code);
      if (p.slot == 'banner') banner = p;
      if (p.slot == 'medal') medal = p;
    }

    final colors = banner != null && banner.colors.length >= 2
        ? banner.colors.map((c) => c.withValues(alpha: 0.55)).toList()
        : const [Color(0xFF1F1F1F), Color(0xFF181818)];

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.slow),
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.55, 0.4),
            child: Capsu(
              size: 112,
              mood: p != null ? CapsuMood.happy : CapsuMood.wave,
              outfit: outfit,
            ),
          ),
          if (medal != null)
            Positioned(
              left: 16,
              top: 14,
              child: Text(medal.icon, style: const TextStyle(fontSize: 30)),
            ),
          Positioned(
            right: 16,
            top: 18,
            bottom: 16,
            width: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Pill(
                  icon: LucideIcons.shield,
                  text: '${state.protectors} protector${state.protectors == 1 ? '' : 'es'}',
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      p != null
                          ? 'Probando:\n${p.name}'
                          : 'Toca un objeto para que Capsu se lo pruebe',
                      textAlign: TextAlign.right,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
                if (p != null)
                  AppButton(
                    label: 'Quitar prueba',
                    size: AppButtonSize.sm,
                    variant: AppButtonVariant.secondary,
                    onPressed: onClearPreview,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.info),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Objetivos semanales ────────────────────────────────────────────────────

class _WeeklyGoalsCard extends StatelessWidget {
  final List<WeeklyGoal> goals;
  const _WeeklyGoalsCard({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecorations.frame(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.target, size: 16, color: AppColors.accent),
              SizedBox(width: 6),
              Expanded(
                child: Text('Objetivos de la semana',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Text('+10 💎/día completo',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          for (final g in goals) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    g.title,
                    style: TextStyle(
                      color: g.completed ? AppColors.success : AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  g.completed ? '✓ +${g.points}' : '${g.progress}/${g.target} · +${g.points} 💎',
                  style: TextStyle(
                    color: g.completed ? AppColors.success : AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: g.progress / g.target,
                minHeight: 6,
                backgroundColor: AppColors.input,
                color: g.completed ? AppColors.success : AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Tarjeta de objeto ──────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final ShopItem item;
  final int points;
  final CapsuOutfit outfit;
  final VoidCallback onTap;

  const _ItemCard({
    required this.item,
    required this.points,
    required this.outfit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = rarityColor(item.rarity);
    final String status;
    final Color statusColor;
    if (item.equipped) {
      status = 'Equipado';
      statusColor = AppColors.success;
    } else if (item.isConsumable && item.isOwned) {
      status = 'Tienes ${item.owned}/${item.maxOwned}';
      statusColor = AppColors.info;
    } else if (item.isOwned) {
      status = 'En tu colección';
      statusColor = AppColors.textSecondary;
    } else if (item.exclusive) {
      status = '🔒 Exclusivo';
      statusColor = AppColors.textMuted;
    } else {
      status = '💎 ${item.price}';
      statusColor = points >= item.price! ? AppColors.neonGold : AppColors.textMuted;
    }

    return Semantics(
      button: true,
      label: '${item.name}, $status',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: item.equipped
                  ? AppColors.success.withValues(alpha: 0.6)
                  : color.withValues(alpha: 0.35),
              width: item.equipped ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rarityLabel(item.rarity).toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Expanded(
                child: Center(
                  child: Opacity(
                    opacity: item.exclusive && !item.isOwned ? 0.45 : 1,
                    child: ShopItemPreview(item: item, size: 70, baseOutfit: outfit),
                  ),
                ),
              ),
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detalle de objeto (comprar / equipar) ──────────────────────────────────

class _ItemSheet extends StatelessWidget {
  final String code;
  const _ItemSheet({required this.code});

  Future<void> _run(BuildContext context, Future<String?> Function() action,
      String successMessage) async {
    final error = await action();
    if (!context.mounted) return;
    if (error != null) {
      AppToast.error(context, error);
    } else {
      AppToast.success(context, successMessage);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RewardsCubit, RewardsState>(
      builder: (context, state) {
        final item = state.item(code);
        if (item == null) return const SizedBox.shrink();
        final cubit = context.read<RewardsCubit>();
        final busy = state.busyCode == code;

        late final String label;
        VoidCallback? onPressed;
        var variant = AppButtonVariant.primary;
        String? hint;

        if (item.isOwned && item.slot != null) {
          label = item.equipped ? 'Quitar' : 'Equipar';
          variant = item.equipped ? AppButtonVariant.outline : AppButtonVariant.primary;
          onPressed = () => _run(context, () => cubit.toggleEquip(item),
              item.equipped ? 'Objeto quitado' : '¡Equipado!');
        } else if (item.exclusive) {
          label = 'Se consigue con un logro';
          hint = 'Mira la sección de logros de la tienda.';
        } else if (item.isMaxed) {
          label = 'Tienes el máximo (${item.maxOwned})';
        } else if (state.points < item.price!) {
          label = 'Comprar · 💎 ${item.price}';
          hint = 'Te faltan ${item.price! - state.points} puntos.';
        } else {
          label = 'Comprar · 💎 ${item.price}';
          onPressed = () => _run(context, () async {
                final error = await cubit.buy(item.code);
                // Los objetos de colección se equipan solos al comprarlos
                if (error == null && item.slot != null) {
                  final bought = cubit.state.item(item.code);
                  if (bought != null && !bought.equipped) {
                    return cubit.toggleEquip(bought);
                  }
                }
                return error;
              }, '¡Comprado!');
        }

        return Container(
          padding: EdgeInsets.fromLTRB(
              24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 130,
                child: Center(
                  child: ShopItemPreview(
                      item: item, size: 120, baseOutfit: state.outfit),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                rarityLabel(item.rarity).toUpperCase(),
                style: TextStyle(
                  color: rarityColor(item.rarity),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (item.isConsumable && item.isOwned) ...[
                const SizedBox(height: 8),
                Text('Tienes ${item.owned} de ${item.maxOwned}',
                    style: const TextStyle(color: AppColors.info, fontSize: 13)),
              ],
              const SizedBox(height: 20),
              AppButton(
                label: label,
                expand: true,
                size: AppButtonSize.lg,
                variant: variant,
                loading: busy,
                onPressed: onPressed,
              ),
              if (hint != null) ...[
                const SizedBox(height: 8),
                Text(hint,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Logros ─────────────────────────────────────────────────────────────────

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Semantics(
      label: '${a.title}, ${a.unlocked ? 'conseguido' : 'pendiente'}. ${a.description}',
      excludeSemantics: true,
      button: true,
      child: GestureDetector(
        onTap: () => AppToast.info(
          context,
          '${a.unlocked ? '✅' : '🔒'} ${a.title}: ${a.description} '
          '(+${a.points} 💎${a.rewardItem != null ? ' + medalla exclusiva' : ''})',
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: a.unlocked
                ? AppColors.gold.withValues(alpha: 0.10)
                : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: a.unlocked
                  ? AppColors.gold.withValues(alpha: 0.45)
                  : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: a.unlocked ? 1 : 0.3,
                child: Text(a.icon, style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 6),
              Text(
                a.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: a.unlocked ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      );
}

// ─── Historial de puntos ────────────────────────────────────────────────────

class _HistorySheet extends StatelessWidget {
  final RewardsRemoteDataSource dataSource;
  const _HistorySheet({required this.dataSource});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Icon(LucideIcons.history, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Text('Historial de puntos',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PointsMovement>>(
              future: dataSource.getHistory(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(
                    child: Text('No se pudo cargar el historial',
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                final moves = snap.data!;
                if (moves.isEmpty) {
                  return const Center(
                    child: Text('Aún no has ganado puntos.\n¡Completa tu primer día!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  itemCount: moves.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final m = moves[i];
                    final positive = m.amount >= 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.reason,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  '${m.createdAt.day}/${m.createdAt.month}/${m.createdAt.year}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${positive ? '+' : ''}${m.amount}',
                            style: TextStyle(
                              color: positive ? AppColors.success : AppColors.error,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
