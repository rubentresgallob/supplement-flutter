import 'package:flutter/material.dart';
import '../tokens.dart';
import '../typography.dart';
import 'surfaces.dart';

/// Opción de selección única o múltiple (`multi: true`).
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.multi = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: PressableScale(
        onTap: onTap,
        scale: 0.98,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceSelected : AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadii.tile),
            border: Border.all(
                color: selected ? AppColors.ring : Colors.transparent, width: 1.2),
          ),
          child: Row(children: [
            SelectionMark(selected: selected, multi: multi),
            const SizedBox(width: AppSpace.md),
            if (leading != null) ...[leading!, const SizedBox(width: AppSpace.sm)],
            Expanded(
                child: Text(label,
                    style: AppText.label, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }
}

/// Anillo de 20 con punto interior de 10 (radio o casilla).
class SelectionMark extends StatelessWidget {
  const SelectionMark({super.key, required this.selected, this.multi = false});
  final bool selected;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.medium,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(multi ? AppRadii.chip : AppRadii.tile),
        border: Border.all(
            color: selected ? AppColors.accentStrong : AppColors.textTertiary,
            width: 1.5),
      ),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1 : 0,
          duration: AppMotion.medium,
          curve: AppMotion.pop,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.accentStrong,
              borderRadius: BorderRadius.circular(multi ? 3 : 5),
              boxShadow: const [BoxShadow(color: AppColors.glow, blurRadius: 8)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Línea fina de progreso (pasos de un flujo, objetivos, adherencia).
class FlowProgress extends StatelessWidget {
  const FlowProgress({super.key, required this.value, this.height = 2});
  final double value; // 0..1
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          const ColoredBox(color: AppColors.border),
          AnimatedFractionallySizedBox(
            duration: AppMotion.of(context, AppMotion.slow),
            curve: AppMotion.emphasized,
            alignment: Alignment.centerLeft,
            widthFactor: value.clamp(0.0, 1.0),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [AppColors.textPrimary, AppColors.accent]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          margin: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.accentStrong : AppColors.textTertiary,
          ),
        );
      }),
    );
  }
}

/// Entrada orquestada de las pantallas de flujo: fundido + 8 px hacia arriba.
/// Una sola vez al aparecer; en listas y pantallas de uso diario no se usa.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  /// Escalonado estándar: hero → título → texto → CTA.
  static const step1 = Duration(milliseconds: 80);
  static const step2 = Duration(milliseconds: 140);
  static const step3 = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;
    final total = AppMotion.slow + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.standard),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
      ),
    );
  }
}

/// Cifra que cuenta desde el valor anterior (puntos, racha, precio).
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.suffix = ''});
  final int value;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.standard,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style),
    );
  }
}

/// Pie de pantalla con los CTA anclados abajo.
class BottomActions extends StatelessWidget {
  const BottomActions({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(
          AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpace.md),
          children[i],
        ],
      ]),
    );
  }
}
