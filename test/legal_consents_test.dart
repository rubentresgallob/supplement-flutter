import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/core/design/design.dart';
import 'package:supplement_tracker/data/models/user_model.dart';
import 'package:supplement_tracker/presentation/auth/widgets/legal_consents.dart';

void main() {
  testWidgets('las tres casillas empiezan sin marcar y hacen falta las tres', (tester) async {
    var value = const LegalConsentsValue();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => LegalConsents(
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));

    expect(value.all, isFalse);
    // Se toca la casilla (en el texto de la segunda están los enlaces)
    await tester.tap(find.byType(SelectionMark).at(0));
    await tester.pump();
    await tester.tap(find.byType(SelectionMark).at(1));
    await tester.pump();
    expect(value.adult && value.terms, isTrue);
    expect(value.all, isFalse); // falta el consentimiento de datos de salud

    await tester.tap(find.byType(SelectionMark).at(2));
    await tester.pump();
    expect(value.all, isTrue);
  });

  test('el perfil indica si hay que volver a aceptar los textos', () {
    final user = UserModel.fromJson(const {
      'id': 1,
      'email': 'a@b.c',
      'username': 'ana',
      'created_at': '2026-10-01T00:00:00.000Z',
      'legal': {
        'needsAcceptance': true,
        'changes': ['Nueva política'],
      },
    });
    expect(user.needsLegalAcceptance, isTrue);
    expect(user.legalChanges, ['Nueva política']);
    expect(user.copyWith(needsLegalAcceptance: false).needsLegalAcceptance, isFalse);
  });
}
