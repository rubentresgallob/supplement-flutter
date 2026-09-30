import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/core/widgets/mascot/capsu.dart';
import 'package:supplement_tracker/presentation/onboarding/pages/onboarding_page.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('Capsu', () {
    testWidgets('se dibuja en todos los estados de ánimo sin errores', (tester) async {
      for (final mood in CapsuMood.values) {
        await tester.pumpWidget(_wrap(Capsu(mood: mood, lookAt: const Offset(1, 1))));
        await tester.pump(const Duration(milliseconds: 500));
        expect(tester.takeException(), isNull, reason: 'estado $mood');
      }
    });

    testWidgets('cambia de estado con transición sin errores', (tester) async {
      await tester.pumpWidget(_wrap(const Capsu(mood: CapsuMood.idle)));
      await tester.pumpWidget(_wrap(const Capsu(mood: CapsuMood.shy)));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tiene etiqueta para lectores de pantalla y responde al toque', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(Capsu(onTap: () => taps++)));
      expect(find.bySemanticsLabel('Capsu, la mascota de la app'), findsOneWidget);
      await tester.tap(find.byType(Capsu));
      expect(taps, 1);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('el bocadillo escribe el texto completo', (tester) async {
      await tester.pumpWidget(_wrap(const CapsuBubble(text: 'Hola')));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Hola'), findsWidgets);
    });
  });

  group('Tutorial', () {
    testWidgets('"Saltar" termina el tutorial', (tester) async {
      var done = false;
      await tester.pumpWidget(MaterialApp(home: OnboardingPage(onDone: () => done = true)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Saltar'));
      expect(done, isTrue);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('"Siguiente" avanza hasta "¡Empezar!"', (tester) async {
      var done = false;
      await tester.pumpWidget(MaterialApp(home: OnboardingPage(onDone: () => done = true)));
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Siguiente'));
        // Capsu anima sin fin (no sirve pumpAndSettle): avanzamos varios fotogramas
        for (var f = 0; f < 12; f++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
      }
      expect(find.text('¡Empezar!'), findsOneWidget);
      await tester.tap(find.text('¡Empezar!'));
      expect(done, isTrue);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
