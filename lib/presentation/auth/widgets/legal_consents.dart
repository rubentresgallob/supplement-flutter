import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/legal_links.dart';
import '../../../core/widgets/ui/ui.dart';

/// Estado de las tres casillas obligatorias (registro y reaceptación).
class LegalConsentsValue {
  final bool adult;
  final bool terms;
  final bool health;

  const LegalConsentsValue({this.adult = false, this.terms = false, this.health = false});

  bool get all => adult && terms && health;

  LegalConsentsValue copyWith({bool? adult, bool? terms, bool? health}) => LegalConsentsValue(
        adult: adult ?? this.adult,
        terms: terms ?? this.terms,
        health: health ?? this.health,
      );
}

/// Las tres casillas separadas y sin premarcar que exige el registro (RGPD art. 7 y 9):
/// edad, términos + privacidad y consentimiento explícito para datos de salud.
class LegalConsents extends StatefulWidget {
  final LegalConsentsValue value;
  final ValueChanged<LegalConsentsValue> onChanged;
  final bool enabled;

  const LegalConsents({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<LegalConsents> createState() => _LegalConsentsState();
}

class _LegalConsentsState extends State<LegalConsents> {
  late final _termsTap = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.terms);
  late final _privacyTap = TapGestureRecognizer()
    ..onTap = () => openLegalPage(context, LegalPage.privacy);

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;
    final base = AppText.caption.copyWith(color: AppColors.textSecondary);
    final link = AppText.caption.copyWith(
      color: AppColors.textPrimary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.borderStrong,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConsentRow(
          selected: v.adult,
          enabled: widget.enabled,
          onTap: () => widget.onChanged(v.copyWith(adult: !v.adult)),
          child: Text('Tengo 18 años o más.', style: base),
        ),
        _ConsentRow(
          selected: v.terms,
          enabled: widget.enabled,
          onTap: () => widget.onChanged(v.copyWith(terms: !v.terms)),
          child: Text.rich(TextSpan(style: base, children: [
            const TextSpan(text: 'He leído y acepto los '),
            TextSpan(text: 'Términos de uso', recognizer: _termsTap, style: link),
            const TextSpan(text: ' y la '),
            TextSpan(text: 'Política de privacidad', recognizer: _privacyTap, style: link),
            const TextSpan(text: '.'),
          ])),
        ),
        _ConsentRow(
          selected: v.health,
          enabled: widget.enabled,
          onTap: () => widget.onChanged(v.copyWith(health: !v.health)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Consiento expresamente que se traten mis datos de salud (los suplementos que tomo, '
                'sus dosis y mi registro de tomas) para que la app funcione. Puedo retirar este '
                'consentimiento eliminando mi cuenta.',
                style: base,
              ),
              const SizedBox(height: AppSpace.xs),
              const Text(
                'Es obligatorio: registrar tus suplementos y tus tomas es justo lo que hace la app, '
                'así que sin estos datos no puede funcionar.',
                style: AppText.micro,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentRow extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _ConsentRow({
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SelectionMark(selected: selected, multi: true),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enlaces a los dos textos, visibles sin sesión (login, registro).
class LegalFooterLinks extends StatelessWidget {
  const LegalFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    Widget link(String label, LegalPage page) => PressableScale(
          onTap: () => openLegalPage(context, page),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.sm),
            child: Text(label, style: AppText.micro.copyWith(decoration: TextDecoration.underline)),
          ),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        link('Términos de uso', LegalPage.terms),
        link('Política de privacidad', LegalPage.privacy),
      ],
    );
  }
}
