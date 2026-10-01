import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
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
              child: GestureDetector(
                onTap: () => openProPage(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.22),
                        AppColors.gold.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.crown, color: AppColors.neonGold, size: 26),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  state.isPro ? 'Eres Pro' : 'Hazte Pro',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
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
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12.5),
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
              child: GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const StatsPage())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: AppDecorations.frame(radius: 16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.chartColumn,
                          color: AppColors.textSecondary, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Estadísticas',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
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
