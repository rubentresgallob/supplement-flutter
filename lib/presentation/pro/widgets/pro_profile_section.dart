import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/ui/ui.dart';
import '../bloc/pro_cubit.dart';
import '../pages/pro_page.dart';
import '../pages/stats_page.dart';

/// Bloque del perfil: tarjeta del plan Pro + acceso a Estadísticas.
class ProProfileSection extends StatelessWidget {
  const ProProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProCubit, ProState>(
      builder: (context, state) {
        final until = state.status.proUntil;
        return Column(
          children: [
            Semantics(
              button: true,
              label: state.isPro ? 'Plan Pro activo' : 'Hazte Pro',
              excludeSemantics: true,
              child: PressableScale(
                onTap: () => openProPage(context),
                scale: 0.98,
                child: GlassCard(
                  borderColor: AppColors.ring,
                  child: Row(
                    children: [
                      const IconChip(icon: LucideIcons.crown, highlighted: true),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  state.isPro ? 'Eres Pro' : 'Hazte Pro',
                                  style: AppText.section,
                                ),
                                const SizedBox(width: 6),
                                const ProBadge(),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              state.isPro
                                  ? (until != null
                                      ? 'Activo hasta el ${until.day}/${until.month}/${until.year}'
                                      : 'Activo')
                                  : 'Stock, estadísticas, PDF y ventajas en la tienda',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Semantics(
              button: true,
              label: 'Estadísticas',
              excludeSemantics: true,
              child: PressableScale(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const StatsPage())),
                scale: 0.98,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.lg, vertical: AppSpace.md),
                  decoration: AppDecorations.frame(),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.chartColumn,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Estadísticas',
                            style: AppText.label),
                      ),
                      if (!state.isPro) ...[
                        const Icon(LucideIcons.lock, color: AppColors.textMuted, size: 15),
                        const SizedBox(width: 6),
                      ],
                      const Icon(LucideIcons.chevronRight, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
