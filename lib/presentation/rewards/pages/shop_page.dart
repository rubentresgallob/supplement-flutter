import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../data/datasources/rewards_remote_datasource.dart';
import '../../../data/models/rewards_models.dart';
import '../bloc/rewards_cubit.dart';
import '../widgets/rewards_widgets.dart';
import '../../pro/bloc/pro_cubit.dart';
import '../../pro/pages/pro_page.dart';

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
    ('pro', 'Pro', LucideIcons.crown),
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
      body: AmbientBackground(
        child: SafeArea(
        bottom: false,
        child: BlocBuilder<RewardsCubit, RewardsState>(
          builder: (context, state) {
            if (state.loading && state.summary == null) {
              return const Center(child: CircularProgressIndicator());
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
                    onPressed: context.read<RewardsCubit>().load,
                  ),
                ),
              );
            }
            final items = state.items
                .where((i) =>
                    _filter == 'all' ||
                    (_filter == 'pro' ? i.proOnly : i.category == _filter))
                .toList();

            return RefreshIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.surfaceRaised,
              onRefresh: context.read<RewardsCubit>().load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(state)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
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
                        padding: const EdgeInsets.fromLTRB(
                            AppSpace.screen, AppSpace.lg, AppSpace.screen, 0),
                        child: _WeeklyGoalsCard(goals: state.summary!.weeklyGoals),
                      ),
                    ),
                  SliverToBoxAdapter(child: _filterChips()),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
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
                        padding: EdgeInsets.fromLTRB(
                            AppSpace.screen, AppSpace.xxl, AppSpace.screen, AppSpace.md),
                        child: _SectionTitle('Logros'),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
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
      ),
    );
  }

  Widget _header(RewardsState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.lg, AppSpace.md, AppSpace.lg),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gasta tus puntos', style: AppText.brandSubtitle),
                SizedBox(height: AppSpace.xs),
                Text('Tienda', style: AppText.title),
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
        padding: const EdgeInsets.fromLTRB(
            AppSpace.screen, AppSpace.lg, AppSpace.screen, AppSpace.sm),
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
        ? banner.colors.map((c) => c.withValues(alpha: 0.4)).toList()
        : AppColors.cardGradient;

    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.emphasized,
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Align(
            alignment: const Alignment(-0.6, 0.3),
            child: HeroGlow(
              size: 170,
              child: Floating(
                amplitude: 4,
                child: Capsu(
                  size: 112,
                  mood: p != null ? CapsuMood.happy : CapsuMood.wave,
                  outfit: outfit,
                ),
              ),
            ),
          ),
          if (medal != null)
            Positioned(
              left: AppSpace.lg,
              top: AppSpace.lg,
              child: MedalIcon(medal: medal, size: 32),
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
                AppPill(
                  icon: LucideIcons.shield,
                  color: AppColors.textPrimary,
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
                      style: p != null ? AppText.label : AppText.body,
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
                    style: AppText.label),
              ),
              Text('+10 al día', style: AppText.micro),
            ],
          ),
          for (final g in goals) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    g.title,
                    style: AppText.captionStrong.copyWith(color: g.completed ? AppColors.success : AppColors.textSecondary),
                  ),
                ),
                Text(
                  g.completed ? '+${g.points}' : '${g.progress}/${g.target} · +${g.points}',
                  style: AppText.micro.copyWith(color: g.completed ? AppColors.success : AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FlowProgress(value: g.progress / g.target, height: 4),
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
    IconData? statusIcon;
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
      status = 'Exclusivo';
      statusIcon = LucideIcons.lock;
      statusColor = AppColors.textMuted;
    } else {
      status = '${item.price}';
      statusIcon = LucideIcons.gem;
      statusColor = points >= item.price! ? AppColors.textPrimary : AppColors.textMuted;
    }

    return Semantics(
      button: true,
      label: '${item.name}, $status',
      excludeSemantics: true,
      child: PressableScale(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(AppSpace.md),
          borderColor: item.equipped ? AppColors.ring : AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      rarityLabel(item.rarity),
                      style: AppText.micro.copyWith(color: color),
                    ),
                  ),
                  if (item.proOnly) const ProBadge(),
                ],
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
                style: AppText.label,
              ),
              const SizedBox(height: AppSpace.xs),
              Row(
                children: [
                  if (statusIcon != null) ...[
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: AppSpace.xs),
                  ],
                  Flexible(
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.captionStrong.copyWith(color: statusColor),
                    ),
                  ),
                ],
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
              item.equipped ? 'Objeto quitado' : 'Equipado');
        } else if (item.proOnly && !context.watch<ProCubit>().state.isPro) {
          label = 'Hazte Pro para conseguirlo';
          onPressed = () => openProPage(context);
          hint = 'Objeto exclusivo del plan Pro.';
        } else if (item.exclusive) {
          label = 'Se consigue con un logro';
          hint = 'Mira la sección de logros de la tienda.';
        } else if (item.isMaxed) {
          label = 'Tienes el máximo (${item.maxOwned})';
        } else if (state.points < item.price!) {
          label = 'Comprar · ${item.price} puntos';
          hint = 'Te faltan ${item.price! - state.points} puntos.';
        } else {
          label = 'Comprar · ${item.price} puntos';
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
              }, 'Comprado');
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
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 140,
                child: Center(
                  child: HeroGlow(
                    size: 180,
                    child: Floating(
                      amplitude: 4,
                      child: ShopItemPreview(
                          item: item, size: 120, baseOutfit: state.outfit),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                rarityLabel(item.rarity),
                style: AppText.brandSubtitle.copyWith(color: rarityColor(item.rarity)),
              ),
              const SizedBox(height: 4),
              Text(
                item.name,
                style: AppText.title,
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              if (item.isConsumable && item.isOwned) ...[
                const SizedBox(height: 8),
                Text('Tienes ${item.owned} de ${item.maxOwned}',
                    style: AppText.body.copyWith(color: AppColors.info)),
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
                    style: AppText.caption),
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
          '${a.title}: ${a.description} '
          '(+${a.points} puntos${a.rewardItem != null ? ' y medalla exclusiva' : ''})',
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: a.unlocked ? AppColors.surfaceSelected : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.button),
            border: Border.all(
              color: a.unlocked ? AppColors.ring : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: a.unlocked ? 1 : 0.4,
                child: IconChip(
                    icon: achievementIcon(a.code), highlighted: a.unlocked),
              ),
              const SizedBox(height: 6),
              Text(
                a.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.micro.copyWith(color: a.unlocked ? AppColors.textPrimary : AppColors.textMuted),
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
        style: AppText.section,
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
                    style: AppText.section),
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
                  return const Center(child: CircularProgressIndicator());
                }
                final moves = snap.data!;
                if (moves.isEmpty) {
                  return const Center(
                    child: Text('Aún no has ganado puntos.\nCompleta tu primer día.',
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
                                    style: AppText.body.copyWith(color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text(
                                  '${m.createdAt.day}/${m.createdAt.month}/${m.createdAt.year}',
                                  style: AppText.micro,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${positive ? '+' : ''}${m.amount}',
                            style: AppText.navTitle.copyWith(color: positive ? AppColors.success : AppColors.error),
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
