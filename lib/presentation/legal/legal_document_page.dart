import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/legal_links.dart';
import '../../core/widgets/ui/ui.dart';

/// Muestra un texto legal de `docs/legal/` (se puede abrir sin sesión).
/// Los textos usan solo <h1>, <h2>, <p>, <ul>, <li>, <strong> y <a>, así que
/// basta con un intérprete mínimo en vez de un paquete de HTML.
class LegalDocumentPage extends StatelessWidget {
  final LegalPage page;
  const LegalDocumentPage({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(LucideIcons.chevronLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(page.title),
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString(page.asset!),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('No se pudo abrir el texto', style: AppText.body));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final blocks = parseLegalHtml(snapshot.data!);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.xxl),
              itemCount: blocks.length,
              itemBuilder: (context, i) => _BlockView(block: blocks[i]),
            );
          },
        ),
      ),
    );
  }
}

enum LegalBlockType { h1, h2, p, li }

class LegalBlock {
  final LegalBlockType type;
  final List<LegalSpan> spans;
  const LegalBlock(this.type, this.spans);
}

class LegalSpan {
  final String text;
  final bool bold;
  final String? href;
  const LegalSpan(this.text, {this.bold = false, this.href});
}

/// Convierte el HTML sencillo de los textos legales en bloques.
List<LegalBlock> parseLegalHtml(String html) {
  final blocks = <LegalBlock>[];
  final block = RegExp(r'<(h1|h2|p|li)>([\s\S]*?)</\1>');
  for (final m in block.allMatches(html)) {
    final type = LegalBlockType.values.byName(m.group(1)!);
    blocks.add(LegalBlock(type, _inline(m.group(2)!)));
  }
  return blocks;
}

List<LegalSpan> _inline(String html) {
  final spans = <LegalSpan>[];
  final token = RegExp(r'<strong>([\s\S]*?)</strong>|<a href="([^"]*)">([\s\S]*?)</a>');
  var last = 0;
  for (final m in token.allMatches(html)) {
    if (m.start > last) spans.add(LegalSpan(_decode(html.substring(last, m.start))));
    if (m.group(1) != null) {
      spans.add(LegalSpan(_decode(m.group(1)!), bold: true));
    } else {
      spans.add(LegalSpan(_decode(m.group(3)!), href: m.group(2)));
    }
    last = m.end;
  }
  if (last < html.length) spans.add(LegalSpan(_decode(html.substring(last))));
  return spans;
}

String _decode(String s) => s
    .replaceAll(RegExp(r'<[^>]+>'), '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&amp;', '&');

class _BlockView extends StatefulWidget {
  final LegalBlock block;
  const _BlockView({required this.block});

  @override
  State<_BlockView> createState() => _BlockViewState();
}

class _BlockViewState extends State<_BlockView> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  /// "/privacidad" y "/terminos" se abren dentro de la app; el resto, fuera.
  void _open(String href) {
    final internal = switch (href) {
      '/privacidad' => LegalPage.privacy,
      '/terminos' => LegalPage.terms,
      _ => null,
    };
    if (internal != null) {
      openLegalPage(context, internal);
    } else {
      launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    final style = switch (block.type) {
      LegalBlockType.h1 => AppText.title,
      LegalBlockType.h2 => AppText.section,
      _ => AppText.body,
    };
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final text = Text.rich(TextSpan(
      style: style,
      children: [
        for (final s in block.spans)
          if (s.href != null)
            TextSpan(
              text: s.text,
              style: style.copyWith(
                color: AppColors.textPrimary,
                decoration: TextDecoration.underline,
                fontWeight: s.bold ? FontWeight.w600 : null,
              ),
              recognizer: (TapGestureRecognizer()..onTap = () => _open(s.href!))
                ..also(_recognizers.add),
            )
          else
            TextSpan(
              text: s.text,
              style: s.bold ? style.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600) : null,
            ),
      ],
    ));
    final top = switch (block.type) {
      LegalBlockType.h1 => 0.0,
      LegalBlockType.h2 => AppSpace.xl,
      _ => AppSpace.sm,
    };
    if (block.type == LegalBlockType.li) {
      return Padding(
        padding: EdgeInsets.only(top: top, left: AppSpace.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('•  ', style: style),
            Expanded(child: text),
          ],
        ),
      );
    }
    return Padding(padding: EdgeInsets.only(top: top), child: text);
  }
}

extension<T> on T {
  T also(void Function(T) f) {
    f(this);
    return this;
  }
}
