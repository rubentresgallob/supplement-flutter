import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:supplement_tracker/core/theme/forui_theme.dart';
import 'package:supplement_tracker/core/widgets/ui/ui.dart';

/// Igual que en la app: español + tema forui.
Widget _app(Widget Function(BuildContext) onTap) => MaterialApp(
      locale: AppLocalization.locale,
      localizationsDelegates: AppLocalization.delegates,
      supportedLocales: AppLocalization.supportedLocales,
      builder: (context, child) => FTheme(data: AppForuiTheme.data, child: child!),
      home: Scaffold(body: Builder(builder: onTap)),
    );

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('showAppConfirm devuelve true al confirmar', (tester) async {
    bool? result;
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async => result = await showAppConfirm(context,
              title: '¿Eliminar?', body: 'Seguro', confirmLabel: 'Eliminar', destructive: true),
          child: const Text('abrir'),
        )));
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    expect(find.text('¿Eliminar?'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await _settle(tester);
    expect(result, isTrue);
  });

  testWidgets('showAppConfirm devuelve false al cancelar', (tester) async {
    bool? result;
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async => result = await showAppConfirm(context,
              title: '¿Eliminar?', body: 'Seguro', confirmLabel: 'Eliminar'),
          child: const Text('abrir'),
        )));
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await tester.tap(find.text('Cancelar'));
    await _settle(tester);
    expect(result, isFalse);
  });

  testWidgets('showAppPrompt devuelve el texto escrito', (tester) async {
    String? result;
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async => result = await showAppPrompt(context,
              title: 'Añadir amigo', body: 'Usuario', confirmLabel: 'Enviar'),
          child: const Text('abrir'),
        )));
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), '  laura  ');
    await tester.tap(find.text('Enviar'));
    await _settle(tester);
    expect(result, 'laura');
  });

  testWidgets('showReminderTimePicker devuelve la hora inicial al guardar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    TimeOfDay? result;
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async => result = await showReminderTimePicker(context,
              initial: const TimeOfDay(hour: 21, minute: 32)),
          child: const Text('abrir'),
        )));
    await tester.tap(find.text('abrir'));
    await _settle(tester);
    expect(find.text('Hora del recordatorio'), findsOneWidget);
    await tester.tap(find.text('Guardar hora'));
    await _settle(tester);
    // 21:32 se redondea a 21:30 (la rueda va de 5 en 5)
    expect(result, const TimeOfDay(hour: 21, minute: 30));
  });
}
