import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplement_tracker/presentation/legal/legal_document_page.dart';

void main() {
  const docs = ['docs/legal/politica-privacidad.html', 'docs/legal/terminos.html'];

  for (final path in docs) {
    group(path, () {
      final html = File(path).readAsStringSync();

      test('solo usa h1, h2, p, ul, li, strong y a (sin estilos ni scripts)', () {
        final tags = RegExp(r'</?([a-zA-Z0-9]+)').allMatches(html).map((m) => m.group(1)!.toLowerCase()).toSet();
        expect(tags.difference({'h1', 'h2', 'p', 'ul', 'li', 'strong', 'a'}), isEmpty);
        expect(html.contains('style='), isFalse);
      });

      test('empieza con la fecha y la versión 1.0 (la misma que src/legal/legal.ts)', () {
        final blocks = parseLegalHtml(html);
        expect(blocks.first.type, LegalBlockType.h1);
        expect(blocks[1].spans.single.text, 'Última actualización: [FECHA]');
        expect(blocks[2].spans.single.text, 'Versión: 1.0');
      });

      test('no habla de funciones que esta versión no tiene', () {
        final lower = html.toLowerCase();
        for (final word in ['suscripción', 'pro ', 'revenuecat', 'anuncios personalizados', 'iniciar sesión con google', 'iniciar sesión con apple']) {
          expect(lower.contains(word), isFalse, reason: word);
        }
      });
    });
  }

  test('interpreta negritas y enlaces', () {
    final blocks = parseLegalHtml('<p>Hola <strong>tú</strong>, mira <a href="/terminos">esto</a> &amp; ya.</p>');
    final spans = blocks.single.spans;
    expect(spans.map((s) => s.text).join(), 'Hola tú, mira esto & ya.');
    expect(spans[1].bold, isTrue);
    expect(spans[3].href, '/terminos');
  });
}
