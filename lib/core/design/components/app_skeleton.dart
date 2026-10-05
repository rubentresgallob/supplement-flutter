import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';

/// Skeleton con brillo diagonal (120°) como `Skeleton` de coss.
/// Todos los skeletons dentro de un [AppSkeletonGroup] comparten animación.
class AppSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;

  const AppSkeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
    this.shape = BoxShape.rectangle,
  });

  const AppSkeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  @override
  Widget build(BuildContext context) {
    final anim = _SkeletonScope.maybeOf(context);
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );
    if (anim == null) return box;

    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final t = anim.value; // 0 → 1
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment(-1.0 + 4 * t - 1.5, -0.4),
            end: Alignment(1.0 + 4 * t - 1.5, 0.4),
            colors: const [
              Color(0x00FFFFFF),
              Color(0x14FFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(rect),
          child: child,
        );
      },
      child: box,
    );
  }
}

/// Lista de filas skeleton (avatar + dos líneas) para pantallas de listado.
class AppListSkeleton extends StatelessWidget {
  final int itemCount;
  final bool circleLeading;
  final EdgeInsetsGeometry padding;

  const AppListSkeleton({
    super.key,
    this.itemCount = 6,
    this.circleLeading = false,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return AppSkeletonGroup(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => Container(
          padding: const EdgeInsets.all(14),
          decoration: AppDecorations.frame(radius: AppRadius.xl),
          child: Row(
            children: [
              circleLeading
                  ? const AppSkeleton.circle(size: 44)
                  : const AppSkeleton(width: 44, height: 44, radius: AppRadius.lg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton(width: 110.0 + (i % 3) * 30, height: 13),
                    const SizedBox(height: 8),
                    AppSkeleton(width: 80.0 + (i % 2) * 30, height: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Proveedor de la animación compartida del skeleton.
class AppSkeletonGroup extends StatefulWidget {
  final Widget child;
  const AppSkeletonGroup({super.key, required this.child});

  @override
  State<AppSkeletonGroup> createState() => _AppSkeletonGroupState();
}

class _AppSkeletonGroupState extends State<AppSkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Cargando',
        liveRegion: true,
        child: ExcludeSemantics(
          child: _SkeletonScope(animation: _ctrl, child: widget.child),
        ),
      );
}

class _SkeletonScope extends InheritedWidget {
  final Animation<double> animation;
  const _SkeletonScope({required this.animation, required super.child});

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.animation;

  @override
  bool updateShouldNotify(_SkeletonScope old) => old.animation != animation;
}
