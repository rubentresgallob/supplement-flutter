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

/// Etiqueta "Pro".
class ProBadge extends StatelessWidget {
  final bool large;
  const ProBadge({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? AppSpace.md : AppSpace.sm,
          vertical: large ? AppSpace.xs : 2),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.ring),
      ),
      child: Text(
        'Pro',
        style: (large ? AppText.label : AppText.micro)
            .copyWith(color: AppColors.accent),
      ),
    );
  }
}

/// Icono de cada ventaja Pro (el backend manda un emoji; se traduce por `code`).
IconData proFeatureIcon(String code) => switch (code) {
      'stock' => LucideIcons.package,
      'stats' => LucideIcons.chartColumn,
      'pdf' => LucideIcons.fileText,
      'points' => LucideIcons.gem,
      'protector' => LucideIcons.shieldCheck,
      'items' => LucideIcons.crown,
      _ => LucideIcons.sparkles,
    };

/// Lo que se muestra si el backend aún no ha respondido.
const _fallbackFeatures = [
  ProFeature(code: 'stock', icon: '', title: 'Control de stock', description: 'Te avisa antes de que se te acabe un suplemento.'),
  ProFeature(code: 'stats', icon: '', title: 'Estadísticas avanzadas', description: 'Calendario de cumplimiento, gráficos y mejores días.'),
  ProFeature(code: 'pdf', icon: '', title: 'Informe en PDF', description: 'Para tu médico o nutricionista.'),
  ProFeature(code: 'points', icon: '', title: 'Puntos x1,5', description: 'Más puntos por cada día completo y objetivo semanal.'),
  ProFeature(code: 'protector', icon: '', title: 'Protector gratis cada mes', description: 'Tu racha, siempre a salvo.'),
  ProFeature(code: 'items', icon: '', title: 'Objetos exclusivos de Capsu', description: 'Aureola, Capsu galaxia y más, solo para Pro.'),
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
    AppToast.success(context, 'Ya eres Pro');
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
      body: AmbientBackground(
        child: BlocBuilder<ProCubit, ProState>(
          builder: (context, state) {
            final status = state.status;
            final features =
                status.features.isNotEmpty ? status.features : _fallbackFeatures;
            final prices =
                status.prices.isNotEmpty ? status.prices : _fallbackPrices;

            return SafeArea(
              bottom: false,
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
                      padding: const EdgeInsets.fromLTRB(
                          AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
                      children: [
                        Reveal(child: _hero(state.isPro)),
                        const SizedBox(height: AppSpace.xl),
                        if (status.testMode && !state.isPro) ...[
                          const AppAlert(
                            variant: AppAlertVariant.info,
                            message:
                                'Modo de prueba: puedes activar Pro gratis para probarlo. No se cobra nada.',
                          ),
                          const SizedBox(height: AppSpace.lg),
                        ],
                        Reveal(
                          delay: Reveal.step2,
                          child: GlassCard(
                            blur: true,
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpace.lg, vertical: AppSpace.sm),
                            child: Column(
                              children: [
                                for (final f in features) _FeatureRow(feature: f),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Reveal(
                    delay: Reveal.step3,
                    child: BottomActions(
                      children: [
                        if (state.isPro)
                          _proFooter(status, state.loading)
                        else ...[
                          // Precios siempre a la vista, junto a la acción
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final p in prices) ...[
                                Expanded(
                                  child: _PriceCard(
                                    price: p,
                                    selected: _selected == p.id,
                                    onTap: () => setState(() => _selected = p.id),
                                  ),
                                ),
                                if (p != prices.last) const SizedBox(width: AppSpace.md),
                              ],
                            ],
                          ),
                          AppButton(
                            label: 'Empezar ${status.trialDays} días gratis',
                            size: AppButtonSize.lg,
                            expand: true,
                            loading: state.loading,
                            onPressed: () => _activate(status),
                          ),
                          Column(
                            children: [
                              const Text(
                                'Se renueva automáticamente. Cancela cuando quieras desde tu tienda de apps.',
                                textAlign: TextAlign.center,
                                style: AppText.caption,
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _LegalLink('Términos',
                                      () => openLegalPage(context, LegalPage.terms)),
                                  const Text('·', style: AppText.caption),
                                  _LegalLink('Privacidad',
                                      () => openLegalPage(context, LegalPage.privacy)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _hero(bool isPro) {
    return Column(
      children: [
        const HeroGlow(
          size: 240,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -48,
                top: 8,
                child: Floating(
                    phase: 0.3, amplitude: 5, child: IridescentOrb(size: 18)),
              ),
              Positioned(
                right: -56,
                bottom: 12,
                child: Floating(
                    phase: 0.75, amplitude: 8, child: IridescentOrb(size: 26)),
              ),
              Floating(
                child: Capsu(
                  size: 120,
                  mood: CapsuMood.celebrate,
                  outfit: CapsuOutfit(
                      head: 'capsu_head_crown', skin: 'capsu_skin_galaxy'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hazte', style: AppText.title),
            SizedBox(width: AppSpace.sm),
            ProBadge(large: true),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          isPro
              ? 'Gracias por apoyar la app'
              : 'Lleva tu constancia al siguiente nivel',
          textAlign: TextAlign.center,
          style: AppText.brandSubtitle,
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
          style: AppText.label.copyWith(color: AppColors.mint),
        ),
        if (status.source == 'test' && status.testMode) ...[
          const SizedBox(height: AppSpace.md),
          AppButton(
            label: 'Quitar Pro de prueba',
            variant: AppButtonVariant.outline,
            size: AppButtonSize.lg,
            expand: true,
            loading: loading,
            onPressed: _deactivate,
          ),
        ],
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LegalLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: PressableScale(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.sm),
          child: Text(label,
              style: AppText.caption.copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final ProFeature feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          IconChip(icon: proFeatureIcon(feature.code), highlighted: true),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: AppText.label),
                const SizedBox(height: 2),
                Text(feature.description, style: AppText.caption),
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
      child: PressableScale(
        onTap: onTap,
        scale: 0.98,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSelected : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected ? AppColors.ring : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(price.label,
                        style: AppText.label
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                  SelectionMark(selected: selected),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(price.price, style: AppText.title),
              Text(price.period, style: AppText.caption),
              if (price.note != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(price.note!,
                    style: AppText.micro.copyWith(color: AppColors.accent)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
