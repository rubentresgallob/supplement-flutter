import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../presentation/legal/legal_document_page.dart';
import '../constants/api_constants.dart';
import '../widgets/ui/ui.dart';

/// Textos legales (en la app, desde `docs/legal/`) y página web de eliminación de cuenta.
/// Las mismas versiones se publican en la web: /privacidad y /terminos.
enum LegalPage {
  privacy('Política de privacidad', 'docs/legal/politica-privacidad.html', null),
  terms('Términos de uso', 'docs/legal/terminos.html', null),
  // Google Play exige una página web pública para borrar la cuenta
  deleteAccount('Eliminar cuenta', null, '/eliminar-cuenta.html');

  final String title;
  final String? asset;
  final String? webPath;
  const LegalPage(this.title, this.asset, this.webPath);

  Uri get uri => Uri.parse('${ApiConstants.baseUrl}$webPath');
}

/// Privacidad y términos: pantalla dentro de la app (también sin sesión).
/// Eliminar cuenta: la página web, en el navegador.
Future<void> openLegalPage(BuildContext context, LegalPage page) async {
  if (page.asset != null) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalDocumentPage(page: page)),
    );
    return;
  }
  final opened = await launchUrl(page.uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    AppToast.error(context, 'No se pudo abrir ${page.uri}');
  }
}
