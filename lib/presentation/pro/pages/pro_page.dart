import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/widgets/mascot/capsu.dart';
import '../../../core/widgets/ui/ui.dart';
import '../../../core/utils/legal_links.dart';
import '../../../data/models/pro_models.dart';
import '../../rewards/bloc/rewards_cubit.dart';
import '../bloc/pro_cubit.dart';

/// Abre la pantalla "Hazte Pro".
Future<void> openProPage(BuildContext context) {
  context.read<ProCubit>().load();
  return Navigator.of(context).push(
    MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ProPage()),
  );
}

/// Etiqueta dorada "PRO".
class ProBadge extends StatelessWidget {
  final double fontSize;
  const ProBadge({super.key, this.fontSize = 9.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.2),
      decoration: BoxDecoration(
        gradient: AppGradients.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: AppColors.onPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Lo que se muestra si el backend aún no ha respondido.
const _fallbackFeatures = [
  ProFeature(code: 'stock', icon: '📦', title: 'Control de stock', description: 'Te avisa antes de que se te acabe un suplemento.'),
  ProFeature(code: 'stats', icon: '📊', title: 'Estadísticas avanzadas', description: 'Calendario de cumplimiento, gráficos y mejores días.'),
  ProFeature(code: 'pdf', icon: '📄', title: 'Informe en PDF', description: 'Para tu médico o nutricionista.'),
  ProFeature(code: 'points', icon: '💎', title: 'Puntos x1,5', description: 'Más puntos por cada día completo y objetivo semanal.'),
  ProFeature(code: 'protector', icon: '🛡️', title: 'Protector gratis cada mes', description: 'Tu racha, siempre a salvo.'),
  ProFeature(code: 'items', icon: '👑', title: 'Objetos exclusivos de Capsu', description: 'Aureola, Capsu galaxia y más, solo para Pro.'),
];

const _fallbackPrices = [
  ProPrice(id: 'monthly', label: 'Mensual', price: '2,99 €', period: 'al mes'),
  ProPrice(id: 'yearly', label: 'Anual', price: '19,99 €', period: 'al año', note: '1,67 €/mes · ahorras un 44 %', highlight: true),
];

class ProPage extends StatefulWidget {
  const ProPage({super.key});

  @override
  State<ProPage> createState() => _ProPageState();
}

class _ProPageState extends State<ProPage> {
  String _selected = 'yearly';

  Future<void> _activate(ProStatus status) async {
    if (!status.testMode) {
      // Los pagos reales (Apple/Google vía RevenueCat) se conectan al publicar la app
      AppToast.info(context, 'Las suscripciones estarán disponibles al publicar la app.');
      return;
    }
    final error = await context.read<ProCubit>().activate();
    if (!mounted) return;
    if (error != null) {
      AppToast.error(context, error);
      return;
    }
    context.read<RewardsCubit>().load(); // objetos Pro y protector del mes
    AppToast.success(context, '¡Ya eres Pro! 👑');
    Navigator.of(context).pop();
  }

  Future<void> _deactivate() async {
    final error = await context.read<ProCubit>().deactivate();
    if (!mounted) return;
    if (error != null) {
      AppToast.error(context, error);
    } else {
      context.read<RewardsCubit>().load();
      AppToast.info(context, 'Pro de prueba desactivado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: BlocBuilder<ProCubit, ProState>(
        builder: (context, state) {
          final status = state.status;
          final features =
              status.features.isNotEmpty ? status.features : _fallbackFeatures;
          final prices = status.prices.isNotEmpty ? status.prices : _fallbackPrices;

          return SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(LucideIcons.x, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      _hero(state.isPro),
                      const SizedBox(height: 20),
                      if (status.testMode && !state.isPro) ...[
                        const AppAlert(
                          variant: AppAlertVariant.info,
                          message:
                              'Modo de prueba: puedes activar Pro gratis para probarlo. No se cobra nada.',
                        ),
                        const SizedBox(height: 16),
                      ],
                      for (final f in features) _FeatureRow(feature: f),
                      const SizedBox(height: 20),
                      if (!state.isPro)
                        Row(
                          children: [
                            for (final p in prices) ...[
                              Expanded(
                                child: _PriceCard(
                                  price: p,
                                  selected: _selected == p.id,
                                  onTap: () => setState(() => _selected = p.id),
                                ),
                              ),
                              if (p != prices.last) const SizedBox(width: 10),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: state.isPro
                      ? _proFooter(status, state.loading)
                      : Column(
                          children: [
                            AppButton(
                              label: 'Empezar ${status.trialDays} días gratis',
                              icon: LucideIcons.crown,
                              size: AppButtonSize.lg,
                              expand: true,
                              loading: state.loading,
                              onPressed: () => _activate(status),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Se renueva automáticamente. Cancela cuando quieras desde tu tienda de apps.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () => openLegalPage(context, LegalPage.terms),
                                  child: const Text('Términos',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ),
                                const Text('·', style: TextStyle(color: AppColors.textMuted)),
                                TextButton(
                                  onPressed: () => openLegalPage(context, LegalPage.privacy),
                                  child: const Text('Privacidad',
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _hero(bool isPro) {
    return Column(
      children: [
        const Capsu(
          size: 120,
          mood: CapsuMood.celebrate,
          outfit: CapsuOutfit(head: 'capsu_head_crown', skin: 'capsu_skin_gold'),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (b) => AppGradients.accent.createShader(b),
              child: const Text(
                'Hazte',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const ProBadge(fontSize: 16),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          isPro ? '¡Gracias por apoyar la app! 🧡' : 'Lleva tu constancia al siguiente nivel',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ],
    );
  }

  Widget _proFooter(ProStatus status, bool loading) {
    final until = status.proUntil;
    return Column(
      children: [
        Text(
          until == null
              ? 'Tienes Pro activo'
              : 'Pro activo hasta el ${until.day}/${until.month}/${until.year}',
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (status.source == 'test' && status.testMode) ...[
          const SizedBox(height: 10),
          AppButton(
            label: 'Quitar Pro de prueba',
            variant: AppButtonVariant.outline,
            expand: true,
            loading: loading,
            onPressed: _deactivate,
          ),
        ],
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final ProFeature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(feature.icon, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(feature.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12.5, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final ProPrice price;
  final bool selected;
  final VoidCallback onTap;

  const _PriceCard({required this.price, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${price.label}, ${price.price} ${price.period}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold.withValues(alpha: 0.10) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(price.label,
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                  if (price.highlight)
                    const Text('⭐', style: TextStyle(fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Text(price.price,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(price.period,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              if (price.note != null) ...[
                const SizedBox(height: 6),
                Text(price.note!,
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
