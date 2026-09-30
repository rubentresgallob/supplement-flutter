import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supplement_tracker/core/widgets/ui/ui.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('AppButton', () {
    testWidgets('llama a onPressed al pulsar', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
          _wrap(AppButton(label: 'Guardar', onPressed: () => taps++)));
      await tester.tap(find.text('Guardar'));
      expect(taps, 1);
    });

    testWidgets('no responde mientras carga', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
          AppButton(label: 'Guardar', loading: true, onPressed: () => taps++)));
      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('cumple la zona táctil mínima de 44pt', (tester) async {
      await tester.pumpWidget(_wrap(AppButton(
          label: 'OK', size: AppButtonSize.sm, onPressed: () {})));
      final size = tester.getSize(find.byType(AnimatedContainer));
      expect(size.width, greaterThanOrEqualTo(AppSpacing.minTouch));
    });
  });

  group('AppNumberField', () {
    testWidgets('respeta los límites min/max', (tester) async {
      var value = 1;
      await tester.pumpWidget(_wrap(StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 300,
          child: AppNumberField(
            value: value,
            min: 1,
            max: 2,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      )));
      await tester.tap(find.byIcon(LucideIcons.minus));
      expect(value, 1);
      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.plus));
      expect(value, 2);
    });
  });

  group('AppToggleChip', () {
    testWidgets('alterna la selección', (tester) async {
      bool? changed;
      await tester.pumpWidget(_wrap(AppToggleChip(
          label: 'Mañana', selected: false, onChanged: (v) => changed = v)));
      await tester.tap(find.text('Mañana'));
      expect(changed, isTrue);
    });
  });
}
